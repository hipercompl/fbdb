import "dart:ffi";
import "dart:isolate";
import "dart:async";
import "dart:typed_data";
import "package:fbdb/fbdb.dart";
import "package:fbdb/fbclient.dart";
import "fbhelper.dart";

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
  final ReceivePort _fromMain;

  /// The database attachment used by the worker.
  IAttachment? attachment;

  /// The status vector used internally by the worker methods.
  IStatus status;

  /// The connection options, as passed from the main isolate.
  FbOptions? _options;

  /// The active explicit transaction (or null if there is none).
  ITransaction? _transaction;

  /// All active (opened and not closed yet) queries.
  ///
  /// Those are only queries, which communicate with the Firebird
  /// database via this worker's attachment.
  final Map<int, FbDbQueryWorker> _activeQueries;

  /// All active (created or opened, but not closed yet) blobs.
  final Map<int, FbBlobDef> _activeBlobs;

  /// All active (created and not closed) batches.
  final Map<int, FbDbBatchWorker> _activeBatches;

  /// The length of the pre-allocated TPB.
  int _tpbLength = 0;

  /// A pre-allocated TPB, to avoid allocating it anew for each transaction.
  Pointer<Uint8>? _tpb;

  /// A set of all explicit concurrent transactions.
  /// The keys in the map are hashCode values of the transaction objects.
  /// The values in the map are actual transaction interfaces.
  final Map<int, ITransaction> _activeTransactions;

  /// Private constructor, so that no foreign code can instantiate
  /// the worker.
  FbDbWorker._init(this._fromMain)
    : status = master.getStatus(),
      _activeQueries = {},
      _activeBlobs = {},
      _activeBatches = {},
      _activeTransactions = {};

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
      await for (final msg in _fromMain) {
        // a new control message arrived
        try {
          if (!await _dispatchMessage(msg)) {
            // dispatcher decided to stop the message loop
            break;
          }
        } on FbStatusException catch (se) {
          // encapsulate the exception and send it to the main isolate
          _sendErrorResp(
            (msg as FbDbControlMessage).resultPort,
            FbServerException.fromStatus(se.status, util: util),
          );
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
      case FbDbControlOp.newTransaction:
        await _newTransaction(msg);
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
      case FbDbControlOp.prepareQuery:
        await _prepareQuery(msg);
      case FbDbControlOp.createBatch:
        await _createBatch(msg);
      default:
        throw FbClientException(
          "FbDbWorker operation not supported: ${msg.op.name}",
        );
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
    _options = params.containsKey("options") ? params["options"] : FbOptions();
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
      _prepareTpbFromOptions(_options);
      _sendSuccessResp(msg.resultPort);
    } finally {
      dpb.dispose();
    }
  }

  /// Handles the createDatabase operation.
  Future<void> _createDatabase(FbDbControlMessage msg) async {
    final Map<String, dynamic> params = msg.data[0];
    _options = params.containsKey("options") ? params["options"] : FbOptions();
    final dpb = _makeDPB(params);
    final db = _makeDBPath(params);
    int? pageSize = _options?.pageSize;
    if (pageSize != null && pageSize > 0) {
      dpb.insertInt(status, FbConsts.isc_dpb_page_size, pageSize);
    }
    final dbCharset = _options?.dbCharset ?? "UTF8";
    dpb.insertString(status, FbConsts.isc_dpb_set_db_charset, dbCharset);
    try {
      status.init();
      attachment = provider.createDatabase(
        status,
        db,
        dpb.getBufferLength(status),
        dpb.getBuffer(status),
      );
      _prepareTpbFromOptions(_options);
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
      final (tpb, tpbLength) = _prepareTpb(
        options.transactionFlags,
        options.lockTimeout,
      );
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
    // Bind time zone to extended representation (to receive
    // ISC_TIME_TZ_EX instead of ISC_TIME_TZ and ISC_TIMESTAMP_TZ_EX
    // instead of ISC_TIMESTAMP_TZ).
    // This feature is requires Firebird version >= 4.0.
    if (util.getClientVersion() >= 0x400) {
      dpb.insertString(
        status,
        FbConsts.isc_dpb_set_bind,
        "TIME ZONE TO EXTENDED",
      );
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
    _transaction?.commit(status);
    _transaction = null;
    _closeActiveQueries();
    _closeAllBatches();
    _closeActiveTransactions();
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
  void _closeActiveQueries() {
    final keys = List<int>.from(_activeQueries.keys);
    for (final key in keys) {
      _activeQueries[key]?._close();
    }
  }

  /// Closes all active transactions.
  void _closeActiveTransactions() {
    for (final k in _activeTransactions.keys) {
      _activeTransactions[k]?.release();
    }
    _activeTransactions.clear();
  }

  /// Handles the dropDatabase operation.
  Future<void> _dropDatabase(FbDbControlMessage msg) async {
    _closeAllBlobs();
    _transaction?.commit(status);
    _transaction = null;
    _closeActiveQueries();
    _closeActiveTransactions();
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

  /// Starts a new transaction with the given flags and lock timeout,
  /// which it extracts from the message data.
  /// Returns the transaction object.
  ITransaction? _makeTransaction(FbDbControlMessage msg) {
    status.init();
    Pointer<Uint8>? tpb = _tpb;
    int tpbLength = _tpbLength;

    if (msg.data.length >= 2 && (msg.data[0] != null || msg.data[1] != null)) {
      // specific transaction parameters are provided
      (tpb, tpbLength) = _prepareTpb(msg.data[0], msg.data[1]);
    }
    return attachment?.startTransaction(status, tpbLength, tpb);
  }

  /// Handles the startTransaction operation.
  Future<void> _startTransaction(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("Start transaction: no active attachment");
    }
    _transaction?.release();
    _transaction = _makeTransaction(msg);
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the newTransaction operation.
  Future<void> _newTransaction(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("New transaction: no active attachment");
    }
    final t = _makeTransaction(msg);
    if (t != null) {
      var tid = t.hashCode;
      _activeTransactions[tid] = t;
      _sendSuccessResp(msg.resultPort, [tid]);
    } else {
      // in fact, if the transaction was not created,
      // _makeTransaction has most likely already thrown FbStatusException
      throw FbClientException("Transaction creation failed (no further info)");
    }
  }

  /// Retrieves the transaction object from _activeTransactions,
  /// based on the provided transaction ID (key).
  /// If the key is null or a transaction assiociated with the key
  /// was not found, the method returns null.
  ITransaction? getActiveTransaction(Object? key) {
    if (key != null && key is int && _activeTransactions.containsKey(key)) {
      return _activeTransactions[key];
    } else if (key != null) {
      throw FbClientException("Invalid transaction handle: $key");
    } else {
      return null;
    }
  }

  /// Handles the commit operation.
  Future<void> _commit(FbDbControlMessage msg) async {
    if (msg.data.isNotEmpty && msg.data[0] != null) {
      // commit an explicit concurrent transaction
      // data[0] contains the transaction key (hash)
      final tid = msg.data[0];
      final t = getActiveTransaction(tid);
      _activeTransactions.remove(tid);
      try {
        status.init();
        t?.commit(status);
      } finally {
        t?.release();
      }
    } else {
      // commit the internal explicit transaction
      _closeAllBlobs();
      if (attachment == null) {
        throw FbClientException("Commit: no active attachment");
      }
      if (_transaction != null) {
        status.init();
        _transaction?.commit(status);
        _transaction = null;
      }
    }
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the rollback operation.
  Future<void> _rollback(FbDbControlMessage msg) async {
    if (msg.data.isNotEmpty && msg.data[0] != null) {
      // commit an explicit concurrent transaction
      // data[0] contains the transaction key (hash)
      final tid = msg.data[0];
      final t = getActiveTransaction(tid);
      _activeTransactions.remove(tid);
      try {
        status.init();
        t?.rollback(status);
      } finally {
        t?.release();
      }
    } else {
      _closeAllBlobs();
      if (attachment == null) {
        throw FbClientException("Rollback: no active attachment");
      }
      if (_transaction != null) {
        status.init();
        _transaction?.rollback(status);
        _transaction = null;
      }
    }
    _sendSuccessResp(msg.resultPort);
  }

  /// Handles the inTransaction operation.
  Future<void> _inTransaction(FbDbControlMessage msg) async {
    ITransaction? t;
    if (msg.data.isNotEmpty && msg.data[0] != null) {
      t = getActiveTransaction(msg.data[0]);
    } else {
      t = _transaction;
    }
    _sendSuccessResp(msg.resultPort, (t != null));
  }

  /// Handles the queryExec operation.
  Future<void> _queryExec(FbDbControlMessage msg) async {
    final fromMain = ReceivePort();
    try {
      final q = FbDbQueryWorker(fromMain, this);
      _activeQueries[q.hashCode] = q;
      final (sql, params, inlineBlobs, withTransaction) = _extractExecData(msg);
      await q._exec(
        sql,
        params,
        allocCursor: false,
        inlineBlobs: inlineBlobs,
        withTransaction: withTransaction,
      );
      unawaited(q._run()); // we don't await run() on purpose
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
      _activeQueries[q.hashCode] = q;
      final (sql, params, inlineBlobs, withTransaction) = _extractExecData(msg);
      await q._exec(
        sql,
        params,
        allocCursor: true,
        inlineBlobs: inlineBlobs,
        withTransaction: withTransaction,
      );
      unawaited(q._run()); // we don't await _run() on purpose
      _sendSuccessResp(msg.resultPort, queryFromMain.sendPort);
    } catch (e) {
      queryFromMain.close();
      rethrow;
    }
  }

  /// Handles the prepareQuery operation.
  Future<void> _prepareQuery(FbDbControlMessage msg) async {
    if (msg.data.isEmpty) {
      throw FbClientException("No SQL statement provided");
    }
    String sql = msg.data[0];
    ITransaction? tra = msg.data.length > 1
        ? getActiveTransaction(msg.data[1])
        : null;
    final fromMain = ReceivePort();
    try {
      final q = FbDbQueryWorker(fromMain, this);
      _activeQueries[q.hashCode] = q;
      await q._prepare(sql, withTransaction: tra);
      unawaited(q._run()); // we don't await run() on purpose
      _sendSuccessResp(msg.resultPort, fromMain.sendPort);
    } catch (e) {
      fromMain.close();
      rethrow;
    }
  }

  /// Handles the createBlob operation
  Future<void> _createBlob(FbDbControlMessage msg) async {
    if (attachment == null) {
      throw FbClientException("No active attachment");
    }
    ITransaction? tra = msg.data.isNotEmpty
        ? getActiveTransaction(msg.data[0])
        : _transaction;
    if (tra == null) {
      throw FbClientException("No active transaction");
    }
    IBlob? iblob;
    var id = FbBlobId(0, 0);
    final fbId = IscQuad.allocate(0, 0);
    try {
      try {
        iblob = attachment!.createBlob(status, tra, fbId);
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
    ITransaction? tra = msg.data.length > 1
        ? getActiveTransaction(msg.data[1])
        : _transaction;
    if (tra == null) {
      throw FbClientException("No active transaction");
    }
    final FbBlobId inId = msg.data[0];
    final fbId = IscQuad.allocate(inId.quadHigh, inId.quadLow);
    try {
      IBlob? iblob;
      try {
        iblob = attachment!.openBlob(status, tra, fbId);
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
    ByteBuffer data = asByteBuffer(msg.data[1]);
    final def = _activeBlobs[id.idHash];
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
    final def = _activeBlobs[id.idHash];
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
    final def = _activeBlobs[id.idHash];
    if (def != null) {
      def.close(status);
      _activeBlobs.remove(id.idHash);
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

  /// Handles the createBatch operation.
  Future<void> _createBatch(FbDbControlMessage msg) async {
    final fromMain = ReceivePort();
    try {
      final b = FbDbBatchWorker(fromMain, this);
      final sql = msg.data[0] as String;
      final FbBatchOptions? options = msg.data[1] as FbBatchOptions?;
      final int transId = msg.data[2] ?? -1;
      ITransaction? transaction;
      if (_activeTransactions.containsKey(transId)) {
        transaction = _activeTransactions[transId];
      }
      await b._prepare(
        sql: sql,
        options: options,
        withTransaction: transaction,
      );
      _activeBatches[b.hashCode] = b;

      unawaited(b._run()); // we don't await run() on purpose
      _sendSuccessResp(msg.resultPort, fromMain.sendPort);
    } catch (e) {
      fromMain.close();
      rethrow;
    }
  }

  /// Extracts the SQL statement and the parameters from the message data.
  /// Returns a tuple with:
  /// - SQL statement text
  /// - query parameters list
  /// - inline blobs flag
  /// - custom transaction hash
  (String, List<dynamic>, bool, ITransaction?) _extractExecData(
    FbDbControlMessage msg,
  ) {
    if (msg.data.isEmpty) {
      throw FbClientException("No SQL statement provided");
    }
    String sql = msg.data[0];
    List<dynamic> params =
        (msg.data.length > 1 ? msg.data[1] : const []) ?? const [];
    bool inlineBlobs = (msg.data.length > 2 ? msg.data[2] : true) ?? true;
    ITransaction? t = (msg.data.length > 3
        ? getActiveTransaction(msg.data[3])
        : null);
    return (sql, params, inlineBlobs, t);
  }

  /// Sends a success message with a payload to the main isolate.
  /// If obj is a list, it's being sent as the actual payload.
  /// Every other object is wrapped in a one-item list.
  void _sendSuccessResp(SendPort toMain, [dynamic obj]) {
    final payload = obj is List ? obj : [?obj];
    toMain.send(FbDbResponse(FbDbResponseOp.success, payload));
  }

  /// Sends an error message with a payload to the main isolate.
  /// If obj is a list, it's being sent as the actual payload.
  /// Every other object is wrapped in a one-item list.
  void _sendErrorResp(SendPort toMain, [dynamic obj]) {
    final payload = obj is List ? obj : [?obj];
    toMain.send(FbDbResponse(FbDbResponseOp.error, payload));
  }

  /// Closes all active blobs and clears the [_activeBlobs] map.
  void _closeAllBlobs() {
    for (var b in _activeBlobs.values) {
      try {
        b.close(status);
      } catch (_) {}
    }
    _activeBlobs.clear();
  }

  /// Closes all active batches and clears the [_activeBatches] map.
  void _closeAllBatches() {
    for (final b in _activeBatches.values) {
      try {
        b._close(updateActiveBatches: false);
      } catch (_) {}
    }
    _activeBatches.clear();
  }

  /// Adds a blob definition to active blobs.
  void _addBlobDef(FbBlobDef d) {
    if (d.id != null) {
      _activeBlobs[d.id!.idHash] = d;
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
          db._sendErrorResp(
            (msg as FbDbControlMessage).resultPort,
            FbServerException.fromStatus(se.status, util: util),
          );
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

        case FbDbControlOp.execQueryPrepared:
          await _execQueryPrepared(msg);

        case FbDbControlOp.openQueryPrepared:
          await _openQueryPrepared(msg);

        case FbDbControlOp.isQueryPrepared:
          await _isQueryPrepared(msg);

        default:
          throw FbClientException(
            "FbDbQueryWorker operation not supported: ${msg.op.name}",
          );
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
      db._activeQueries.remove(hashCode);
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
      final FbRowFormat format = msg.data.isNotEmpty
          ? msg.data[0]
          : FbRowFormat.asMap;
      final values = getRowValues(
        _outMsg,
        _outputMetadata,
        db,
        _transaction,
        util,
        _getInternalBuffer(),
        _internalBufferSize,
        _inlineBlobs,
      );
      if (format == FbRowFormat.asList) {
        db._sendSuccessResp(msg.resultPort, [values]);
      } else {
        final rec = Map<String, dynamic>.fromIterables(
          _fieldNames ?? [],
          values,
        );
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
        msg.resultPort,
        _statement?.getAffectedRecords(db.status) ?? 0,
      );
    } else {
      throw FbClientException(
        "affectedRows not available: no active DML query",
      );
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
    final FbRowFormat format = msg.data.isNotEmpty
        ? msg.data[0]
        : FbRowFormat.asMap;
    final values = getRowValues(
      _outMsg,
      _outputMetadata,
      db,
      _transaction,
      util,
      _getInternalBuffer(),
      _internalBufferSize,
      _inlineBlobs,
    );
    if (format == FbRowFormat.asList) {
      db._sendSuccessResp(msg.resultPort, values);
    } else {
      final rec = Map<String, dynamic>.fromIterables(_fieldNames ?? [], values);
      db._sendSuccessResp(msg.resultPort, rec);
    }
  }

  /// Handles the execQueryPrepared operation.
  Future<void> _execQueryPrepared(FbDbControlMessage msg) async {
    if (msg.data.length < 2) {
      throw FbClientException("Malformed execQueryPrepared message");
    }
    await _execPrepared(
      msg.data[0],
      allocCursor: false,
      inlineBlobs: msg.data[1],
      withTransaction: (msg.data.length > 2
          ? db.getActiveTransaction(msg.data[2])
          : null),
    );
    db._sendSuccessResp(msg.resultPort);
  }

  /// Handles the openQueryPrepared operation.
  Future<void> _openQueryPrepared(FbDbControlMessage msg) async {
    if (msg.data.length < 2) {
      throw FbClientException("Malformed execQueryPrepared message");
    }
    await _execPrepared(
      msg.data[0],
      allocCursor: true,
      inlineBlobs: msg.data[1],
      withTransaction: (msg.data.length > 2
          ? db.getActiveTransaction(msg.data[2])
          : null),
    );
    db._sendSuccessResp(msg.resultPort);
  }

  /// Handles the isQueryPrepared operation.
  Future<void> _isQueryPrepared(FbDbControlMessage msg) async {
    db._sendSuccessResp(msg.resultPort, _statement != null);
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
  Future<void> _prepare(String sql, {ITransaction? withTransaction}) async {
    _closeStatement();
    if (db.attachment == null) {
      throw FbClientException(
        "No active database connection associated with the query object",
      );
    }
    ITransaction? tra = withTransaction ?? db._transaction;
    bool ownTransaction = false;
    if (db._transaction == null) {
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
            IStatement.preparePrefetchAffectedRecords,
      );
    } finally {
      if (ownTransaction) {
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

  /// Executes a previously prepared query, either by calling execute
  /// or openCursor, depending on the allocCursor parameter.
  Future<void> _execPrepared(
    List<dynamic> params, {
    required bool allocCursor,
    bool inlineBlobs = true,
    ITransaction? withTransaction,
  }) async {
    if (_statement == null) {
      throw FbClientException("No SQL statement is prepared in this query.");
    }
    final paramCount = _inputMetadata?.getCount(db.status) ?? 0;
    if (paramCount != params.length) {
      throw FbClientException(
        "The number of provided values: ${params.length} "
        "doesn't match the required number of query parameters: $paramCount",
      );
    }
    _inlineBlobs = inlineBlobs;
    _transaction = withTransaction ?? db._transaction;
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
    putParams(
      _inMsg,
      _inputMetadata,
      params,
      db.status,
      db,
      _transaction,
      _getInternalBuffer(),
      _internalBufferSize,
    );
    if (allocCursor) {
      if (_resultSet != null) {
        _resultSet?.release();
      }
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

  /// Executes a query either by calling execute or openCursor,
  /// depending on the allocCursor parameter.
  Future<void> _exec(
    String sql,
    List<dynamic> params, {
    required bool allocCursor,
    bool inlineBlobs = true,
    ITransaction? withTransaction,
  }) async {
    _inlineBlobs = inlineBlobs;
    await _prepare(sql, withTransaction: withTransaction);
    await _execPrepared(
      params,
      allocCursor: allocCursor,
      inlineBlobs: inlineBlobs,
      withTransaction: withTransaction,
    );
  }

  /// Handles the closeQuery operation.
  Future<void> _closeQuery(FbDbControlMessage msg) async {
    _close();
    db._sendSuccessResp(msg.resultPort);
  }
}

/// The batch worker class.
///
/// Each batch created in the main isolate via a call to [FbDb.batch]
/// causes creation of its peer [FbDbBatchWorker] object
/// in the worker isolate.
class FbDbBatchWorker {
  /// The port, through which commands from the main isolate are received.
  ReceivePort fromMain;

  /// The connection this query will use to talk to the database.
  FbDbWorker db;

  /// An internal transaction, started and ended if no explicit one is present.
  ITransaction? _transaction;

  /// Indicates whether a statement was executed in its own, internal transaction.
  bool _ownTransaction = false;

  /// The batch interface instance used by this worker.
  IBatch? batch;

  /// The input metadata of the current statement.
  IMessageMetadata? _inputMetadata;

  /// The input message buffer (native memory).
  Pointer<Uint8> _inMsg = nullptr;

  /// The length of the input message.
  int _inMsgLen = 0;

  /// The size of the internal buffer (in native memory).
  static const _internalBufferSize = 1024;

  /// Internal buffer for values and blob chunks (native memory).
  ///
  /// The internal buffer is used in marshalling small data pieces
  /// (like ints, dates, blob IDs, etc.), to avoid continuous
  /// allocation and deallocation of small chunks of native memory,
  /// which is costly.
  Pointer<Uint8> _internalBuffer = nullptr;

  /// The record count flag, remembered at the batch creation phase,
  /// useful for optimizations during processing of batch results.
  bool _recordCounts = false;

  /// The default constructor.
  ///
  /// To construct a query worker one needs to pass a receive port
  /// for commands from the main isolate, as well as an active
  /// database connection.
  FbDbBatchWorker(this.fromMain, this.db);

  /// Prepare the batch and set up the worker.
  Future<void> _prepare({
    required String sql,
    FbBatchOptions? options,
    ITransaction? withTransaction,
  }) async {
    _transaction = withTransaction ?? db._transaction;
    if (_transaction == null) {
      // we'll use our own transaction
      db.status.init();
      _transaction = db.attachment?.startTransaction(db.status);
      _ownTransaction = true;
    } else {
      _ownTransaction = false;
    }

    if (_transaction != null) {
      int bpbLength = 0;
      Pointer<Uint8> bpb = nullptr;
      (bpb, bpbLength) = _optionsToBPB(options);
      try {
        db.status.init();
        batch = db.attachment?.createBatch(
          db.status,
          _transaction!,
          sql,
          FbConsts.sqlDialectCurrent,
          null,
          bpbLength,
          bpb,
        );
      } finally {
        if (bpb != nullptr) {
          mem.free(bpb);
          bpb = nullptr;
        }
      }
      _inputMetadata = batch?.getMetadata(db.status);
      _inMsgLen = _inputMetadata?.getMessageLength(db.status) ?? 0;
      if (_inMsgLen > 0) {
        _inMsg = mem.allocate(_inMsgLen);
      }
    } else {
      throw FbClientException("No active transaction and couldn't start one");
    }
  }

  (Pointer<Uint8>, int) _optionsToBPB(FbBatchOptions? options) {
    Pointer<Uint8> bpb = nullptr;
    int bpbLength = 0;
    final builder = _optionsToXpb(options ?? FbBatchOptions());
    try {
      db.status.init();
      bpbLength = builder.getBufferLength(db.status);
      bpb = mem.allocate(bpbLength);
      bpb.fromNativeMem(builder.getBuffer(db.status), bpbLength);
    } finally {
      builder.dispose();
    }
    return (bpb, bpbLength);
  }

  IXpbBuilder _optionsToXpb(FbBatchOptions options) {
    final IXpbBuilder builder = util.getXpbBuilder(
      db.status,
      IXpbBuilder.batch,
    );
    db.status.init();
    // explicit checks for true / false so that null sets nothing
    if (options.multiError == true) {
      builder.insertInt(db.status, IBatch.tagMultierror, 1);
    } else if (options.multiError == false) {
      builder.insertInt(db.status, IBatch.tagMultierror, 0);
    }
    if (options.recordCounts == true) {
      builder.insertInt(db.status, IBatch.tagRecordCounts, 1);
      _recordCounts = true;
    } else if (options.recordCounts == false) {
      builder.insertInt(db.status, IBatch.tagRecordCounts, 0);
      _recordCounts = false;
    }
    if (options.bufferSize != null) {
      builder.insertInt(
        db.status,
        IBatch.tagBufferBytesSize,
        options.bufferSize ?? 16 * 1024 * 1024,
      );
    }
    if (options.maxDetailedErrors != null) {
      builder.insertInt(
        db.status,
        IBatch.tagDetailedErrors,
        options.maxDetailedErrors ?? 64,
      );
    }

    // inline blobs always processed by the engine
    builder.insertInt(db.status, IBatch.tagBlobPolicy, IBatch.blobIdEngine);
    return builder;
  }

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
          db._sendErrorResp(
            (msg as FbDbControlMessage).resultPort,
            FbServerException.fromStatus(se.status, util: util),
          );
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
        case FbDbControlOp.batchClose:
          try {
            _closeBatch(msg);
          } catch (_) {
            // we don't want exceptions when closing
          }
          return false; // end the message loop

        case FbDbControlOp.batchAdd:
          await _add(msg);

        case FbDbControlOp.batchExec:
          await _exec(msg);

        case FbDbControlOp.batchCancel:
          await _cancel(msg);

        case FbDbControlOp.batchInfo:
          await _getInfo(msg);

        default:
          throw FbClientException(
            "FbDbBatchWorker operation not supported: ${msg.op.name}",
          );
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

  /// Handles the batchClose message.
  void _closeBatch(FbDbControlMessage msg) {
    _close();
    db._sendSuccessResp(msg.resultPort);
  }

  /// Cleans up the internal structures of the batch.
  ///
  /// By default also removes the batch from the set of active batches
  /// in the database connection, but it can be turned off with the
  /// [updateActiveBatches] parameter.
  /// Also closes the command channel from the main isolate, rendering
  /// this batch instance unusable from the main isolate's point of view.
  void _close({bool updateActiveBatches = true}) {
    if (_inMsg != nullptr) {
      mem.free(_inMsg);
      _inMsg = nullptr;
    }
    _inMsgLen = 0;
    if (_internalBuffer != nullptr) {
      mem.free(_internalBuffer);
      _internalBuffer = nullptr;
    }
    if (updateActiveBatches) {
      db._activeBatches.remove(hashCode);
    }
    db.status.init();
    if (_ownTransaction) {
      _ownTransaction = false;
      try {
        db.status.init();
        _transaction?.commit(db.status);
      } catch (_) {}
    }
    _transaction = null;
    fromMain.close();
    batch?.release(); // also closes the batch
  }

  /// Handles the batchAdd operation.
  Future<void> _add(FbDbControlMessage msg) async {
    if (batch == null || _inputMetadata == null) {
      throw FbClientException("Cannot add values to a batch: not prepared");
    }
    if (msg.data.isEmpty) {
      throw FbClientException(
        "FbBatchWorker.add: parameter values not provided",
      );
    }
    final List<dynamic> params = msg.data[0];
    final paramCount = _inputMetadata?.getCount(db.status) ?? 0;
    if (paramCount != params.length) {
      throw FbClientException(
        "The number of provided values: ${params.length} "
        "doesn't match the required number of batch statement parameters: "
        "$paramCount",
      );
    }
    db.status.init();
    putParams(
      _inMsg,
      _inputMetadata,
      params,
      db.status,
      db,
      _transaction,
      _getInternalBuffer(),
      _internalBufferSize,
      batch: this,
    );
    batch?.add(db.status, 1, _inMsg);
    db._sendSuccessResp(msg.resultPort, []);
  }

  /// Handles the batchExec operation.
  Future<void> _exec(FbDbControlMessage msg) async {
    if (batch == null) {
      throw FbClientException("Cannot execute batch: not prepared");
    }
    if (_transaction == null) {
      if (_ownTransaction) {
        _transaction = db.attachment?.startTransaction(db.status);
      } else {
        throw FbClientException("Cannot execute batch: no active transaction");
      }
    }
    final bcs = batch?.execute(db.status, _transaction!);
    if (_ownTransaction) {
      _transaction?.commit(db.status);
      _transaction = null;
    }
    if (bcs == null) {
      throw FbClientException("No completion state after batch execution");
    }
    try {
      final tmpStatus = master.getStatus();
      try {
        final bres = FbBatchResult.fromCompletionState(
          status: db.status,
          state: bcs,
          tmpStatus: tmpStatus,
          util: util,
          withRecordCounts: _recordCounts,
        );
        db._sendSuccessResp(msg.resultPort, [bres]);
      } finally {
        tmpStatus.dispose();
      }
    } finally {
      bcs.dispose();
    }
  }

  /// Handles the batchClear operation.
  Future<void> _cancel(FbDbControlMessage msg) async {
    if (batch != null) {
      db.status.init();
      batch?.cancel(db.status);
    }
    db._sendSuccessResp(msg.resultPort, []);
  }

  /// Handles the batchInfo operation.
  Future<void> _getInfo(FbDbControlMessage msg) async {
    if (batch == null) {
      throw FbClientException("Batch interface not available for querying");
    }

    // we need just 3 bytes as input
    final Pointer<Uint8> inPtr = (_internalBuffer + _internalBufferSize - 4)
        .cast();
    inPtr[0] = IBatch.infBufferBytesSize;
    inPtr[1] = IBatch.infDataBytesSize;
    inPtr[2] = IBatch.infBlobsBytesSize;

    // the rest of the buffer will be for output
    final outPtr = _internalBuffer;
    final outBufSize = _internalBufferSize - 4;

    db.status.init();
    batch?.getInfo(db.status, 3, inPtr.cast(), outBufSize, outPtr);

    IXpbBuilder b = util.getXpbBuilder(
      db.status,
      IXpbBuilder.infoResponse,
      outPtr,
      outBufSize,
    );
    var i = FbBatchInfo();
    try {
      for (b.rewind(db.status); !b.isEof(db.status); b.moveNext(db.status)) {
        int val = b.getInt(db.status);
        switch (b.getTag(db.status)) {
          case IBatch.infBufferBytesSize:
            i.maxBufferSize = val;
          case IBatch.infDataBytesSize:
            i.dataSize = val;
          case IBatch.infBlobsBytesSize:
            i.blobSize = val;
        }
      }
    } finally {
      b.dispose();
    }

    db._sendSuccessResp(msg.resultPort, [i]);
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
  withoutCursor,
}

/// Possible operations for control messages.
///
/// Some operations are handled by FbDbWorker, and some other
/// by FbDbQueryWorker objects.
enum FbDbControlOp {
  // commands for FbDbWorker

  /// Check the connection.
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `bool` - attached or not
  ping,

  /// Attach to an existing database.
  /// Input payload:
  /// data[0]: `Map<String, dynamic>` - connection parameters
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the worker
  attach,

  /// Create a new database.
  /// Input payload:
  /// data[0]: `Map<String, dynamic>` - connection and creation parameters
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the worker
  createDatabase,

  /// Detach from the database.
  /// Input payload: none.
  /// Output payload:
  /// none in the normal case
  /// or payload[0]: `Map` - statistics from the tracing allocator
  /// if the worker was created with memory tracing enabled
  detach,

  /// Drop (remove) the database.
  /// Input payload: none.
  /// Output payload:
  /// none in the normal case
  /// or payload[0]: `Map` - statistics from the tracing allocator
  /// if the worker was created with memory tracing enabled
  dropDatabase,

  /// Execute a query without opening a database cursor.
  /// Input payload:
  /// data[0]: `String` - the SQL statement
  /// data[1]: `List<dynamic>` - list of query parameters
  /// data[2]: `bool` - return blobs inline
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the query worker
  queryExec,

  /// Execute a query, opening a database cursor for it.
  /// Input payload:
  /// data[0]: `String` - the SQL statement
  /// data[1]: `List<dynamic>` - list of query parameters
  /// data[2]: `bool` - return blobs inline
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the query worker
  queryOpen,

  /// Start an explicit transaction.
  /// Input payload:
  /// data[0]: `Set<FbTrFlag>?` - transaction flags
  /// data[1]: `int?` - lock timeout
  /// Output payload: none.
  startTransaction,

  /// Register, start and return a new concurrent transaction.
  /// Input payload:
  /// data[0]: `Set<FbTrFlag>?` - transaction flags
  /// data[1]: `int?` - lock timeout
  /// Output payload:
  /// payload[0]: `int` - the handle (hash) of the started transaction
  newTransaction,

  /// Commit an explicit transaction (if there's one pending).
  /// Input payload:
  /// data[0]: `int?` - transaction ID
  /// Output payload: none.
  commit,

  /// Roll an explicit transaction back (if there's one pending).
  /// Input payload:
  /// data[0]: `int?` - transaction ID
  /// Output payload: none.
  rollback,

  /// Check if there is a pending explicit transaction.
  /// Input payload:
  /// data[0]: `int?` - transaction ID
  /// Output payload:
  /// payload[0]: `bool` - whether the transaction is active or not
  inTransaction,

  /// Create a blob in the database.
  /// Input payload:
  /// data[0]: `int?` - transaction ID
  /// Output payload:
  /// payload[0]: `FbBlobId` - ID of the created blob
  createBlob,

  /// Open an existing blob in the database.
  /// Input payload:
  /// data[0]: `FbBlobId` - the ID of the blob to open
  /// data[1]: `int?` - transaction ID
  /// Output payload: none.
  openBlob,

  /// Retrieve a single segment of data from a blob.
  /// Input payload:
  /// data[0]: `FbBlobId` - the ID of the blob
  /// data[1]: `int` - segment size
  /// Output payload:
  /// payload[0]: `ByteBuffer` - the contents of the segment
  getBlobSegment,

  /// Put a single segment of data into a blob.
  /// Input payload:
  /// data[0]: `FbBlobId` - the ID of the blob
  /// data[1]: `ByteBuffer`, `String` or any type convertible to `ByteBuffer` -
  /// the data to be stored in the blob
  /// Output payload: none.
  putBlobSegment,

  /// Close a blob.
  /// Input payload:
  /// data[0]: `FbBlobId` - the ID of the blob
  /// Output payload: none.
  closeBlob,

  /// Immediately quit the worker.
  /// Input payload: none.
  /// Output payload: none (no message at all, worker isolate terminates).
  quit,

  /// Prepare a query for multiple parametrized executions.
  /// Input payload:
  /// data[0]: `String` - the SQL statement to prepare
  /// data[1]: `int?` - transaction ID
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the query
  prepareQuery,

  /// Create a batch.
  /// Input payload:
  /// data[0]: `String` - the SQL statement to batch-execute
  /// data[1]: FbBatchOptions? - the batch parameters (can be null)
  /// data[2]: `int?` - transaction ID
  /// Output payload:
  /// payload[0]: `SendPort` - port to send commands to the batch
  createBatch,

  // ---------- commands for FbDbQueryWorker ----------

  /// Send back field (column) definitions.
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `List<FbFieldDef>` - field definitions
  getFieldDefs,

  /// Send back the next (single) row of data.
  /// Input payload:
  /// data[0]: `FbRowFormat` - the format of the record (list or map)
  /// Output payload:
  /// payload[0]: `null` or `List<dynamic>` or `Map<String, dynamic>` -
  /// the contents of the next row (or null if there is none),
  /// whether a map or a list depends on the requested row format
  fetchNext,

  /// Send back the output parameters (for queries without a cursor).
  /// Input payload:
  /// data[0]: `FbRowFormat` - the format of the record (list or map)
  /// Output payload:
  /// payload[0]: `null` or `List<dynamic>` or `Map<String, dynamic>` -
  /// the contents of the query output message (or null if there is none),
  /// whether a map or a list depends on the requested row format
  getOutput,

  /// Send back the number of rows that have been affected by the last DML query.
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `int` - the number of affected rows
  affectedRows,

  /// Close the query and release all resources.
  /// Input payload: none.
  /// Output payload: none.
  closeQuery,

  /// Execute a prepared query without allocating a cursor.
  /// Input payload:
  /// data[0]: `List<dynamic>` - list of query parameters
  /// data[1]: `bool` - return blobs inline
  /// data[2]: `int?` - transaction ID
  /// Output payload: none.
  execQueryPrepared,

  /// Execute a prepared query with allocating a cursor.
  /// Input payload:
  /// data[0]: `List<dynamic>` - list of query parameters
  /// data[1]: `bool` - return blobs inline
  /// data[2]: `int?` - transaction ID
  /// Output payload: none.
  openQueryPrepared,

  /// Check if a query contains an already prepared statement.
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `bool` - whether a query contains a prepared statement
  isQueryPrepared,

  // ---------- commands for FbDbBatchWorker ----------

  /// Add a new set of parameters to the batch.
  /// Input payload:
  /// data[0]: `List<dynamic>` - list of values to add to the batch
  /// Output payload: none.
  batchAdd,

  /// Execute the batch.
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `FbBatchResult` - status of statements executed in the batch
  batchExec,

  /// Close the batch.
  /// Input payload: none.
  /// Output payload: none.
  batchClose,

  /// Cancel the batch (remove all values added so far).
  /// Input payload: none.
  /// Output payload: none.
  batchCancel,

  /// Get the current batch info (memory usage).
  /// Input payload: none.
  /// Output payload:
  /// payload[0]: `FbBatchInfo` - converted from IBatch.getInfo()
  batchInfo,
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
