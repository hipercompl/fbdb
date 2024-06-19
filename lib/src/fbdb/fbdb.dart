import "dart:io";
import "dart:async";
import "dart:isolate";
import "dart:convert";
import "dart:typed_data";

import "package:fbdb/fbdb.dart";
import "fbdbworker.dart";

/// Represents a database connection.
///
/// Every object of this class encapsulates a connection
/// to a Firebird database and is associated with a background
/// worker isolate to allow for non-blocking I/O operations
/// on the database.
/// To initialize the connection you should call [attach]
/// or [createDatabase], to close the connection call [detach]
/// or [dropDatabase] (the latter physically removes the database
/// file, so take extra care).
///
/// Example:
/// ```dart
/// final db = await FbDb.attach(host: "localhost", database: "employee");
/// // work with the database here using the db attachment object
/// await db.detach();
/// // db cannot be used any more
/// ```
/// For more details, please refer to the FbDb Programmer's Guide.
class FbDb {
  /// Creates a connection to an existing database.
  ///
  /// Use this construction method to connect to an existing [database],
  /// providing authentication credentials in the form
  /// of the [user] name, [password] and database [role].
  /// The password is optional when using an embedded connection,
  /// the role is optional in all cases (specify only when you actually
  /// need to connect with a specific role).
  /// A database server [host] and [port] number can also be specified,
  /// if needed.
  /// The [options] object allows to fine-tune the database connection,
  /// see the description of the [FbOptions] class. It is optional.
  /// If successful, this method returns a ready to use FbDb
  /// object, representing an active database connection, with a background
  /// (worker) isolate spawned and attached to the connection.
  /// You should call [detach] on the connection to disconnect
  /// from the database and free associated resources (and to end the
  /// worker isolate).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// // work with the database here using the db attachment object
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  static Future<FbDb> attach(
      {String? host,
      int? port,
      required String database,
      String? user,
      String? password,
      String? role,
      FbOptions? options}) async {
    final db = await FbDb._createWorker(options?.libFbClient);
    final args = _argsToMap(
      host: host,
      port: port,
      database: database,
      user: user,
      password: password,
      role: role,
      options: options,
    );
    try {
      await db._attach(args);
      _finalizer.attach(db, db._toWorker, detach: db);
    } catch (_) {
      db._terminateWorker();
      rethrow;
    }
    return db;
  }

  /// Attempts to create a new database and connect to it.
  ///
  /// Use this construction method to create a new [database],
  /// optionally providing authentication credentials in the form
  /// of the [user] name, [password] and database [role].
  /// If needed, you can specify the database server [host]
  /// and [port] number.
  /// The [options] object allows to fine-tune the connection
  /// and set some parameters for the new database
  /// (like [FbOptions.pageSize] and [FbOptions.dbCharset]).
  /// See also the description of the [FbOptions] class.
  /// If successful, this method returns a ready to use FbDb
  /// object, representing an active database connection
  /// to the newly created database.
  /// You should call [detach] on the connection to disconnect
  /// from the database and free associated resources
  /// (and end the background worker isolate).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.createDatabase(
  ///   host: "localhost",
  ///   database: "testdb",
  ///   options: FbOptions(pageSize: 8192, dbCharset: "UTF8"),
  /// );
  /// // work with the database here using the db attachment object
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  static Future<FbDb> createDatabase(
      {String? host,
      int? port,
      required String database,
      String? user,
      String? password,
      String? role,
      FbOptions? options}) async {
    final db = await FbDb._createWorker(options?.libFbClient);
    final args = _argsToMap(
      host: host,
      port: port,
      database: database,
      user: user,
      password: password,
      role: role,
      options: options,
    );
    try {
      await db._createDatabase(args);
      _finalizer.attach(db, db._toWorker, detach: db);
    } catch (_) {
      db._terminateWorker();
      rethrow;
    }
    return db;
  }

  /// Checks if a connection is valid.
  ///
  /// Communicates with the background worker isolate
  /// and checks whether the worker still has a valid
  /// database handle.
  /// If the result of this method resolves to `true`,
  /// the worker isolate is running and responding.
  /// Otherwise it's more likely that an exception will occur
  /// than that `false` will be returned, so you should
  /// always call this method in a `try` block.
  Future<bool> ping() async {
    final resp = await _askWorker(FbDbControlOp.ping, []);
    return (resp.data.isNotEmpty && resp.data[0]);
  }

  /// Closes the database connection.
  ///
  /// After calling [detach], the connection object
  /// cannot be used any longer. Closing the connection may take
  /// some time, as it requires closing all active queries and
  /// ending the background worker isolate. Also, in some cases
  /// an exception may be thrown, so [detach] should be called
  /// in a `try` ... `catch` context, like any other method
  /// which may fail.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// // work with the database here using the db attachment object
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  Future<void> detach() async {
    try {
      await _closeActiveQueries();
      final resp = await _askWorker(FbDbControlOp.detach, []);
      if ((mem is TracingAllocator) &&
          resp.data.isNotEmpty &&
          resp.data[0] is Map) {
        _updateMemStats(resp.data[0]);
      }
    } catch (_) {
      _terminateWorker();
    } finally {
      _workerTerminated();
      _finalizer.detach(this);
    }
  }

  /// Physically removes the currently attached database.
  ///
  /// This method should be used with extreme care.
  /// It is equivalent to issuing the DROP DATABASE statement,
  /// which irrevocably removes the currently open database file
  /// (assuming the current user has sufficient permissions).
  /// It also (obviously) closes the database connection
  /// (after [dropDatabase] the connection is invalid and
  /// can't be used in any way).
  /// This method may result in an exception, so it should be called
  /// within a `try` block, like any other DB-related method
  /// (don't rely on [detach] or [dropDatabase] to succeed in all
  /// circumstances).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "testdb");
  /// // work with the database here using the db attachment object
  /// await db.dropDatabase(); // physically deletes "testdb"
  /// // db cannot be used any more
  /// ```
  Future<void> dropDatabase() async {
    try {
      await _closeActiveQueries();
      final resp = await _askWorker(FbDbControlOp.dropDatabase, []);
      if ((mem is TracingAllocator) &&
          resp.data.isNotEmpty &&
          resp.data[0] is Map) {
        _updateMemStats(resp.data[0]);
      }
    } catch (_) {
      _terminateWorker();
    } finally {
      _workerTerminated();
      _finalizer.detach(this);
    }
  }

  /// Creates a new query object associated with this connection.
  ///
  /// Creating a query object of itself does not interact with
  /// the database in any way. Only after calling [FbQuery.execute]
  /// or [FbQuery.openCursor] the actual SQL statement gets executed.
  /// However, to execute a statement, first you need a valid [FbQuery]
  /// object, associated with an active database attachment.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// final q = db.query(); // note: no await here
  /// // work with the query
  /// await q.close(); // close the query
  /// // query object can still be used after close
  /// // e.g. to execute another SQL statement
  /// await db.detach(); // detach from the database
  /// // db cannot be used any more
  /// ```
  FbQuery query() {
    return FbQuery.forDb(this);
  }

  /// Starts an explicit transaction.
  ///
  /// If an explicit transaction is already pending (has been started
  /// but hasn't been ended), this method has no effect (but doesn't throw
  /// in such scenario).
  /// If [flags] are not provided, the default connection flags
  /// will be used (see [FbDb.attach], [FbDb.createDatabase] and [FbOptions]).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction();
  /// // execute statements
  /// await db.commit(); // or db.rollback()
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  Future<void> startTransaction(
      {Set<FbTrFlag>? flags, int? lockTimeout}) async {
    await _askWorker(FbDbControlOp.startTransaction, [flags, lockTimeout]);
  }

  /// Commits an explicit transaction.
  ///
  /// If no explicit transaction has been started, does nothing (but
  /// doesn't throw).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction();
  /// // execute statements
  /// await db.commit();
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  Future<void> commit() async {
    await _askWorker(FbDbControlOp.commit, []);
  }

  /// Rolls back en explicit transaction.
  ///
  /// If no explicit transaction has been started, does nothing (but
  /// doesn't throw).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction();
  /// // execute statements
  /// await db.rollback();
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  Future<void> rollback() async {
    await _askWorker(FbDbControlOp.rollback, []);
  }

  /// Checks if an explicit transaction is currently pending.
  ///
  /// This method has to communicate with the worker isolate,
  /// so it has to be awaited like most other database methods.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction();
  /// // execute statements
  /// if (await db.inTransaction()) { // remember to await the result
  ///   await db.commit(); // or db.rollback()
  /// }
  /// await db.detach();
  /// // db cannot be used any more
  /// ```
  Future<bool> inTransaction() async {
    final r = await _askWorker(FbDbControlOp.inTransaction, []);
    return (r.data.isNotEmpty && r.data[0] is bool && r.data[0]);
  }

  /// Creates a new blob in the database.
  ///
  /// Allocates a new blob resource, ready to accept data segments.
  /// Returns the blob ID to be used in subsequent references to the blob.
  /// See also FbDb Programmer's Guide for more information on blob handling.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final blobId = await db.createBlob();
  /// await db.putBlobFromStream(
  ///   id: blobId,
  ///   stream: File("data.bin")
  ///     .openRead()
  ///     .map((buf) => Uint8List.fromList(buf).buffer),
  /// );
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.execute(
  ///   sql: "insert into TEST_TABLE(BLOB_COL) values (?)",
  ///   parameters: [blobId], // just the id, not the data
  /// );
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<FbBlobId> createBlob() async {
    return (await _askWorker(FbDbControlOp.createBlob, [])).data[0];
  }

  /// Opens an existing blob for reading.
  ///
  /// For a given [FbBlobId], opens the blob in the database and returns
  /// a stream of byte buffers, which allows to read the binary data
  /// from the blob. The [segmentSize] determines the maximum size
  /// of the buffer a single read from the stream can yield.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.openCursor(
  ///   sql: "SELECT BLOB_COL from TEST_TABLE",
  ///   inlineBlobls: false, // get blob ID instead of a buffer
  /// );
  /// final row = await q.fetchOneAsMap();
  /// final blobId = row["BLOB_COL"];
  /// final blobStream = await db.openBlob(id: blobId);
  /// await for (var segment in blobStream) {
  ///   // process the BLOB data segment
  /// }
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<Stream<ByteBuffer>> openBlob({
    required FbBlobId id,
    int segmentSize = 4096,
  }) async {
    if (segmentSize <= 0) {
      throw FbClientException("Invalid blob segment size: $segmentSize");
    }
    await _askWorker(FbDbControlOp.openBlob, [id]);
    return () async* {
      for (;;) {
        final r =
            await _askWorker(FbDbControlOp.getBlobSegment, [id, segmentSize]);
        if (r.data.isNotEmpty && r.data[0] != null) {
          ByteBuffer buf = r.data[0];
          yield buf;
        } else {
          break;
        }
      }
    }();
  }

  /// Closes a previously created or opened blob.
  ///
  /// You don't need to close a blob if you depleted its data stream
  /// completely or ended the transaction the blob was in scope of.
  Future<void> closeBlob({required FbBlobId id}) async {
    await _askWorker(FbDbControlOp.closeBlob, [id]);
  }

  /// Sends a data segment of a blob to the database.
  ///
  /// The blob [id] has to correspond with a previously created
  /// blob.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final blobId = await db.createBlob();
  /// // send the blob data to the database in chunks
  /// await for (var segment in File("data.bin").openRead()) {
  ///   await db.putBlobSegment(id: blobId, data: segment);
  /// }
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.execute(
  ///   sql: "insert into TEST_TABLE(BLOB_COL) values (?)",
  ///   parameters: [blobId], // just the id, not the data
  /// );
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<void> putBlobSegment({
    required FbBlobId id,
    required ByteBuffer data,
  }) async {
    await _askWorker(FbDbControlOp.putBlobSegment, [id, data]);
  }

  /// Sends a string as a blob's data segment to the database.
  ///
  /// The blob [id] has to correspond with a previously created
  /// blob. The string [data] is automatically converted to UTF-8
  /// and then sent to the database to be appended to the blob.
  Future<void> putBlobSegmentStr({
    required FbBlobId id,
    required String data,
  }) async {
    return putBlobSegment(id: id, data: utf8.encode(data).buffer);
  }

  /// Fills a blob with data from the provided stream.
  ///
  /// The blob [id] has to correspond with a previously created
  /// blob.
  /// The method will keep sending data buffers from the <stream> until
  /// the stream is completely exhausted.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final blobId = await db.createBlob();
  /// await db.putBlobFromStream(
  ///   id: blobId,
  ///   stream: File("data.bin")
  ///     .openRead()
  ///     .map((buf) => Uint8List.fromList(buf).buffer),
  /// );
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.execute(
  ///   sql: "insert into TEST_TABLE(BLOB_COL) values (?)",
  ///   parameters: [blobId], // just the id, not the data
  /// );
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<void> putBlobFromStream({
    required FbBlobId id,
    required Stream<ByteBuffer> stream,
  }) async {
    await for (var data in stream) {
      await putBlobSegment(id: id, data: data);
    }
    await closeBlob(id: id);
  }

  /// Fills a blob with data from the provided file.
  ///
  /// The blob [id] has to correspond with a previously created
  /// blob.
  /// The size of the chunks read from the file is not controlled
  /// by FbDb (the file is opened with [File.openRead], which
  /// provides a stream that spits buffers of various sizes, depending
  /// on the actual speed and availability of the file data).
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final blobId = await db.createBlob();
  /// await db.blobFromFile(
  ///   id: blobId,
  ///   file: File("data.bin"),
  /// );
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.execute(
  ///   sql: "insert into TEST_TABLE(BLOB_COL) values (?)",
  ///   parameters: [blobId], // just the id, not the data
  /// );
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<void> blobFromFile({
    required FbBlobId id,
    required File file,
  }) async {
    return putBlobFromStream(
      id: id,
      stream: file
          .openRead()
          .map((byteValues) => Uint8List.fromList(byteValues).buffer),
    );
  }

  /// Save the data from a blob to a file.
  ///
  /// The blob [id] has to correspond with a previously created
  /// blob.
  /// The [segmentSize] allows to determine the size of a single
  /// chunk that will be transferred from the database and appended
  /// to the [file].
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.startTransaction(); // remember to start an explicit transaction
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.openCursor(
  ///   sql: "SELECT BLOB_COL from TEST_TABLE",
  ///   inlineBlobls: false, // get blob ID instead of a buffer
  /// );
  /// final row = await q.fetchOneAsMap();
  /// final blobId = row["BLOB_COL"];
  /// await db.blobToFile(id: blobId, file: File("data.bin"));
  /// await db.commit(); // commit the started transaction
  /// await db.detach();
  /// ```
  Future<void> blobToFile({
    required FbBlobId id,
    required File file,
    int segmentSize = 4096,
  }) async {
    final blobStream = await openBlob(id: id, segmentSize: segmentSize);
    final sink = file.openWrite();
    await sink.addStream(blobStream.map<Uint8List>((buf) => buf.asUint8List()));
    await sink.close();
  }

  /// Utility method - selects a single row and reurns it as a map.
  ///
  /// This method is a shortcut to obtaining a query, opening a cursor
  /// on the query with the given SQL statement, and fetching a single
  /// row. The row is returned as a map, with keys corresponding
  /// to column names, and values being the actual column values
  /// in the row.
  /// A [FbQuery] object is created internally and closed automatically
  /// when the query completes.
  /// The parameters are the same as in [FbQuery.openCursor].
  Future<Map<String, dynamic>?> selectOne({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
  }) async {
    final q = query();

    try {
      await q.openCursor(
        sql: sql,
        parameters: parameters,
        inlineBlobs: inlineBlobs,
      );
      return await q.fetchOneAsMap();
    } finally {
      await q.close();
    }
  }

  /// Utility method - selects all rows and reurns then as a list of maps.
  ///
  /// This method is a shortcut to obtaining a query, opening a cursor
  /// on the query with the given SQL statement, and fetching all
  /// rows into a list. The rows inside the list are maps,
  /// with keys corresponding to column names, and values being
  /// the actual column values in each row.
  /// A [FbQuery] object is created internally and closed automatically
  /// when the query completes and all rows are fetched.
  /// The parameters are the same as in [FbQuery.openCursor].
  /// Keep in mind, that all rows are cached in the memory, so for
  /// queries returning large data sets, the memory consumption
  /// can be significant.
  Future<List<Map<String, dynamic>>?> selectAll({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
  }) async {
    final q = query();

    try {
      await q.openCursor(
        sql: sql,
        parameters: parameters,
        inlineBlobs: inlineBlobs,
      );
      return await q.fetchAllAsMaps();
    } finally {
      await q.close();
    }
  }

  // --------------------------------------------------------------------
  // --------------------------- private API ----------------------------
  // --------------------------------------------------------------------

  SendPort? _toWorker;
  Isolate? _worker;
  final Map<int, FbQuery> _activeQueries = {};

  FbDb._init(this._worker, this._toWorker);

  /// Spawns the worker isolate, sets up the database connection
  /// object and returns the ready to use connection object.
  ///
  /// Does not connect to the actual database.
  /// Doing so requires a separate attach or createDatabase
  /// message to be sent to the worker isolate.
  static Future<FbDb> _createWorker([String? libPath]) async {
    final fromWorker = ReceivePort();

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn(
        workerRunner,
        [
          fromWorker.sendPort,
          libPath,
          mem is TracingAllocator,
        ],
        errorsAreFatal: true,
        debugName: 'FbDbWorker',
      );

      // the first message from the worker isolate contains the SendPort
      // used to control the worker
      final msg = await fromWorker.first;
      _throwIfErrorResponse(msg);
      if (msg is! FbDbResponse || msg.data.isEmpty) {
        throw FbClientException(
          "Establishing database connection failed (expected response "
          "object from worker isolate with a send port, "
          "got ${msg.runtimeType})",
        );
      }
      SendPort toWorker = msg.data[0];

      return FbDb._init(isolate, toWorker);
    } catch (e) {
      fromWorker.close();
      rethrow;
    }
  }

  /// Packs the arguments to a map, to be passed to the worker
  /// isolate upon spawning it.
  static Map<String, dynamic> _argsToMap(
      {String? host,
      int? port,
      required String database,
      String? user,
      String? password,
      String? role,
      FbOptions? options}) {
    return {
      if (host != null) "host": host,
      if (port != null) "port": port,
      "database": database,
      if (user != null) "user": user,
      if (password != null) "password": password,
      if (role != null) "role": role,
      if (options != null) "options": options,
    };
  }

  /// Sends a control message to the worker and waits for
  /// the worker's response.
  ///
  /// Checks the response for possible error
  /// conditions (upon those it throws an exception) and finally
  /// returns the response message.
  /// Creates a separate ReceivePort for the operation (i.e. each call
  /// to [_askWorker] uses a separate, one-shot ReceivePort).
  Future<FbDbResponse> _askWorker(FbDbControlOp op, List<dynamic> args,
      [SendPort? toWorker]) async {
    toWorker ??= _toWorker;
    if (_worker == null || toWorker == null) {
      throw FbClientException(
          "No active worker isolate associated with the connection");
    }
    final resultPort = ReceivePort();
    try {
      toWorker.send(FbDbControlMessage(op, resultPort.sendPort, args));
      final resp = await resultPort.first;
      _throwIfErrorResponse(resp);
      return resp;
    } finally {
      resultPort.close();
    }
  }

  /// Implements the attach operation.
  Future<void> _attach(Map<String, dynamic> args) async {
    try {
      await _askWorker(FbDbControlOp.attach, [args]);
    } catch (_) {
      _terminateWorker();
      rethrow;
    }
  }

  /// Implements the createDatabase operation.
  Future<void> _createDatabase(Map<String, dynamic> args) async {
    try {
      await _askWorker(FbDbControlOp.createDatabase, [args]);
    } catch (_) {
      _terminateWorker();
      rethrow;
    }
  }

  /// Clears internal structures after the worker has been terminated.
  void _workerTerminated() {
    _finalizer.detach(this);
    _toWorker = null;
    _worker = null;
  }

  /// Sends the termination message to the worker.
  void _terminateWorker() {
    final p = ReceivePort();
    try {
      _toWorker?.send(FbDbControlMessage(FbDbControlOp.quit, p.sendPort, []));
    } finally {
      p.close();
    }
    _workerTerminated();
  }

  /// Detaches all active queries from this connection.
  Future<void> _closeActiveQueries() async {
    final keys = List<int>.from(_activeQueries.keys);
    for (var key in keys) {
      final q = _activeQueries[key];
      try {
        await q?.close();
      } catch (_) {}
      q?._detachConnection();
    }
    _activeQueries.clear();
  }

  /// Update memory statistics with those obtained from the worker isolate.
  void _updateMemStats(Map<String, int> mems) {
    final m = mem as TracingAllocator;
    m.allocatedSum += mems["allocatedSum"] ?? 0;
    m.allocationCount += mems["allocationCount"] ?? 0;
    m.freeCount += mems["freeCount"] ?? 0;
    m.freedSum += mems["freedSum"] ?? 0;
    final maxAl = mems["maxAllocated"] ?? 0;
    if (maxAl > m.maxAllocated) {
      m.maxAllocated = maxAl;
    }
  }

  /// The finalizer to end the worker isolate when this connection
  /// gets garbage collected and the worker is still active.
  static final Finalizer<SendPort?> _finalizer = Finalizer((port) {
    port?.send(FbDbControlMessage(FbDbControlOp.quit, port, []));
  });
}

/// The database query object.
///
/// Allows sending SQL statements to the database, as well as
/// fetching data back.
///
/// Example:
/// ```dart
/// final db = await FbDb.attach(host: "localhost", database: "employee");
/// final q = db.query(); // note: no await here
/// await q.openCursor(sql: "select FIRST_NAME, LAST_NAME from EMPLOYEE");
/// await for (var row in q.rows()) {
///   print("${row['LAST_NAME']}, ${row['FIRST_NAME']}");
/// };
/// await q.close(); // close the query
/// // query object can still be used after close
/// // e.g. to execute another SQL statement
/// await db.detach(); // detach from the database
/// // db cannot be used any more
/// ```
class FbQuery {
  /// Creates a query object associated with the specific database connection.
  FbQuery.forDb(this._db);

  /// Closes the query (if active).
  ///
  /// Releases all internal data associated with the active query.
  /// If there is no active (executed but not closed) statement associated
  /// with this query object, the call has no effect (but will not throw).
  Future<void> close() async {
    if (_db != null && _toWorker != null) {
      final resp = await _db?._askWorker(
        FbDbControlOp.closeQuery,
        [],
        _toWorker,
      );
      _toWorker = null;
      _db?._activeQueries.remove(hashCode);
      _throwIfErrorResponse(resp);
      return;
    }
    _toWorker = null;
  }

  /// Executes an SQL statement, which does not return a data set
  /// and doesn't require a database cursor.
  ///
  /// This method should be used for executing all kinds of DML or DDL
  /// statements (INSERT / UPDATE / DELETE / CREATE / ALTER / DROP).
  /// It can also be used to execute stored procedures, which return
  /// values via output parameters (don't use SUSPEND statements).
  /// [execute] does not allocate a database cursor, therefore
  /// the methods used to access the resulting data set are not
  /// available and will throw exceptions when used.
  /// See [openCursor] for executing queries with cursor allocation.
  /// The only way to access output data of a statement run with [execute]
  /// (e.g. the values of output parameters of a stored procedure)
  /// is to use [getOutputAsMap] or [getOutputAsList].
  /// [sql] must be a valid SQL statement, which can optionally contain
  /// `?` (question mark) placeholders for _value_ parameters
  /// (the placeholders can't parametrize database objects, like
  /// table or column names, only the actual values placed in the statement).
  /// For each `?` placeholder, a corresponding value should be passed
  /// in the [parameters] list (the type must correspond to the expected
  /// value type implied by the context in which the placeholder appears
  /// in the statement).
  ///
  /// Example:
  /// ```dart
  /// await q.execute(
  ///   sql: "update DEPARTMENT set BUDGET = BUDGET + ? "
  ///        "where DEPT_NO = ?",
  ///   parameters: [100.0, "180"] // two parameters: a double and a string
  /// );
  /// final rowCnt = await q.affectedRows();
  /// await q.Close();
  /// ```
  Future<FbQuery> execute({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
  }) async {
    if (_db == null) {
      throw FbClientException("No active database connection");
    }
    await close(); // close the previously associated worker, if any
    final msg = await _db?._askWorker(
      FbDbControlOp.queryExec,
      [sql, parameters, inlineBlobs],
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty) {
      throw FbClientException(
        "FbQuery: connection worker did not provide "
        "a send port for the query",
      );
    }
    _toWorker = r.data[0];
    _db?._activeQueries[hashCode] = this;
    return this;
  }

  /// Executes an SQL statement, which returns a data set
  /// and requires allocation of a database cursor.
  ///
  /// This method should be used for executing SELECT
  /// statements, or EXECUTE BLOCK which returns a set of rows
  /// (i.e. contains SUSPEND statements).
  /// [openCursor] allocates a database cursor, so after
  /// execution of the SQL statement, you can use methods
  /// allowing access to the result set (like [rows], [fetchOneAsMap], etc.).
  /// [sql] must be a valid SQL statement, which can optionally contain
  /// [sql] must be a valid SQL statement, which can optionally contain
  /// `?` (question mark) placeholders for _value_ parameters
  /// (the placeholders can't parametrize database objects, like
  /// table or column names, only the actual values placed in the statement).
  /// For each `?` placeholder, a corresponding value should be passed
  /// in the [parameters] list (the type must correspond to the expected
  /// value type implied by the context in which the placeholder appears
  /// in the statement).
  /// The [inlineBlobs] parameter allows you to specify the way blob columns
  /// are to be treated. If [inlineBlobs] is `true`, all blob columns will
  /// be returned inside data rows as [ByteBuffer] objects. Otherwise, only
  /// the blob IDs will be present in the row data and to access the actual
  /// blob binary data you need to use [FbDb.openBlob] or [FbDb.blobToFile].
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// await for (var row in q.rows()) {
  ///   // process the row (which is a dictionary)
  /// }
  /// await q.close();
  /// ```
  Future<FbQuery> openCursor({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
  }) async {
    if (_db == null) {
      throw FbClientException("No active database connection");
    }
    await close(); // close the previously associated worker, if any
    final msg = await _db?._askWorker(
      FbDbControlOp.queryOpen,
      [sql, parameters, inlineBlobs],
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty) {
      throw FbClientException(
        "FbQuery: connection worker did not provide "
        "a send port for the query",
      );
    }
    _toWorker = r.data[0];
    _db?._activeQueries[hashCode] = this;
    return this;
  }

  /// Fetches the next set of rows from the data set as maps.
  ///
  /// The keys of the resulting maps correspond with the column names
  /// of the selected data.
  /// The [rowCount] is the maximum number of rows that are to be fetched
  /// and returned (the actual number of items in the resulting list
  /// may be smaller if there is no more data in the result set).
  Future<List<Map<String, dynamic>>> fetchAsMaps([int rowCount = 1]) async {
    List<Map<String, dynamic>> res = [];
    if (rowCount <= 0) {
      return res;
    }
    int cnt = 0;
    await for (var row in rows()) {
      res.add(row);
      cnt++;
      if (cnt >= rowCount) {
        break;
      }
    }
    return res;
  }

  /// Fetches the next set of rows from the data set as lists.
  ///
  /// This method, unlike [fetchAsMaps], returns only the values
  /// of the selected data, omitting the names of the columns
  /// (this way less data is transferred between the worker and main
  /// isolates).
  /// The [rowCount] is the maximum number of rows that are to be fetched
  /// and returned (the actual number of items in the resulting list
  /// may be smaller if there is no more data in the result set).
  Future<List<List<dynamic>>> fetchAsLists([int rowCount = 1]) async {
    List<List<dynamic>> res = [];
    if (rowCount <= 0) {
      return res;
    }
    int cnt = 0;
    await for (var row in rowValues()) {
      res.add(row);
      cnt++;
      if (cnt >= rowCount) {
        break;
      }
    }
    return res;
  }

  /// Fetches all rows from the data set as maps.
  ///
  /// Fetches all rows as returned by the database, without any
  /// upper bound. You should use this method only if you're fairly
  /// sure the size of the result set is reasonable.
  /// In general it's better to use [fetchAsMaps] with an upper bound
  /// on the number of rows.
  /// The resulting maps have keys corresponding to the names of
  /// the selected columns.
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// final allRows = await q.fetchAllAsMaps();
  /// // allRows is a list of maps
  /// print(allRows[0]["DEPT_NO"]);
  /// await q.close();
  /// // allRows retains the data after the query gets closed
  /// ```
  Future<List<Map<String, dynamic>>> fetchAllAsMaps() async {
    return rows().toList();
  }

  /// Fetches all rows from the data set as lists.
  ///
  /// Fetches all rows as returned by the database, without any
  /// upper bound. You should use this method only if you're fairly
  /// sure the size of the result set is reasonable.
  /// In general it's better to use [fetchAsLists] with an upper bound
  /// on the number of rows.
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// final allRows = await q.fetchAllAsLists();
  /// // allRows is a list of lists
  /// print(allRows[0][0]); // print the first column of the first row
  /// await q.close();
  /// // allRows retains the data after the query gets closed
  /// ```
  Future<List<List<dynamic>>> fetchAllAsLists() async {
    return rowValues().toList();
  }

  /// Fetches the next row from the data set as a map.
  ///
  /// The resulting map has keys corresponding to the names of
  /// the selected columns.
  /// If there are no more rows in the result set, this method
  /// returns `null`, allowing for a nice pattern to be used:
  /// `fetchOneAsMap` until `null` is returned to process all
  /// rows, one at a time (however, in such scenario probably
  /// using a stream returned by [rows] is more convenient).
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// final row = await q.fetchOneAsMap();
  /// // row is a map
  /// print(allRows["DEPT_NO"]);
  /// await q.close();
  /// // row retains the data after the query gets closed
  /// ```
  Future<Map<String, dynamic>?> fetchOneAsMap() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.fetchNext,
      [FbRowFormat.asMap],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return null;
    } else {
      return r.data[0];
    }
  }

  /// Fetches the next row from the data set as a list.
  ///
  /// If there are no more rows in the result set, this method
  /// returns `null`, allowing for a nice pattern to be used:
  /// `fetchOneAsList` until `null` is returned to process all
  /// rows, one at a time (however, in such scenario probably
  /// using a stream returned by [rowValues] is more convenient).
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// final row = await q.fetchOneAsList();
  /// // row is a list of values only
  /// print(allRows[0]); // print the first column
  /// await q.close();
  /// // row retains the data after the query gets closed
  /// ```
  Future<List<dynamic>?> fetchOneAsList() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.fetchNext,
      [FbRowFormat.asList],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return null;
    } else {
      return r.data[0];
    }
  }

  /// Streams all rows from the data set as maps.
  ///
  /// The resulting maps have keys corresponding to the names of
  /// the selected columns.
  /// The stream ends when all rows from the result set have been
  /// fetched from the database and streamed to the calling code.
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// await for (var row in q.rows()) {
  ///   print(row["DEPT_NO"]);
  /// }
  /// await q.close();
  /// ```
  Stream<Map<String, dynamic>> rows() async* {
    Map<String, dynamic>? row = {};
    while (row != null) {
      row = await fetchOneAsMap();
      if (row != null) {
        yield row;
      }
    }
  }

  /// Streams all rows from the data set as lists.
  ///
  /// The stream ends when all rows from the result set have been
  /// fetched from the database and streamed to the calling code.
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// await for (var row in q.rowValues()) {
  ///   print(row[0]); // print the value from the first column
  /// }
  /// await q.close();
  /// ```
  Stream<List<dynamic>> rowValues() async* {
    List<dynamic>? row = [];
    while (row != null) {
      row = await fetchOneAsList();
      if (row != null) {
        yield row;
      }
    }
  }

  /// Retrieves field / column definitions of the query output.
  ///
  /// If the query has any output data (i.e. it is either a SELECT
  /// query, an EXECUTE BLOCK with suspends or an EXECUTE PROCEDURE
  /// with output parameters), the definition of the data columns
  /// can be obtained using [fieldDefs].
  /// Please refer to the documentation of [FbFieldDef] for the list
  /// of properties that can be obtained for each column / field.
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// final fields = await q.fieldDefs();
  /// // print all column names
  /// for (var d in fields) {
  ///   print(d.name);
  /// }
  /// await q.close();
  /// ```
  Future<List<FbFieldDef>?> fieldDefs() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.getFieldDefs,
      [],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty) {
      return null;
    } else {
      return r.data[0];
    }
  }

  /// Retrieves field names of the query output.
  ///
  /// This method is a simplified version of [fieldDefs].
  /// It retrieves just the column / field names of the query
  /// output data, omitting all other column properties.
  /// See also the documentation of [fieldDefs].
  ///
  /// Example:
  /// ```dart
  /// await q.openCursor(
  ///   sql: "select * from DEPARTMENT "
  ///        "where DEPT_NO = ?",
  ///   parameters: ["180"], // a single string parameter
  /// );
  /// // print all column names
  /// for (var name in await q.fieldNames()) {
  ///   print(name);
  /// }
  /// await q.close();
  /// ```
  Future<List<String>?> fieldNames() async {
    final fd = await fieldDefs();
    return fd?.map((e) => e.name).toList();
  }

  /// Retrieves the number of rows affected by a DML query.
  ///
  /// For any query modifying data in the database, this method
  /// can be used to get the actual number of rows affected by
  /// the recently executed query.
  ///
  /// Example:
  /// ```dart
  /// await q.execute(
  ///   sql: "update EMPLOYEE "
  ///        "set SALARY = SALARY * 1.5 "
  ///        "where EMP_NO between ? and ? ",
  ///   parameters: [5, 27],
  /// );
  /// final updated = await q.affectedRows();
  /// print("Updated $updated salaries.");
  /// await q.close();
  /// ```
  Future<int> affectedRows() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.affectedRows,
      [],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty) {
      return 0;
    } else {
      return r.data[0];
    }
  }

  /// Fetches the output data (as a map) of a query without a cursor.
  ///
  /// This method can be used to get output data passed in output
  /// parameters of a stored procedure or a block.
  /// Provided there is a procedure in the database, which has some
  /// output parameters, but has no SUSPEND statements in its body,
  /// you can run the procedure using the EXECUTE PROCEDURE statement.
  /// In that case, there is no result set (no database cursor)
  /// you can iterate over (with fetch or streams),
  /// the output data is passed from the procedure to the calling code
  /// directly in the output parameters (it's somewhat similar to a single
  /// data row except it's not really a row - that would require a cursor).
  /// To get those values back to the calling code, you need to call
  /// [getOutputAsMap] or [getOutputAsList].
  /// This variant returns the data as a map, with parameter names as
  /// its keys.
  Future<Map<String, dynamic>> getOutputAsMap() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.getOutput,
      [FbRowFormat.asMap],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return {};
    } else {
      return r.data[0];
    }
  }

  /// Fetches the output data (as a list) of a query without a cursor.
  ///
  /// This method can be used to get output data passed in output
  /// parameters of a stored procedure or a block.
  /// Provided there is a procedure in the database, which has some
  /// output parameters, but has no SUSPEND statements in its body,
  /// you can run the procedure using the EXECUTE PROCEDURE statement.
  /// In that case, there is no result set (no database cursor)
  /// you can iterate over (with fetch or streams),
  /// the output data is passed from the procedure to the calling code
  /// directly in the output parameters (it's somewhat similar to a single
  /// data row except it's not really a row - that would require a cursor).
  /// To get those values back to the calling code, you need to call
  /// [getOutputAsMap] or [getOutputAsList].
  /// This variant returns the data as a list, one item per each output
  /// parameter (there are no parameter names in the result of this method).
  Future<Map<String, dynamic>?> getOutputAsList() async {
    if (_toWorker == null) {
      throw FbClientException(
          "No active query associated with this query object");
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.getOutput,
      [FbRowFormat.asList],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return null;
    } else {
      return r.data[0];
    }
  }

  // --------------------------------------------------------------------
  // --------------------------- private API ----------------------------
  // --------------------------------------------------------------------

  /// A private port to send control messages to the FbDbQueryWorker
  /// associated with this particular open query (in the worker isolate).
  SendPort? _toWorker;

  /// The active connection, through which this query makes requests
  /// to the worker isolate.
  FbDb? _db;

  /// Detaches from the connection (makes this query unusable).
  void _detachConnection() {
    _toWorker = null;
    _db = null;
  }
}

// Pre-check the response from the worker isolate.
// If the response has invalid data type (i.e. not FbDbResponse),
// an exception is thrown. Similarly, if the response encapsulates
// a worker-side exception, it gets rethrown in the current isolate.
void _throwIfErrorResponse(dynamic response) {
  const vagueErrorMessage =
      "Error detected in the worker isolate. No details available.";
  if (response is List) {
    // A list is sent from the worker isolate when an uncaught exception
    // terminates the isolate. The list consists of two strings: the error
    // message and the stack trace.
    var message = vagueErrorMessage;
    if (response.isNotEmpty && response[0] is String) {
      if (response.length > 1 && response[1] is String) {
        message = "${response[0]}\nStack trace:\n${response[1]}";
      } else {
        message = response[0]; // just the message
      }
    }
    throw FbClientException(message);
  } else if (response is! FbDbResponse) {
    // the response is not a response object
    throw FbClientException(
      "Expected response object, got ${response.runtimeType} "
      "from the worker instead",
    );
  } else if (response.op == FbDbResponseOp.error) {
    // the response is a response object, but it contains
    // an encapsulated worker-side exception
    if (response.data.isNotEmpty) {
      throw response.data[0]; // the actual exception sent by the worker
    } else {
      throw FbClientException(vagueErrorMessage);
    }
  }
}
