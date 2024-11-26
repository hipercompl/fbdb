import "dart:ffi";
import "dart:isolate";
import "dart:math";
import "dart:async";
import "dart:typed_data";
import "dart:convert";
import "package:fbdb/fbdb.dart";
import "package:fbdb/fbclient.dart";

/// The native Firebird client loader and bindings.
late FbClient client;

/// The master (IMaster) interface.
///
/// Shared by all objects from the worker isolate.
/// It can be safely shared between different objects in the
/// worker isolate.
/// Interfaces specific to a particular type of object
/// (like attachments, transactions, queries, statements)
/// are encapsulated in those objects and not shared between them.
late IMaster master;

/// The util (IUtil) interface.
///
/// Shared by all objects from the worker isolate.
/// It can be safely shared between different objects in the
/// worker isolate.
/// Interfaces specific to a particular type of object
/// (like attachments, transactions, queries, statements)
/// are encapsulated in those objects and not shared between them.
late IUtil util;

/// The provider (IProvider) interface, which encapsulates an attachment.
///
/// Shared by all objects from the worker isolate.
/// It can be safely shared between different objects in the
/// worker isolate.
/// Interfaces specific to a particular type of object
/// (like attachments, transactions, queries, statements)
/// are encapsulated in those objects and not shared between them.
late IProvider provider;

/// The worker isolate runner.
/// The args list should contain:
/// index 0: the SendPort to the main isolate
/// index 1: the path to the Firebird client library
///          (optional, may be null or omitted)
/// index 2: use (true) or not (false) TracingAllocator
Future<void> workerRunner(List<dynamic> args) async {
  if (args.isEmpty) {
    throw FbClientException("Required worker parameters not provided");
  }

  if (args[2]) {
    // use tracing allocator
    mem = TracingAllocator();
  }

  SendPort toMain = args[0];
  final fromMain = ReceivePort();
  try {
    try {
      // args[1] is the path to libfbclient (null = use defaults)
      _createClient(args[1]);
    } catch (e) {
      toMain.send(FbDbResponse(FbDbResponseOp.error, [e]));
      return;
    }
    // send the control SendPort to the main isolate
    toMain.send(FbDbResponse(FbDbResponseOp.success, [fromMain.sendPort]));

    // create the worker object
    final worker = FbDbWorker._init(fromMain);

    // start the event loop of the worker
    await worker._run();

    // when the event loop finishes, the worker isolate should be shut down
    _disposeClient();
  } catch (e) {
    // ignoring all uncaught exceptions
    // can't do anything about them
  } finally {
    fromMain.close();
  }
}

// Create the global FbClient instance, optionally using the provided
// path to the libfbclient binary.
void _createClient(String? libPath) {
  client = FbClient(libPath);
  master = client.fbGetMasterInterface();
  util = master.getUtilInterface();
  provider = master.getDispatcher();
}

// Close / release the global FbClient instance and associated interfaces.
void _disposeClient() {
  provider.release();
  client.close();
}

/// The database connection worker class.
///
/// The worker can be created only by the main isolate function,
/// it is not intended to be instantiated by the client code.
class FbDbWorker {
  /// The receive port for commands from the main isolate.
  ReceivePort fromMain;

  /// The database attachment used by the worker.
  IAttachment? attachment;

  /// The status vector used internally by the worker methods.
  IStatus status;

  /// The connection options, as passed from the main isolate.
  FbOptions? options;

  /// The active explicit transaction (or null if there is none).
  ITransaction? transaction;

  /// All active (opened and not closed yet) queries.
  ///
  /// Those are only queries, which communicate with the Firebird
  /// database via this worker's attachment.
  Map<int, FbDbQueryWorker> activeQueries;

  /// All active (created or opened, but not closed yet) blobs.
  Map<int, FbBlobDef> activeBlobs;

  int _tpbLength = 0;
  Pointer<Uint8>? _tpb;

  /// Private constructor, so that no foreign code can instantiate
  /// the worker.
  FbDbWorker._init(this.fromMain)
      : status = master.getStatus(),
        activeQueries = {},
        activeBlobs = {};

  /// Release the memory resources used by this worker object.
  void _release() {
    if (_tpb != null) {
      mem.free(_tpb!);
      _tpb = null;
      _tpbLength = 0;
    }
  }

  /// The main message loop.
  ///
  /// Breaking out of the loop effectively ends the worker isolate.
  Future<void> _run() async {
    try {
      // Read data from the ReceivePort, on which the main isolate
      // sends the control messages.
      await for (final msg in fromMain) {
        // a new control message arrived
        try {
          if (!await _dispatchMessage(msg)) {
            // dispatcher decided to stop the message loop
            break;
          }
        } on FbStatusException catch (se) {
          // encapsulate the exception and send it to the main isolate
          _sendErrorResp((msg as FbDbControlMessage).resultPort,
              FbServerException.fromStatus(se.status, util: util));
        } catch (e) {
          // encapsulate the exception and send it to the main isolate
          _sendErrorResp((msg as FbDbControlMessage).resultPort, e);
        }
      }
    } finally {
      _release();
    }
  }

  /// The message dispatcher.
  ///
  /// The returned bool value indicates whether to continue listening
  /// for more messages (true) or end the message loop (false).
  /// The latter effectively ends the worker isolate.
  Future<bool> _dispatchMessage(FbDbControlMessage msg) async {
    switch (msg.op) {
      case FbDbControlOp.attach:
        await _attach(msg);
      case FbDbControlOp.createDatabase:
        await _createDatabase(msg);
      case FbDbControlOp.ping:
        await _ping(msg);
      case FbDbControlOp.detach:
        await _detach(msg);
        return false; // detaching closes the connection
      case FbDbControlOp.dropDatabase:
        await _dropDatabase(msg);
        return false; // dropping the database closes the connection
      case FbDbControlOp.startTransaction:
        await _startTransaction(msg);
      case FbDbControlOp.commit:
        await _commit(msg);
      case FbDbControlOp.rollback:
        await _rollback(msg);
      case FbDbControlOp.inTransaction:
        await _inTransaction(msg);
      case FbDbControlOp.queryExec:
        await _queryExec(msg);
      case FbDbControlOp.queryOpen:
        await _queryOpen(msg);
      case FbDbControlOp.createBlob:
        await _createBlob(msg);
      case FbDbControlOp.openBlob:
        await _openBlob(msg);
      case FbDbControlOp.putBlobSegment:
        await _putBlobSegment(msg);
      case FbDbControlOp.getBlobSegment:
        await _getBlobSegment(msg);
      case FbDbControlOp.closeBlob:
        await _closeBlob(msg);
      case FbDbControlOp.quit:
        await _quit(msg);
      default:
        throw FbClientException(
            "FbDbWorker operation not supported: ${msg.op.name}");
    }
    return true; // continue the message loop
  }

  /// Handles the ping operation.
  Future<void> _ping(FbDbControlMessage msg) async {
    if (attachment != null) {
      _sendSuccessResp(msg.resultPort, true);
    } else {
      _sendSuccessResp(msg.resultPort, false);
    }
  }

  /// Handles the attach operation.
  Future<void> _attach(FbDbControlMessage msg) async {
    final Map<String, dynamic> params = msg.data[0];
    options = params.containsKey("options") ? params["options"] : FbOptions();
    final dpb = _makeDPB(params);
    final db = _makeDBPath(params);
    try {
      status.init();
      attachment = provider.attachDatabase(
        status,
        db,
        dpb.getBufferLength(status),
        dpb.getBuffer(status),
      );
      _prepareTpbFromOptions(options);
      _sendSuccessResp(msg.resultPort);
    } finally {
      dpb.dispose();
    }
  }

  /// Handles the createDatabase operation.
  Future<void> _createDatabase(FbDbControlMessage msg) async {
    final Map<String, dynamic> params = msg.data[0];
    options = params.containsKey("options") ? params["options"] : FbOptions();
    final dpb = _makeDPB(params);
    final db = _makeDBPath(params);
    int? pageSize = options?.pageSize;
    if (pageSize != null && pageSize > 0) {
      dpb.insertInt(status, FbConsts.isc_dpb_page_size, pageSize);
    }
    final dbCharset = options?.dbCharset ?? "UTF8";
    dpb.insertString(status, FbConsts.isc_dpb_set_db_charset, dbCharset);
    try {
      status.init();
      attachment = provider.createDatabase(
        status,
        db,
        dpb.getBufferLength(status),
        dpb.getBuffer(status),
      );
      _prepareTpbFromOptions(options);
      _sendSuccessResp(msg.resultPort);
    } finally {
      dpb.dispose();
    }
  }

  /// Decodes transaction parameters and puts them into [_tpb].
  void _prepareTpbFromOptions(FbOptions? options) {
    if (_tpb != null) {
      mem.free(_tpb!);
      _tpb = null;
      _tpbLength = 0;
    }
    if (options != null && !options.transactionFlagsDefault()) {
      final (tpb, tpbLength) =
          _prepareTpb(options.transactionFlags, options.lockTimeout);
      _tpb = tpb;
      _tpbLength = tpbLength;
    }
  }

  /// Prepares a TPB, based on the provided transaction flags
  /// and (optionally) the lock timeout value.
  (Pointer<Uint8>?, int) _prepareTpb(Set<FbTrFlag>? flags, int? lockTimeout) {
    Pointer<Uint8>? tpb;
    int tpbLength = 0;
    if (flags != null || lockTimeout != null) {
      status.init();
      final builder = util.getXpbBuilder(status, IXpbBuilder.tpb);
      try {
        for (var flag in flags ?? {}) {
          builder.insertTag(status, fbTrParTags[flag] ?? 0);
        }
        if (lockTimeout != null) {
          builder.insertInt(status, FbConsts.isc_tpb_lock_timeout, lockTimeout);
        }
        tpbLength = builder.getBufferLength(status);
        tpb = mem.allocate(tpbLength);
        tpb.fromNativeMem(builder.getBuffer(status), tpbLength);
      } finally {
        builder.dispose();
      }
    }

    return (tpb, tpbLength);
  }

  /// Creates the PDB builder instance, based on the provided
  /// connection parameters (see [FbDb.attach]).
  IXpbBuilder _makeDPB(Map<String, dynamic> params) {
    final dpb = util.getXpbBuilder(status, IXpbBuilder.dpb);
    dpb.insertString(status, FbConsts.isc_dpb_lc_ctype, "UTF8");
    if (params.containsKey("user")) {
      dpb.insertString(status, FbConsts.isc_dpb_user_name, params["user"]);
    }
    if (params.containsKey("password")) {
      dpb.insertString(status, FbConsts.isc_dpb_password, params["password"]);
    }
    if (params.containsKey("role")) {
      dpb.insertString(status, FbConsts.isc_dpb_sql_role_name, params["role"]);
    }
    return dpb;
  }

  /// Prepares the database path string based on the provided
  /// connection parameters (see [FbDb.attach]).
  String _makeDBPath(Map<String, dynamic> params) {
    final buf = StringBuffer();
    if (params.containsKey("host")) {
      buf.write(params["host"]);
    }
    if (params.containsKey("port")) {
      if (!params.containsKey("host")) {
        buf.write("localhost");
      }
      buf.write("/${params['port']}");
    }
    if (params.containsKey("host") || params.containsKey("port")) {
      buf.write(":");
    }
    buf.write(params["database"]);
    return buf.toString();
  }

  /// Handles the detach operation.
  Future<void> _detach(FbDbControlMessage msg) async {
    _closeAllBlobs();
    transaction?.commit(status);
    transaction = null;
    _closeActiveQueries();
    status.init();
    attachment?.detach(status);
    attachment = null; // to prevent calling methods on destroyed FB interface
    List<dynamic> backInfo = [];
    if (mem is TracingAllocator) {
      // If we're using a tracing allocator,
      // send back the allocation data
      backInfo.add((mem as TracingAllocator).toMap());
    }
    _sendSuccessResp(msg.resultPort, backInfo);
  }

  /// Closes all active queries (also closes their receive ports).
  Future<void> _closeActiveQueries() async {
    final keys = List<int>.from(activeQueries.keys);
    for (final key in keys) {
      activeQueries[key]?._close();
    }
  }

  /// Handles the dropDatabase operation.
  Future<void> _dropDatabase(FbDbControlMessage msg) async {
    _closeAllBlobs();
    transaction?.commit(status);
    transaction = null;
    _closeActiveQueries();
    status.init();
    attachment?.dropDatabase(status);
    attachment = null;
    List<dynamic> backInfo = [];
    if (mem is TracingAllocator) {
      // If we're using a tracing allocator,
      // send back the allocation data
      backInfo.add((mem as TracingAllocator).toMap());
    }
    _sendSuccessResp(msg.resultPort, backInfo);
  }

  /// Handles the startTransaction operation.
  Future<void> _startTransaction(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("Drop database: no active attachment");
    }
    transaction?.release();
    status.init();
    Pointer<Uint8>? tpb = _tpb;
    int tpbLength = _tpbLength;

    if (msg.data.length >= 2 && (msg.data[0] != null || msg.data[1] != null)) {
      // specific transaction parameters are provided
      (tpb, tpbLength) = _prepareTpb(msg.data[0], msg.data[1]);
    }

    transaction = attachment?.startTransaction(status, tpbLength, tpb);
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the commit operation.
  Future<void> _commit(FbDbControlMessage msg) async {
    _closeAllBlobs();
    if (attachment == null) {
      throw FbClientException("Drop database: no active attachment");
    }
    if (transaction != null) {
      status.init();
      transaction?.commit(status);
      transaction = null;
    }
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the rollback operation.
  Future<void> _rollback(FbDbControlMessage msg) async {
    _closeAllBlobs();
    if (attachment == null) {
      throw FbClientException("Drop database: no active attachment");
    }
    if (transaction != null) {
      status.init();
      transaction?.rollback(status);
      transaction = null;
    }
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the inTransaction operation.
  Future<void> _inTransaction(FbDbControlMessage msg) async {
    _sendSuccessResp(msg.resultPort, (transaction != null));
  }

  /// Handles the queryExec operation.
  Future<void> _queryExec(FbDbControlMessage msg) async {
    final fromMain = ReceivePort();
    try {
      final q = FbDbQueryWorker(fromMain, this);
      activeQueries[q.hashCode] = q;
      final (sql, params, _) = _extractExecData(msg);
      await q._exec(sql, params, allocCursor: false);
      q._run(); // we don't await run() on purpose
      _sendSuccessResp(msg.resultPort, fromMain.sendPort);
    } catch (e) {
      fromMain.close();
      rethrow;
    }
  }

  /// Handles the queryOpen operation.
  Future<void> _queryOpen(FbDbControlMessage msg) async {
    final queryFromMain = ReceivePort();
    try {
      final q = FbDbQueryWorker(queryFromMain, this);
      activeQueries[q.hashCode] = q;
      final (sql, params, inlineBlobs) = _extractExecData(msg);
      await q._exec(sql, params, allocCursor: true, inlineBlobs: inlineBlobs);
      q._run(); // we don't await _run() on purpose
      _sendSuccessResp(msg.resultPort, queryFromMain.sendPort);
    } catch (e) {
      queryFromMain.close();
      rethrow;
    }
  }

  /// Handles the createBlob operation
  Future<void> _createBlob(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("No active attachment");
    }
    if (transaction == null) {
      throw FbClientException("No active transaction");
    }
    IBlob? iblob;
    var id = FbBlobId(0, 0);
    final fbId = IscQuad.allocate(0, 0);
    try {
      try {
        iblob = attachment!.createBlob(status, transaction!, fbId);
      } catch (_) {
        mem.free(fbId);
        rethrow;
      }
      id = FbBlobId.fromIscQuad(fbId);
    } finally {
      mem.free(fbId);
    }
    final def = FbBlobDef(iblob, id);
    _addBlobDef(def);
    _sendSuccessResp(msg.resultPort, id);
  }

  /// Handles the openBlob operation
  Future<void> _openBlob(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("No active attachment");
    }
    if (transaction == null) {
      throw FbClientException("No active transaction");
    }
    final FbBlobId inId = msg.data[0];
    final fbId = IscQuad.allocate(inId.quadHigh, inId.quadLow);
    try {
      IBlob? iblob;
      try {
        iblob = attachment!.openBlob(status, transaction!, fbId);
      } catch (_) {
        mem.free(fbId);
        rethrow;
      }
      final def = FbBlobDef(iblob, inId);
      _addBlobDef(def);
    } finally {
      mem.free(fbId);
    }
    _sendSuccessResp(msg.resultPort, []);
  }

  /// Handles the putBlobSegment operation
  Future<void> _putBlobSegment(FbDbControlMessage msg) async {
    final FbBlobId id = msg.data[0];
    ByteBuffer data = FbDbQueryWorker._asByteBuffer(msg.data[1]);
    final def = activeBlobs[id.idHash];
    if (def == null) {
      throw FbClientException("Blob ID does not point to an active blob");
    }
    if (def.iblob == null) {
      throw FbClientException("Blob ID does not match a valid blob interface");
    }
    if (data.lengthInBytes > 0) {
      Pointer<Uint8> buf = mem.allocate(data.lengthInBytes);
      try {
        buf.fromDartMem(data.asUint8List());
        def.iblob?.putSegment(status, data.lengthInBytes, buf);
      } finally {
        mem.free(buf);
      }
    }
    _sendSuccessResp(msg.resultPort, []);
  }

  /// Handles the getBlobSegment operation
  Future<void> _getBlobSegment(FbDbControlMessage msg) async {
    final FbBlobId id = msg.data[0];
    final int segmentSize = msg.data[1];
    final def = activeBlobs[id.idHash];
    Uint8List? blobData;
    if (def == null) {
      throw FbClientException("Blob ID does not point to an active blob");
    }
    if (def.iblob == null) {
      throw FbClientException("Blob ID does not match a valid blob interface");
    }
    if (segmentSize > 0) {
      Pointer<Uint8> buf = mem.allocate(segmentSize);
      Pointer<UnsignedInt> len = mem.allocate(sizeOf<UnsignedInt>());
      try {
        final r = def.iblob?.getSegment(status, segmentSize, buf, len);
        if ([IStatus.resultOK, IStatus.resultSegment].contains(r) &&
            len.value > 0) {
          blobData = buf.toDartMem(len.value);
        }
      } finally {
        mem.free(buf);
        mem.free(len);
      }
    }
    _sendSuccessResp(msg.resultPort, [blobData?.buffer]);
  }

  /// Handles the closeBlob operation
  Future<void> _closeBlob(FbDbControlMessage msg) async {
    final FbBlobId id = msg.data[0];
    final def = activeBlobs[id.idHash];
    if (def != null) {
      def.close(status);
      activeBlobs.remove(id.idHash);
    }
    _sendSuccessResp(msg.resultPort, []);
  }

  /// Handles the quit operaton.
  ///
  /// The quit command causes an immediate emergency exit
  /// from the worker isolate.
  Future<void> _quit(FbDbControlMessage _) {
    Isolate.exit();
  }

  /// Extracts the SQL statement and the parameters from the message data.
  (String, List<dynamic>, bool) _extractExecData(FbDbControlMessage msg) {
    if (msg.data.isEmpty) {
      throw FbClientException("No SQL statement provided");
    }
    String sql = msg.data[0];
    List<dynamic> params =
        (msg.data.length > 1 ? msg.data[1] : const []) ?? const [];
    bool inlineBlobs = (msg.data.length > 2 ? msg.data[2] : true) ?? true;
    return (sql, params, inlineBlobs);
  }

  /// Sends a success message with a payload to the main isolate.
  /// If obj is a list, it's being sent as the actual payload.
  /// Every other object is wrapped in a one-item list.
  void _sendSuccessResp(SendPort toMain, [dynamic obj]) {
    final payload = obj is List ? obj : [if (obj != null) obj];
    toMain.send(FbDbResponse(FbDbResponseOp.success, payload));
  }

  /// Sends an error message with a payload to the main isolate.
  /// If obj is a list, it's being sent as the actual payload.
  /// Every other object is wrapped in a one-item list.
  void _sendErrorResp(SendPort toMain, [dynamic obj]) {
    final payload = obj is List ? obj : [if (obj != null) obj];
    toMain.send(FbDbResponse(FbDbResponseOp.error, payload));
  }

  /// Closes all active blobs and clears the [activeBlobs] map.
  void _closeAllBlobs() {
    for (var b in activeBlobs.values) {
      try {
        b.close(status);
      } catch (_) {}
    }
    activeBlobs.clear();
  }

  /// Adds a blob definition to active blobs.
  void _addBlobDef(FbBlobDef d) {
    if (d.id != null) {
      activeBlobs[d.id!.idHash] = d;
    }
  }
}

/// The query worker class.
///
/// Each query created in the main isolate via a call to [FbDb.query]
/// causes creation of its peer [FbDbQueryWorker] object
/// in the worker isolate.
class FbDbQueryWorker {
  /// The port, through which commands from the main isolate are received.
  ReceivePort fromMain;

  /// The connection this query will use to talk to the database.
  FbDbWorker db;

  /// An internal transaction, started and ended if no explicit one is present.
  ITransaction? _transaction;

  /// Indicates whether a statement was executed in its own, internal transaction.
  bool _ownTransaction = false;

  /// A prepared statement, ready to be executed.
  IStatement? _statement;

  /// The database cursor to fetch rows from.
  IResultSet? _resultSet;

  /// The input metadata of the current statement.
  IMessageMetadata? _inputMetadata;

  /// The output metadata of the current statement.
  IMessageMetadata? _outputMetadata;

  /// The input message buffer (native memory).
  Pointer<Uint8> _inMsg = nullptr;

  /// The length of the input message.
  int _inMsgLen = 0;

  /// The output message buffer (native memory).
  Pointer<Uint8> _outMsg = nullptr;

  /// The length of the output message.
  int _outMsgLen = 0;

  /// The size of the internal query buffer (in native memory).
  static const _internalBufferSize = 1024;

  /// Internal buffer for values and blob chunks (native memory).
  ///
  /// The internal buffer is used in marshalling small data pieces
  /// (like ints, dates, blob IDs, etc.), to avoid continuous
  /// allocation and deallocation of small chunks of native memory,
  /// which is costly.
  Pointer<Uint8> _internalBuffer = nullptr;

  /// Metadata of the fields (columns) of the current result set.
  List<FbFieldDef>? _fieldDefs;

  /// The names of the fields (columns) in the current result set.
  List<String>? _fieldNames;

  /// The kind of query most recently executed.
  ///
  /// It indicates whether it's a query with a cursor
  /// (executed via [FbQuery.openCursor]), or a query without one
  /// (executed via [FbQuery.execute]).
  FbDbQueryType _type = FbDbQueryType.none;

  /// A flag indicating whether blobs should be passed inline or as IDs.
  bool _inlineBlobs = true;

  /// The default constructor.
  ///
  /// To construct a query worker one needs to pass a receive port
  /// for commands from the main isolate, as well as an active
  /// database connection.
  FbDbQueryWorker(this.fromMain, this.db);

  /// The main message loop.
  ///
  /// Breaking out of the loop causes the query worker to finish
  /// and stop responding to any commands from the main isolate.
  Future<void> _run() async {
    try {
      // Read data from the ReceivePort, on which the main isolate
      // sends the control messages.
      await for (final msg in fromMain) {
        // a new control message arrived
        try {
          if (!await _dispatchMessage(msg)) {
            // dispatcher decided to stop the message loop
            break;
          }
        } on FbStatusException catch (se) {
          // encapsulate the exception and send it to the main isolate
          db._sendErrorResp((msg as FbDbControlMessage).resultPort,
              FbServerException.fromStatus(se.status, util: util));
        } catch (e) {
          // encapsulate the exception and send it to the main isolate
          db._sendErrorResp((msg as FbDbControlMessage).resultPort, e);
        }
      }
    } finally {
      _close();
    }
  }

  /// Message dispatcher.
  Future<bool> _dispatchMessage(FbDbControlMessage msg) async {
    try {
      switch (msg.op) {
        case FbDbControlOp.closeQuery:
          try {
            await _closeQuery(msg);
          } catch (_) {
            // we don't want exceptions when closing a query
          }
          return false; // end the message loop

        case FbDbControlOp.getFieldDefs:
          await _getFieldDefs(msg);

        case FbDbControlOp.fetchNext:
          await _fetchNext(msg);

        case FbDbControlOp.affectedRows:
          await _affectedRows(msg);

        case FbDbControlOp.getOutput:
          await _getOutput(msg);

        default:
          throw FbClientException(
              "FbDbQueryWorker operation not supported: ${msg.op.name}");
      }
    } on FbStatusException catch (se) {
      db._sendErrorResp(
        msg.resultPort,
        FbServerException.fromStatus(se.status, util: util),
      );
    } catch (e) {
      db._sendErrorResp(msg.resultPort, e);
    }
    return true;
  }

  /// Closes the previously prepared statement's interfaces.
  ///
  /// Before executing another statement, it's necessary to clean up
  /// allocated interfaces from the previous statement (if there was one).
  void _closeStatement() {
    if (_ownTransaction) {
      _ownTransaction = false;
      _transaction?.commit(db.status);
    }
    if (_inMsg != nullptr) {
      mem.free(_inMsg);
      _inMsg = nullptr;
    }
    _inMsgLen = 0;
    if (_outMsg != nullptr) {
      mem.free(_outMsg);
      _outMsg = nullptr;
    }
    _outMsgLen = 0;
    if (_resultSet != null) {
      _resultSet?.release();
      _resultSet = null;
    }
    if (_inputMetadata != null) {
      _inputMetadata?.release();
      _inputMetadata = null;
    }
    if (_outputMetadata != null) {
      _outputMetadata?.release();
      _outputMetadata = null;
    }
    if (_internalBuffer != nullptr) {
      mem.free(_internalBuffer);
      _internalBuffer = nullptr;
    }
    if (_statement != null) {
      final ref = _statement;
      _statement = null;
      try {
        ref?.free(db.status);
      } catch (_) {}
    }
    _fieldDefs = null;
    _type = FbDbQueryType.none;
  }

  /// Closes the query.
  ///
  /// Closes the receive port from the main isolate.
  /// By default, removes the query from the active queries
  /// of the connection (but it depends on the provided flag).
  void _close({bool updateActiveQueries = true}) {
    if (updateActiveQueries) {
      db.activeQueries.remove(hashCode);
    }
    db.status.init();
    if (_ownTransaction) {
      _ownTransaction = false;
      try {
        _transaction?.commit(db.status);
      } catch (_) {}
    }
    _transaction = null;
    fromMain.close();
    _closeStatement();
  }

  /// Handles the getFieldDefs operation.
  Future<void> _getFieldDefs(FbDbControlMessage msg) async {
    if (_type != FbDbQueryType.withCursor || _fieldDefs == null) {
      throw FbClientException("No data set available for the query");
    }
    db._sendSuccessResp(msg.resultPort, [_fieldDefs]);
  }

  /// Handles the fetchNext operation.
  ///
  /// The response sent back to the main isolate either contains
  /// the row data (in form of a map field name : value or a list of values,
  /// depending on the format requirement sent from the main isolate),
  /// or null if no data is available (i.e. the end of the data set
  /// has been reached).
  /// On errors an exception gets thrown.
  Future<void> _fetchNext(FbDbControlMessage msg) async {
    if (_type != FbDbQueryType.withCursor || _resultSet == null) {
      throw FbClientException("No data set available for the query");
    }
    int? r;
    db.status.init();
    try {
      r = _resultSet?.fetchNext(db.status, _outMsg);
    } on FbStatusException catch (e) {
      if (e.status.errors[1] == FbErrorCodes.isc_bad_result_set) {
        // special case - trying to fetch from a result set
        // that has been already depleted
        // we don't want an exception in this case - just a null
        // return, indicating there are no more rows
        db._sendSuccessResp(msg.resultPort, null);
        return;
      } else {
        // in all other cases, the exception is to be passed on
        rethrow;
      }
    }
    if (r == IStatus.resultOK) {
      final FbRowFormat format =
          msg.data.isNotEmpty ? msg.data[0] : FbRowFormat.asMap;
      final values = _getRowValues(_outMsg);
      if (format == FbRowFormat.asList) {
        db._sendSuccessResp(msg.resultPort, [values]);
      } else {
        final rec =
            Map<String, dynamic>.fromIterables(_fieldNames ?? [], values);
        db._sendSuccessResp(msg.resultPort, rec);
      }
    } else {
      if (_ownTransaction) {
        _transaction?.commit(db.status);
        _ownTransaction = false;
        _transaction = null;
      }
      db._sendSuccessResp(msg.resultPort, null);
    }
  }

  /// Handles the affectedRows operation.
  Future<void> _affectedRows(FbDbControlMessage msg) async {
    if (_type == FbDbQueryType.withoutCursor) {
      db.status.init();
      db._sendSuccessResp(
          msg.resultPort, _statement?.getAffectedRecords(db.status) ?? 0);
    } else {
      throw FbClientException(
          "affectedRows not available: no active DML query");
    }
  }

  /// Handles the getOutput operation.
  ///
  /// The response sent back to the main isolate consists
  /// of two values:
  /// - data presence indicator (true / false),
  /// - output data as a map or list (if [FbRowFormat.asList] was passed
  ///   from the main isolate).
  Future<void> _getOutput(FbDbControlMessage msg) async {
    if (_type != FbDbQueryType.withoutCursor) {
      throw FbClientException("No output data available for the query");
    }
    final FbRowFormat format =
        msg.data.isNotEmpty ? msg.data[0] : FbRowFormat.asMap;
    final values = _getRowValues(_outMsg);
    if (format == FbRowFormat.asList) {
      db._sendSuccessResp(msg.resultPort, values);
    } else {
      final rec = Map<String, dynamic>.fromIterables(_fieldNames ?? [], values);
      db._sendSuccessResp(msg.resultPort, rec);
    }
  }

  /// Returns the internal native memory buffer.
  ///
  /// Casts the buffer to the native type [T].
  /// Allocates the buffer (of size [_internalBufferSize]) if it's
  /// not currently allocated.
  Pointer<T> _getInternalBuffer<T extends NativeType>() {
    if (_internalBuffer == nullptr) {
      _internalBuffer = mem.allocate(_internalBufferSize);
    }
    return _internalBuffer.cast<T>();
  }

  /// Prepares the query.
  ///
  /// It asks the Firebird server to prepare the statement,
  /// and then fetches and decodes input and output metadata.
  Future<void> _prepare(String sql) async {
    _closeStatement();
    if (db.attachment == null) {
      throw FbClientException(
          "No active database connection associated with the query object");
    }
    ITransaction? tra = db.transaction;
    bool ownTransaction = false;
    if (db.transaction == null) {
      // we'll use our own transaction
      db.status.init();
      tra = db.attachment?.startTransaction(db.status);
      ownTransaction = true;
    }
    try {
      if (tra == null) {
        throw FbClientException("No active transaction and couldn't start one");
      }
      db.status.init();
      _statement = db.attachment?.prepare(
          db.status,
          tra,
          sql,
          FbConsts.sqlDialectCurrent,
          IStatement.preparePrefetchMetadata |
              IStatement.preparePrefetchAffectedRecords);
    } finally {
      if (ownTransaction) {
        db.status.init();
        tra?.commit(db.status);
      }
    }
    _inputMetadata = _statement?.getInputMetadata(db.status);
    _outputMetadata = _statement?.getOutputMetadata(db.status);
    _inMsgLen = _inputMetadata?.getMessageLength(db.status) ?? 0;
    _outMsgLen = _outputMetadata?.getMessageLength(db.status) ?? 0;
    if (_inMsgLen > 0) {
      _inMsg = mem.allocate(_inMsgLen);
    }
    if (_outMsgLen > 0) {
      _outMsg = mem.allocate(_outMsgLen);
    }
    if (_internalBuffer == nullptr) {
      _internalBuffer = mem.allocate(_internalBufferSize);
    }
  }

  /// Decodes the output fields.
  List<FbFieldDef> _decodeFields() {
    final List<FbFieldDef> res = [];
    final fieldCount = _outputMetadata?.getCount(db.status);
    if (fieldCount == null) {
      return res;
    }
    for (var i = 0; i < fieldCount; i++) {
      res.add(FbFieldDef.fromMetadata(_outputMetadata, i, db.status));
    }
    return res;
  }

  /// Retrieves just the field names from field definitions.
  List<String>? _namesFrom(List<FbFieldDef>? defs) {
    return defs?.map((e) => e.name).toList(growable: false);
  }

  /// Puts all params inside msg, according to the inputMetadata
  void _putQueryParams(Pointer<Uint8> msg, List<dynamic> params) {
    if (_inputMetadata == null) {
      throw FbClientException(
          "Cannot parametrize query - no input metadata available");
    }
    final totalLen = _inputMetadata!.getMessageLength(db.status);
    msg.setAllBytes(totalLen, 0);
    for (var i = 0; i < params.length; i++) {
      _putParam(db.status, msg, _inputMetadata!, i, params[i]);
    }
  }

  /// Gets all field values from the msg, according to the otputMetadata.
  List<dynamic> _getRowValues(Pointer<Uint8> msg) {
    if (_outputMetadata == null) {
      throw FbClientException(
          "Cannot access row data - no output metadata available");
    }
    final List<dynamic> res = [];
    int colCount = _outputMetadata?.getCount(db.status) ?? 0;
    for (var i = 0; i < colCount; i++) {
      final val = _getRowValue(db.status, msg, _outputMetadata!, i);
      res.add(val);
    }
    return res;
  }

  /// Executes a query either by calling execute or openCursor,
  /// depending on the allocCursor parameter.
  Future<void> _exec(String sql, List<dynamic> params,
      {required bool allocCursor, bool inlineBlobs = true}) async {
    _closeStatement();
    _inlineBlobs = inlineBlobs;
    await _prepare(sql);
    final paramCount = _inputMetadata?.getCount(db.status) ?? 0;
    if (paramCount != params.length) {
      throw FbClientException(
        "The number of provided values: ${params.length} "
        "doesn't match the required number of parameters: $paramCount",
      );
    }

    _transaction = db.transaction;
    if (_transaction == null) {
      _transaction = db.attachment?.startTransaction(db.status);
      _ownTransaction = true;
    } else {
      _ownTransaction = false;
    }
    if (_transaction == null) {
      throw FbClientException("Execute statement: no active transaction");
    }
    db.status.init();
    _putQueryParams(_inMsg, params);
    if (allocCursor) {
      _resultSet = _statement?.openCursor(
        db.status,
        _transaction!,
        (_inMsgLen > 0 ? _inputMetadata : null),
        (_inMsgLen > 0 ? _inMsg : null),
        (_outMsgLen > 0 ? _outputMetadata : null),
      );
      _type = FbDbQueryType.withCursor;
      _fieldDefs = _decodeFields();
    } else {
      _statement?.execute(
        db.status,
        _transaction!,
        (_inMsgLen > 0 ? _inputMetadata : null),
        (_inMsgLen > 0 ? _inMsg : null),
        (_outMsgLen > 0 ? _outputMetadata : null),
        (_outMsgLen > 0 ? _outMsg : null),
      );
      _type = FbDbQueryType.withoutCursor;
      _fieldDefs = _decodeFields();
      if (_ownTransaction) {
        _transaction?.commit(db.status);
        _transaction = null;
        _ownTransaction = false;
      }
    }
    _fieldNames = _namesFrom(_fieldDefs);
  }

  /// Handles the closeQuery operation.
  Future<void> _closeQuery(FbDbControlMessage msg) async {
    _close();
    db._sendSuccessResp(msg.resultPort);
  }

  /// Puts the value into the message buffer, respecting the message metadata.
  ///
  /// The [value] has to comply with the type of the parameter at index [index].
  /// It will be put into [msg] at the memory offset defined by [meta],
  /// unless the [value] is null, in which case the null flag will be set
  /// in the buffer.
  /// [status] is used for error checking (must be a valid IStatus
  /// interface instance).
  void _putParam(
    IStatus status,
    Pointer<Uint8> msg,
    IMessageMetadata meta,
    int index,
    dynamic value,
  ) {
    int nullOffset = meta.getNullOffset(status, index);
    if (value == null) {
      if (!meta.isNullable(status, index)) {
        throw FbClientException(
            "Parameter at index $index is not nullable (null requested)");
      }
      msg.writeUint16(nullOffset, 1); // null value
      return;
    }
    msg.writeUint16(nullOffset, 0); // non-null value
    int type = meta.getType(status, index);
    int offset = meta.getOffset(status, index);
    int scale = meta.getScale(status, index);
    int length = meta.getLength(status, index);

    switch (type) {
      case FbConsts.SQL_TEXT:
      case FbConsts.SQL_TEXT + 1:
        _putChar(msg, offset, value, length, meta, index);

      case FbConsts.SQL_VARYING:
      case FbConsts.SQL_VARYING + 1:
        // length + 2 because length reported by metadata
        // means the length of the field / parameter,
        // excluding the 2-byte unsigned short holding
        // the actual length of the text
        msg.writeVarchar(offset, value, length + 2);

      case FbConsts.SQL_SHORT:
      case FbConsts.SQL_SHORT + 1:
        msg.writeInt16(offset,
            scale != 0 ? _scaled(value, scale) : (value as num).toInt());

      case FbConsts.SQL_LONG:
      case FbConsts.SQL_LONG + 1:
        msg.writeInt32(offset,
            scale != 0 ? _scaled(value, scale) : (value as num).toInt());

      case FbConsts.SQL_FLOAT:
      case FbConsts.SQL_FLOAT + 1:
        msg.writeFloat(offset, (value as num).toDouble());

      case FbConsts.SQL_DOUBLE:
      case FbConsts.SQL_DOUBLE + 1:
        msg.writeDouble(offset, (value as num).toDouble());

      case FbConsts.SQL_TIMESTAMP:
      case FbConsts.SQL_TIMESTAMP + 1:
        _putTimestamp(msg, offset, value);

      case FbConsts.SQL_BLOB:
      case FbConsts.SQL_BLOB + 1:
        _putBlob(msg, offset, value);

      case FbConsts.SQL_QUAD:
      case FbConsts.SQL_QUAD + 1:
        _putQuad(msg, offset, value);

      case FbConsts.SQL_TYPE_TIME:
      case FbConsts.SQL_TYPE_TIME + 1:
        _putTime(msg, offset, value);

      case FbConsts.SQL_TYPE_DATE:
      case FbConsts.SQL_TYPE_DATE + 1:
        _putDate(msg, offset, value);

      case FbConsts.SQL_INT64:
      case FbConsts.SQL_INT64 + 1:
        msg.writeInt64(offset,
            scale != 0 ? _scaled(value, scale) : (value as num).toInt());

      case FbConsts.SQL_INT128:
      case FbConsts.SQL_INT128 + 1:
        _putInt128(status, msg, offset, value, scale);

      case FbConsts.SQL_TIMESTAMP_TZ:
      case FbConsts.SQL_TIMESTAMP_TZ + 1:
        _putTimestampTZ(status, msg, offset, value);

      case FbConsts.SQL_TIME_TZ:
      case FbConsts.SQL_TIME_TZ + 1:
        _putTimeTZ(status, msg, offset, value);

      // note: SQL_TIME_TZ_EX and SQL_TIMESTAMP_TZ_EX shouldn't appear
      // in input message, because IUtil doesn't provide encoding
      // methods for them, only decoding ones

      case FbConsts.SQL_DEC16:
      case FbConsts.SQL_DEC16 + 1:
        _putDec16(status, msg, offset, value);

      case FbConsts.SQL_DEC34:
      case FbConsts.SQL_DEC34 + 1:
        _putDec34(status, msg, offset, value);

      case FbConsts.SQL_BOOLEAN:
      case FbConsts.SQL_BOOLEAN + 1:
        msg.writeUint8(offset, value ? 1 : 0);

      case FbConsts.SQL_NULL:
        msg.writeInt16(nullOffset, value == null ? 1 : 0);

      default:
        throw FbClientException(
            "Firebird data type (code $type) not implemented");
    }
  }

  /// Puts a constant-length string into the message [msg] at offset [offset].
  ///
  /// Right-pads the string after converting it to UTF-8
  /// to fill the required length.
  /// For character set OCTETS the string is padded with 0x00, for all other
  /// character sets it's padded with 0x20 (spaces).
  /// See https://groups.google.com/g/firebird-support/c/06aNT1ZieOk
  void _putChar(Pointer<Uint8> msg, int offset, String value, int length,
      IMessageMetadata meta, int index) {
    var encoded = utf8.encode(value);
    Uint8List toWrite;
    if (encoded.length < length) {
      // right-pad the UTF-8 string to the required length
      // char set == 1 (OCTETS) => pad with 0, otherwise pad with space
      final padCode = meta.getCharSet(db.status, index) == 1 ? 0x00 : 0x20;
      List<int> pad = List<int>.filled(length - encoded.length, padCode);
      toWrite = Uint8List.fromList(encoded + pad);
    } else if (encoded.length > length) {
      toWrite = encoded.sublist(0, length);
    } else {
      toWrite = encoded;
    }
    msg.fromDartMem(toWrite, length, 0, offset);
  }

  /// Puts date part from [dt] into the message [msg] at offset [offset].
  void _putDate(
    Pointer<Uint8> msg,
    int offset,
    DateTime dt,
  ) {
    int encoded = util.encodeDate(dt.year, dt.month, dt.day);
    msg.writeInt32(offset, encoded);
  }

  /// Puts time part from [dt] into the message [msg] at offset [offset].
  void _putTime(
    Pointer<Uint8> msg,
    int offset,
    DateTime dt,
  ) {
    int encoded = util.encodeTime(dt.hour, dt.minute, dt.second,
        dt.millisecond * 10 + dt.microsecond ~/ 100);
    msg.writeUint32(offset, encoded);
  }

  /// Puts time part from [dt] into the message [msg] at offset [offset].
  ///
  /// Appends time zone info.
  void _putTimeTZ(
    IStatus status,
    Pointer<Uint8> msg,
    int offset,
    DateTime dt,
  ) {
    final Pointer<IscTimeTz> t = _getInternalBuffer();
    try {
      util.encodeTimeTz(
        status,
        t,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond + dt.microsecond ~/ 100,
        dt.timeZoneName,
      );
      msg.fromNativeMem(t, sizeOf<IscTimeTz>(), 0, offset);
    } finally {
      IscTimeTz.free(t);
    }
  }

  /// Puts date and time from [dt] into the message [msg] at offset [offset].
  void _putTimestamp(
    Pointer<Uint8> msg,
    int offset,
    DateTime dt,
  ) {
    final Pointer<IscTimestamp> ts = _getInternalBuffer();
    ts.ref.date = util.encodeDate(dt.year, dt.month, dt.day);
    ts.ref.time = util.encodeTime(
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
    );
    msg.fromNativeMem(ts, sizeOf<IscTimestamp>(), 0, offset);
  }

  /// Puts date and time from [dt] into the message [msg] at offset [offset].
  ///
  /// Appends time zone info.
  void _putTimestampTZ(
    IStatus status,
    Pointer<Uint8> msg,
    int offset,
    DateTime dt,
  ) {
    final Pointer<IscTimestampTz> ts = _getInternalBuffer();
    util.encodeTimeStampTz(
      status,
      ts,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond + dt.microsecond ~/ 100,
      dt.timeZoneName,
    );
    msg.fromNativeMem(ts, sizeOf<IscTimestampTz>(), 0, offset);
  }

  double _scaleMultiplier(int scaleDigits) {
    const scaleMultipliers = [
      1.0,
      10.0,
      100.0,
      1000.0,
      10000.0,
      100000.0,
      1000000.0,
      10000000.0,
      100000000.0,
    ];
    final scaleIndex = scaleDigits.abs();
    final scaleMul = scaleIndex < scaleMultipliers.length
        ? scaleMultipliers[scaleIndex]
        : pow(10.0, scaleIndex).toDouble();
    return scaleDigits >= 0 ? scaleMul : 1.0 / scaleMul;
  }

  /// Converts a floating point value to a scaled integer.
  ///
  /// Takes [value] and produces an integer by mutiplying [value]
  /// by 10 to the power of -[scaleDigits].
  /// Note, that negative [scaleDigits] scale up, positive scale down.
  ///
  /// Example:
  /// ```dart
  /// assert(_scaled(1.0, -3) == 1000.0);
  /// assert(_scaled(500.0, 2) == 5.0);
  /// ```
  int _scaled(double value, int scaleDigits) {
    if (scaleDigits == 0) {
      return value.toInt();
    }
    return (value * _scaleMultiplier(-scaleDigits)).round().toInt();
  }

  /// Converts a scaled integer to unscaled floating point.
  ///
  /// Takes [value] and produces a double by dividing [value]
  /// by 10^-[scaleDigits].
  ///
  /// Example:
  /// ```dart
  /// assert(_unscaled(1000, -3) == 1.0);
  /// assert(_unscaled(5.0, 2) == 500.0);
  /// ```
  double _unscaled(int value, int scaleDigits) {
    if (scaleDigits == 0) {
      return value.toDouble();
    }
    return (value / _scaleMultiplier(-scaleDigits));
  }

  /// Puts a floating point value into the message as a scaled integer.
  ///
  /// Scales [value] by 10^[scale] and stores it in [msg] as 128-bit integer
  /// at offset [offset].
  /// Note: currently uses intermediate string representation, which is far
  /// from optimal in terms of efficiency. Will be re-implemented in future
  /// versions.
  void _putInt128(
      IStatus status, Pointer<Uint8> msg, int offset, double value, int scale) {
    // Current implementation converts the double value to string
    // and then uses Int128 interface to convert the string to
    // the int128-backed scaled value.
    // This is probably inefficient and requires further optimization.
    final i128 = util.getInt128(status);
    final s = value.toString();
    Pointer<FbI128> ii = _getInternalBuffer();
    i128.fromStr(status, scale, s, ii);
    msg.fromNativeMem(ii, sizeOf<FbI128>(), 0, offset);
  }

  /// Stores a floating point value as dec16 decimal value.
  ///
  /// Note: currently uses intermediate string representation, which is far
  /// from optimal in terms of efficiency. Will be re-implemented in future
  /// versions.
  void _putDec16(IStatus status, Pointer<Uint8> msg, int offset, double value) {
    final iDec = util.getDecFloat16(status);
    final s = value.toString();
    Pointer<FbDec16> d = _getInternalBuffer();
    iDec.fromStr(status, s, d);
    msg.fromNativeMem(d, sizeOf<FbDec16>(), 0, offset);
  }

  /// Stores a floating point value as dec34 decimal value.
  ///
  /// Note: currently uses intermediate string representation, which is far
  /// from optimal in terms of efficiency. Will be re-implemented in future
  /// versions.
  void _putDec34(IStatus status, Pointer<Uint8> msg, int offset, double value) {
    final iDec = util.getDecFloat34(status);
    final s = value.toString();
    Pointer<FbDec34> d = _getInternalBuffer();
    iDec.fromStr(status, s, d);
    msg.fromNativeMem(d, sizeOf<FbDec34>(), 0, offset);
  }

  /// Stores an isc_quad value in the message buffer.
  void _putQuad(Pointer<Uint8> msg, int offset, FbQuad value) {
    Pointer<IscQuad> q = _getInternalBuffer();
    q.ref.iscQuadHigh = value.quadHigh;
    q.ref.iscQuadLow = value.quadLow;
    msg.fromNativeMem(q, sizeOf<IscQuad>(), 0, offset);
  }

  /// Creates a blob and stores its id in the message buffer.
  void _putBlob(Pointer<Uint8> msg, int offset, dynamic data) {
    if (_transaction == null) {
      throw FbClientException("Cannot store blobs outside transaction context");
    }

    if (data is FbBlobId) {
      // the blob has been already stored in the database
      // so we just store the provided ID in the message data
      data.storeInQuad((msg + offset).cast());
    } else {
      // we assume data is the actual blob buffer
      ByteBuffer binData = _asByteBuffer(data);

      // we need to store the blob in the database
      // before passing its ID to the query
      IBlob? blob = db.attachment?.createBlob(
        db.status,
        _transaction!,
        (msg + offset).cast(),
      );
      if (blob == null) {
        throw FbClientException("Blob creation failed");
      }
      try {
        Pointer<Uint8> blobBuf = _getInternalBuffer();
        int stored = 0;
        int toStore = binData.lengthInBytes;
        while (stored < toStore) {
          final chunkSize = min(toStore - stored, _internalBufferSize);
          blobBuf.fromDartMem(
              binData.asUint8List(stored, chunkSize), chunkSize);
          blob.putSegment(db.status, chunkSize, blobBuf);
          stored += chunkSize;
        }
        blob.close(db.status);
        blob = null;
      } finally {
        blob?.release();
      }
    }
  }

  /// Retrieves a single value from the message buffer.
  ///
  /// Retrieves the value at index [index] from [msg], calculating
  /// offsets using the message metadata in [meta].
  /// Returned data type varies, depending on the type of the value
  /// in [msg]. If the field at index [index] in [msg] contains the null flag,
  /// null is returned.
  /// [status] is used for error checking (must be a valid IStatus
  /// interface instance).
  dynamic _getRowValue(
    IStatus status,
    Pointer<Uint8> msg,
    IMessageMetadata meta,
    int index,
  ) {
    const maxBytesPerCodePoint = 4;
    int nullOffset = meta.getNullOffset(status, index);
    int isNull = msg.readUint16(nullOffset);
    if (isNull > 0) {
      return null;
    }
    int offset = meta.getOffset(status, index);
    int type = meta.getType(status, index);
    int scale = meta.getScale(status, index);
    int length = meta.getLength(status, index);

    switch (type) {
      case FbConsts.SQL_TEXT:
      case FbConsts.SQL_TEXT + 1:
        final s = msg.readString(offset, length);
        final sl = length ~/ maxBytesPerCodePoint;
        return s.length > sl ? s.substring(0, sl) : s;

      case FbConsts.SQL_VARYING:
      case FbConsts.SQL_VARYING + 1:
        return msg.readVarchar(offset);

      case FbConsts.SQL_SHORT:
      case FbConsts.SQL_SHORT + 1:
        final v = msg.readInt16(offset);
        return scale != 0 ? _unscaled(v, scale) : v;

      case FbConsts.SQL_LONG:
      case FbConsts.SQL_LONG + 1:
        final v = msg.readInt32(offset);
        return scale != 0 ? _unscaled(v, scale) : v;

      case FbConsts.SQL_FLOAT:
      case FbConsts.SQL_FLOAT + 1:
        return msg.readFloat(offset);

      case FbConsts.SQL_DOUBLE:
      case FbConsts.SQL_DOUBLE + 1:
        return msg.readDouble(offset);

      case FbConsts.SQL_TIMESTAMP:
      case FbConsts.SQL_TIMESTAMP + 1:
        return _getTimestamp(msg, offset);

      case FbConsts.SQL_BLOB:
      case FbConsts.SQL_BLOB + 1:
        return _inlineBlobs ? _getBlob(msg, offset) : _getBlobId(msg, offset);

      case FbConsts.SQL_QUAD:
      case FbConsts.SQL_QUAD + 1:
        return _getQuad(msg, offset);

      case FbConsts.SQL_TYPE_TIME:
      case FbConsts.SQL_TYPE_TIME + 1:
        return _decodeTime(msg.readUint32(offset));

      case FbConsts.SQL_TYPE_DATE:
      case FbConsts.SQL_TYPE_DATE + 1:
        return _decodeDate(msg.readInt32(offset));

      case FbConsts.SQL_INT64:
      case FbConsts.SQL_INT64 + 1:
        final v = msg.readInt64(offset);
        return scale != 0 ? _unscaled(v, scale) : v;

      case FbConsts.SQL_INT128:
      case FbConsts.SQL_INT128 + 1:
        return _getInt128(status, msg, offset, scale);

      case FbConsts.SQL_TIMESTAMP_TZ:
      case FbConsts.SQL_TIMESTAMP_TZ + 1:
        // for now timestamp with TZ ignores the time zone,
        // because Dart's DateTime class doesn't allow setting
        // arbitrary time zones
        return _getTimestampTZ(status, msg, offset);

      case FbConsts.SQL_TIME_TZ:
      case FbConsts.SQL_TIME_TZ + 1:
        return _getTimeTZ(status, msg, offset);

      case FbConsts.SQL_TIME_TZ_EX:
      case FbConsts.SQL_TIME_TZ_EX + 1:
        return _getTimeTZEx(status, msg, offset);

      case FbConsts.SQL_TIMESTAMP_TZ_EX:
      case FbConsts.SQL_TIMESTAMP_TZ_EX + 1:
        return _getTimestampTZEx(status, msg, offset);

      case FbConsts.SQL_DEC16:
      case FbConsts.SQL_DEC16 + 1:
        return _getDec16(status, msg, offset);

      case FbConsts.SQL_DEC34:
      case FbConsts.SQL_DEC34 + 1:
        return _getDec34(status, msg, offset);

      case FbConsts.SQL_BOOLEAN:
      case FbConsts.SQL_BOOLEAN + 1:
        return msg.readUint8(offset) != 0;

      case FbConsts.SQL_NULL:
        return msg.readInt16(nullOffset) == 1 ? null : false;

      default:
        throw FbClientException(
            "Firebird data type (code $type) not implemented");
    }
  }

  /// Decodes a date from the provided value.
  ///
  /// Uses IUtil to do the actual decoding.
  DateTime _decodeDate(int date) {
    Pointer<UnsignedInt> parts = _getInternalBuffer();
    final s = sizeOf<UnsignedInt>();
    util.decodeDate(
      date,
      parts,
      Pointer<UnsignedInt>.fromAddress(parts.address + s),
      Pointer<UnsignedInt>.fromAddress(parts.address + 2 * s),
    );
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Decodes time from the provided value.
  ///
  /// Uses IUtil to do the actual decoding.
  DateTime _decodeTime(int time) {
    Pointer<UnsignedInt> parts = _getInternalBuffer();
    final s = sizeOf<UnsignedInt>();
    util.decodeTime(
      time,
      parts,
      Pointer<UnsignedInt>.fromAddress(parts.address + s),
      Pointer<UnsignedInt>.fromAddress(parts.address + 2 * s),
      Pointer<UnsignedInt>.fromAddress(parts.address + 3 * s),
    );
    return DateTime(
      1,
      1,
      1,
      parts[0],
      parts[1],
      parts[2],
      parts[3] ~/ 10,
      (parts[3] % 10) * 100,
    );
  }

  /// Decodes date and time, based on the provided native structure.
  DateTime _decodeTimestamp(Pointer<IscTimestamp> ts) {
    final d = _decodeDate(ts.ref.date);
    final t = _decodeTime(ts.ref.time);
    return DateTime(
      d.year,
      d.month,
      d.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }

  /// Retrieves a timestamp value from the message.
  DateTime _getTimestamp(Pointer<Uint8> msg, int offset) {
    return _decodeTimestamp((msg + offset).cast());
  }

  /// Retrieves a quad (IscQuad / FbQuad) value from the message.
  FbQuad _getQuad(Pointer<Uint8> msg, int offset) {
    Pointer<IscQuad> q = _getInternalBuffer();
    msg.toNativeMem(q, sizeOf<IscQuad>(), offset);
    return FbQuad(q.ref.iscQuadHigh, q.ref.iscQuadLow);
  }

  /// Retrieves blob data for the blob ID read from the message.
  ByteBuffer _getBlob(Pointer<Uint8> msg, int offset) {
    if (_transaction == null) {
      throw FbClientException(
          "Cannot retrieve blobs outside transaction context");
    }
    Pointer<IscQuad> blobId = (msg + offset).cast();
    IBlob? blob = db.attachment?.openBlob(db.status, _transaction!, blobId);
    if (blob == null) {
      throw FbClientException("Cannot open blob data for reading");
    }
    final List<Uint8List> segments = [];
    var totalLength = 0;
    try {
      // The internal buffer will be used both for read bytes count
      // and the actual data
      // The first sizeOf<UnsignedInt> bytes are used by segmentLength,
      // the rest of the internal buffer constitute blobBuf.
      Pointer<UnsignedInt> segmentLength = _getInternalBuffer().cast();
      Pointer<Uint8> blobBuf =
          (_getInternalBuffer() + sizeOf<UnsignedInt>()).cast();
      int maxCnt = _internalBufferSize - sizeOf<UnsignedInt>();
      for (;;) {
        final rc = blob.getSegment(db.status, maxCnt, blobBuf, segmentLength);
        if ([IStatus.resultOK, IStatus.resultSegment].contains(rc) &&
            segmentLength.value > 0) {
          totalLength += segmentLength.value;
          segments.add(blobBuf.toDartMem(segmentLength.value));
        } else {
          break;
        }
      }
      blob.close(db.status);
      blob = null;
      final result = Uint8List(totalLength);
      var offset = 0;
      for (var segment in segments) {
        result.setAll(offset, segment);
        offset += segment.length;
      }
      return result.buffer;
    } finally {
      blob?.release();
    }
  }

  /// Retrieves just a blob ID from the message (not the blob data).
  FbBlobId _getBlobId(Pointer<Uint8> msg, int offset) {
    return FbBlobId.fromIscQuad((msg + offset).cast());
  }

  /// Retrieves an INT128 value from the message.
  ///
  /// The implementation is currently inefficient, as it uses
  /// intermediate string representation to tranlate an INT128
  /// into a double.
  double _getInt128(IStatus status, Pointer<Uint8> msg, int offset, int scale) {
    final i128 = util.getInt128(status);
    Pointer<FbI128> ii = _getInternalBuffer();
    msg.toNativeMem(ii, sizeOf<FbI128>(), offset);
    return double.parse(i128.toStr(status, ii));
  }

  /// Gets the timestamp from the message.
  ///
  /// Since Dart currently doesn't support arbitrary time zones,
  /// for now it silently ignores the time zone, returning just
  /// the timestamp.
  DateTime _getTimestampTZ(IStatus status, Pointer<Uint8> msg, int offset) {
    Pointer<UnsignedInt> ts = _getInternalBuffer();
    util.decodeTimeStampTz(
        status,
        (msg + offset).cast(),
        ts, // year
        (ts + sizeOf<UnsignedInt>()).cast(), // month
        (ts + 2 * sizeOf<UnsignedInt>()).cast(), // day
        (ts + 3 * sizeOf<UnsignedInt>()).cast(), // hours
        (ts + 4 * sizeOf<UnsignedInt>()).cast(), // minutes
        (ts + 5 * sizeOf<UnsignedInt>()).cast(), // seconds
        (ts + 6 * sizeOf<UnsignedInt>()).cast(), // fractions
        0, // timeZoneBufferLength
        nullptr // timeZoneBuffer
        );

    return DateTime(
      ts[0], // year
      ts[1], // month
      ts[2], // day
      ts[3], // hour
      ts[4], // minute
      ts[5], // second
      ts[6] ~/ 10, // millisecond
      (ts[6] % 10) * 100, // microsecond
    );
  }

  /// Gets the timestamp from the message.
  ///
  /// Since Dart currently doesn't support arbitrary time zones,
  /// for now it silently ignores the time zone, returning just
  /// the timestamp.
  DateTime _getTimestampTZEx(IStatus status, Pointer<Uint8> msg, int offset) {
    Pointer<UnsignedInt> ts = _getInternalBuffer();
    util.decodeTimeStampTzEx(
        status,
        (msg + offset).cast(),
        ts, // year
        (ts + sizeOf<UnsignedInt>()).cast(), // month
        (ts + 2 * sizeOf<UnsignedInt>()).cast(), // day
        (ts + 3 * sizeOf<UnsignedInt>()).cast(), // hours
        (ts + 4 * sizeOf<UnsignedInt>()).cast(), // minutes
        (ts + 5 * sizeOf<UnsignedInt>()).cast(), // seconds
        (ts + 6 * sizeOf<UnsignedInt>()).cast(), // fractions
        0, // timeZoneBufferLength
        nullptr // timeZoneBuffer
        );

    return DateTime(
      ts[0], // year
      ts[1], // month
      ts[2], // day
      ts[3], // hour
      ts[4], // minute
      ts[5], // second
      ts[6] ~/ 10, // millisecond
      (ts[6] % 10) * 100, // microsecond
    );
  }

  /// Gets time with time zone from the message.
  ///
  /// Currently, the actual time zone is ignored, as Dart's DateTime
  /// doesn't support arbitrary time zones.
  DateTime _getTimeTZ(IStatus status, Pointer<Uint8> msg, int offset) {
    Pointer<UnsignedInt> ts = _getInternalBuffer();
    util.decodeTimeTz(
      status,
      (msg + offset).cast(),
      ts, // hours
      (ts + sizeOf<UnsignedInt>()).cast(), // minutes
      (ts + sizeOf<UnsignedInt>()).cast(), // seconds
      (ts + sizeOf<UnsignedInt>()).cast(), // fractions
      0,
      nullptr,
    );
    return DateTime(
      1, // year
      1, // month
      1, // day
      ts[0], // hour
      ts[1], // minute
      ts[2], // second
      ts[3] ~/ 10, // millisecond
      (ts[3] % 10) * 100, // microsecond
    );
  }

  /// Gets time with time zone from the message.
  ///
  /// Currently, the actual time zone is ignored, as Dart's DateTime
  /// doesn't support arbitrary time zones.
  DateTime _getTimeTZEx(IStatus status, Pointer<Uint8> msg, int offset) {
    Pointer<UnsignedInt> ts = _getInternalBuffer();
    util.decodeTimeTzEx(
      status,
      (msg + offset).cast(),
      ts, // hours
      (ts + sizeOf<UnsignedInt>()).cast(), // minutes
      (ts + sizeOf<UnsignedInt>()).cast(), // seconds
      (ts + sizeOf<UnsignedInt>()).cast(), // fractions
      0,
      nullptr,
    );
    return DateTime(
      1, // year
      1, // month
      1, // day
      ts[0], // hour
      ts[1], // minute
      ts[2], // second
      ts[3] ~/ 10, // millisecond
      (ts[3] % 10) * 100, // microsecond
    );
  }

  /// Retrieves a value of type DECIMAL (DEC16) from the message.
  ///
  /// The implementation is currently inefficient, as it uses
  /// intermediate string representation to tranlate a DEC16
  /// into a double.
  double _getDec16(IStatus status, Pointer<Uint8> msg, int offset) {
    final iDec = util.getDecFloat16(status);
    final s = iDec.toStr(status, (msg + offset).cast());
    return double.parse(s);
  }

  /// Retrieves a value of type DECIMAL (DEC34) from the message.
  ///
  /// The implementation is currently inefficient, as it uses
  /// intermediate string representation to tranlate an DEC34
  /// into a double.
  double _getDec34(IStatus status, Pointer<Uint8> msg, int offset) {
    final iDec = util.getDecFloat34(status);
    final s = iDec.toStr(status, (msg + offset).cast());
    return double.parse(s);
  }

  /// Converts a dynamic object into a byte buffer.
  ///
  /// Handles the following data classes:
  /// - String: returns bytes of the UTF-8 encoded text
  /// - TypedData: returns the underlying buffer
  /// - ByteBuffer: returns the buffer as is
  /// For all other types a conversion error will be thrown.
  static ByteBuffer _asByteBuffer(dynamic data) {
    if (data is String) {
      return utf8.encode(data).buffer;
    } else if (data is TypedData) {
      return data.buffer;
    } else {
      return data as ByteBuffer;
    }
  }
}

/// Possible worker starting modes.
enum FbDbWorkerCreationMode {
  /// Attaches the worker object to an existing database.
  attach,

  /// Creates a new database.
  createDatabase,
}

/// Possible query types.
///
/// The query type is needed to differentiate between queries
/// with and without a database cursor.
enum FbDbQueryType {
  /// No query has been executed.
  none,

  /// The query was created with openQuery.
  withCursor,

  /// The query was created with execute.
  withoutCursor
}

/// Possible operations for control messages.
///
/// Some operations are handled by FbDbWorker, and some other
/// by FbDbQueryWorker objects.
enum FbDbControlOp {
  // commands for FbDbWorker

  /// Check the connection.
  ping,

  /// Attach to an existing database.
  attach,

  /// Create a new database.
  createDatabase,

  /// Detach from the database.
  detach,

  /// Drop (remove) the database.
  dropDatabase,

  /// Execute a query without opening a database cursor.
  queryExec,

  /// Execute a query, opening a database cursor for it.
  queryOpen,

  /// Start an explicit transaction.
  startTransaction,

  /// Commit an explicit transaction (if there's one pending).
  commit,

  /// Roll an explicit transaction back (if there's one pending).
  rollback,

  /// Check if there is a pending explicit transaction.
  inTransaction,

  /// Create a blob in the database.
  createBlob,

  /// Open an existing blob in the database.
  openBlob,

  /// Retrieve a single segment of data from a blob.
  getBlobSegment,

  /// Put a single segment of data into a blob.
  putBlobSegment,

  /// Close a blob.
  closeBlob,

  /// Immediately quit the worker
  quit,

  // commands for FbDbQueryWorker

  /// Execute a statement without a cursor.
  execQuery,

  /// Execute a statement with allocating a cursor.
  openQuery,

  /// Send back field (column) definitions.
  getFieldDefs,

  /// Send back the next (single) row of data.
  fetchNext,

  /// Send back the output parameters (for queries without a cursor).
  getOutput,

  /// Send back the number of rows that have been affected by the last DML query.
  affectedRows,

  /// Close the query and release all resources.
  closeQuery,
}

/// Possible types of responses to control messages.
enum FbDbResponseOp {
  /// Succesful execution of a command.
  success,

  /// Errors occured during command execution.
  error,
}

/// Represents a control message being sent from FbDb instance
/// to its associated worker instance.
///
/// Objects of this class are used both by FbDb and FbQuery.
class FbDbControlMessage {
  /// The operation to be executed.
  FbDbControlOp op;

  /// The port used to send back the result of the operation.
  SendPort resultPort;

  /// Parameters (if needed) of the operation.
  List<dynamic> data;

  /// The default constructor.
  ///
  /// Attribute initialization only, no extra activities.
  FbDbControlMessage(this.op, this.resultPort, this.data);
}

/// Represents a response message being sent from FbDb worker
/// instance to its associated main isolate object.
///
/// Objects of this class are used both by FbDb and FbQuery.
class FbDbResponse {
  /// The reponse kind (success / error).
  FbDbResponseOp op;

  /// The response data (varies, depending on the command).
  List<dynamic> data;

  /// The default constructor.
  ///
  /// Attribute initialization only, no extra activities.
  FbDbResponse(this.op, this.data);
}

/// Encapsulates information about an open (active) BLOB.
class FbBlobDef {
  /// The native IBlob interface.
  IBlob? iblob;

  /// The ID of this blob.
  FbBlobId? id;

  /// The default constructor.
  ///
  /// Attribute initialization only, no extra activities.
  FbBlobDef(this.iblob, this.id);

  /// Invalidates the blob info.
  ///
  /// Also closes the corresponding BLOB in the database.
  void close(IStatus status) {
    if (iblob != null) {
      try {
        iblob?.close(status);
      } catch (_) {}
      iblob = null;
    }
    id = null;
  }
}
