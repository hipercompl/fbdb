import "dart:io";
import "dart:async";
import "dart:isolate";
import "dart:convert";
import "dart:typed_data";

import "package:fbdb/fbdb.dart";
import "fbdbworker.dart";

/// Represents a database connection.
///
/// Every object of this cla/ to a Firebird database and is associated with a background
//  / worker isolate to /// on the database.
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
  static Future<FbDb> attach({
    String? host,
    int? port,
    required String database,
    String? user,
    String? password,
    String? role,
    FbOptions? options,
  }) async {
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
  static Future<FbDb> createDatabase({
    String? host,
    int? port,
    required String database,
    String? user,
    String? password,
    String? role,
    FbOptions? options,
  }) async {
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
  Future<void> startTransaction({
    Set<FbTrFlag>? flags,
    int? lockTimeout,
  }) async {
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
  ///
  /// If you provide an [FbTransaction] object, the commit operation
  /// will concern the provided transaction.
  /// However, it is probably more natural to call [FbTransaction.commit]
  /// instead of passing the transaction to [FbDb.commit].
  Future<void> commit({FbTransaction? transaction}) async {
    await _askWorker(FbDbControlOp.commit, [
      if (transaction != null) transaction.handle,
    ]);
    if (transaction != null) {
      transaction.handle = 0; // invalidate the transaction
    }
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
  ///
  /// If you provide an [FbTransaction] object, the rollback operation
  /// will concern the provided transaction.
  /// However, it is probably more natural to call [FbTransaction.rollback]
  /// instead of passing the transaction to [FbDb.rollback].
  Future<void> rollback({FbTransaction? transaction}) async {
    await _askWorker(FbDbControlOp.rollback, [
      if (transaction != null) transaction.handle,
    ]);
    if (transaction != null) {
      transaction.handle = 0; // invalidate the transaction
    }
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
  ///
  /// If you provide an [FbTransaction] object, the test
  /// will concern the provided transaction.
  /// However, it is probably more natural to call [FbTransaction.isActive]
  /// instead of passing the transaction to [FbDb.inTransaction].
  Future<bool> inTransaction({FbTransaction? transaction}) async {
    if (transaction != null && transaction.handle == 0) {
      // no need to communicate the worker
      // transaction handle 0 is invalid
      return false;
    }
    final r = await _askWorker(FbDbControlOp.inTransaction, [
      if (transaction != null) transaction.handle,
    ]);
    return (r.data.isNotEmpty && r.data[0] is bool && r.data[0]);
  }

  /// Start a new concurrent, explicit transaction.
  ///
  /// Use this method to create (and start) a new explicit transaction,
  /// which is distinct from the default connection-wise explicit
  /// transaction (which you start with [FbDb.startTransaction]).
  /// You get back an [FbTransaction] object, which can be passed
  /// to relevant methods (like [FbQuery.execute] or [FbQuery.open])
  /// to execute them in the context of the transaction.
  ///
  /// In most everyday database scenarios, you don't actually need to create
  /// multiple concurrent transactions. It's usually enough to use
  /// the database-wise explicit transaction, which simplifies the code,
  /// at the same time providing basic transaction support, sufficient
  /// for most use cases.
  ///
  /// Example:
  /// ```dart
  /// // db is an active connection
  /// final t1 = await db.newTransaction();
  /// final t2 = await db.newTransaction();
  /// print(await t1.isActive()); // true
  /// print(await t2.isActive()); // true
  /// final q = await db.query();
  /// await q.execute(
  ///   sql: "delete from TABLE1",
  ///   inTransaction: t1, // transaction parameter is optional
  /// );
  /// await q.execute(
  ///   sql: "delete from TABLE2",
  ///   inTransaction: t2, // transaction parameter is optional
  /// );
  /// await t1.rollback(); // cancel the deletion from TABLE1
  /// await t2.commit(); // commit the deletion from TABLE2
  /// print(await t1.isActive()); // false
  /// print(await t2.isActive()); // false
  /// await q.close();
  /// ```
  Future<FbTransaction> newTransaction({
    Set<FbTrFlag>? flags,
    int? lockTimeout,
  }) async {
    final r = await _askWorker(FbDbControlOp.newTransaction, [
      flags,
      lockTimeout,
    ]);
    if (r.data.isNotEmpty) {
      return FbTransaction(this, r.data[0]);
    } else {
      throw FbClientException(
        "FbDb.newTransaction did not return a transaction handle.",
      );
    }
  }

  /// Creates a new blob in the database.
  ///
  /// Allocates a new blob resource, ready to accept data segments.
  /// Returns the blob ID to be used in subsequent references to the blob.
  /// See also FbDb Programmer's Guide for more information on blob handling.
  ///
  /// Optionally, you can provide a transaction object, in which case
  /// the blob will be created in the context of this transaction.
  /// If you do so, remember to provide the same transaction object
  /// to other blob methods dealing with the newly created blob
  /// (e.g. [FbDb.putBlobSegment], [FbDb.closeBlob]).
  ///
  /// Example 1:
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
  ///
  /// Example 2:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// final t = await db.newTransaction(); // a new concurrent transaction
  /// final blobId = await db.createBlob(inTransaction: t);
  /// await db.putBlobFromStream(
  ///   id: blobId,
  ///   stream: File("data.bin")
  ///     .openRead()
  ///     .map((buf) => Uint8List.fromList(buf).buffer),
  ///   inTransaction: t,
  /// );
  /// final q = db.query();
  /// // suppose TEST_TABLE.BLOB_COL contains blobs
  /// await q.execute(
  ///   sql: "insert into TEST_TABLE(BLOB_COL) values (?)",
  ///   parameters: [blobId], // just the id, not the data
  ///   inTransaction: t,
  /// );
  /// await t.commit(); // commit the concurrent transaction
  /// await db.detach();
  /// ```
  Future<FbBlobId> createBlob({FbTransaction? inTransaction}) async {
    return (await _askWorker(FbDbControlOp.createBlob, [
      if (inTransaction != null) inTransaction.handle,
    ])).data[0];
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
    FbTransaction? inTransaction,
  }) async {
    if (segmentSize <= 0) {
      throw FbClientException("Invalid blob segment size: $segmentSize");
    }
    await _askWorker(FbDbControlOp.openBlob, [
      id,
      if (inTransaction != null) inTransaction.handle,
    ]);
    return () async* {
      for (;;) {
        final r = await _askWorker(FbDbControlOp.getBlobSegment, [
          id,
          segmentSize,
        ]);
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
  /// The method will keep sending data buffers from the [stream] until
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
  Future<void> blobFromFile({required FbBlobId id, required File file}) async {
    return putBlobFromStream(
      id: id,
      stream: file.openRead().map(
        (byteValues) => Uint8List.fromList(byteValues).buffer,
      ),
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
    FbTransaction? inTransaction,
  }) async {
    final q = query();

    try {
      await q.openCursor(
        sql: sql,
        parameters: parameters,
        inlineBlobs: inlineBlobs,
        inTransaction: inTransaction,
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
  Future<List<Map<String, dynamic>>> selectAll({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
    FbTransaction? inTransaction,
  }) async {
    final q = query();

    try {
      await q.openCursor(
        sql: sql,
        parameters: parameters,
        inlineBlobs: inlineBlobs,
        inTransaction: inTransaction,
      );
      return await q.fetchAllAsMaps();
    } finally {
      await q.close();
    }
  }

  /// Utility method - executes a query which doesn't return any data.
  ///
  /// Use this method instead of [FbDb.selectOne] or [FbDb.selectAll]
  /// when you intend to execute a SQL statement, which doesn't return
  /// any data, i.e. it doesn't allocate a database cursor.
  /// In particular, this method is suitable to run `UPDATE`, `INSERT`,
  /// `DELETE`, `CREATE`, `ALTER` and `DROP` statements.
  /// See also [FbQuery.execute].
  ///
  /// If needed, the method can return the number of rows affected by the query
  /// (see also [FbQuery.affectedRows]), pass `returnAffectedRows=true`
  /// in that case.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// await db.execute(
  ///   sql: "delete from T where ID=?",
  ///   parameters: [10]
  /// );
  /// await db.detach();
  /// ```
  Future<int> execute({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
    bool returnAffectedRows = false,
    FbTransaction? inTransaction,
  }) async {
    final q = query();

    try {
      await q.execute(
        sql: sql,
        parameters: parameters,
        inlineBlobs: inlineBlobs,
        inTransaction: inTransaction,
      );
      return returnAffectedRows ? await q.affectedRows() : 0;
    } finally {
      await q.close();
    }
  }

  /// Utility method - execute a sequence of statements in a transaction.
  ///
  /// This method allows you to execute a number of SQL statements,
  /// all within the scope of a single transaction.
  /// If all statements have been executed successfully, the transaction
  /// gets automatically committed.
  /// If any of the statements resulted in an exception, the execution
  /// of all subsequent statements is cancelled, the transaction is
  /// automatically rolled back and the exception is passed up to the caller
  /// (unless [rethrowException] is set intentionally to `false`, in which
  /// case the exception is consumed and `null` is returned by
  /// [runInTransaction]).
  /// The function passed as the parameter can return any data type,
  /// which gets passed up the stack to the caller as the result
  /// of [runInTransaction] if the execution is successful.
  /// This method uses the explicit transaction, starting it if not
  /// already pending (see [FbDb.startTransaction], [FbDb.commit] and
  /// [FbDb.rollback]).
  /// If a transaction has been already started, before the call
  /// to [runInTransaction], neither commit nor rollback take place,
  /// i.e. the transaction remains pending after the call completes.
  ///
  /// Example:
  /// ```dart
  /// final db = await FbDb.attach(host: "localhost", database: "employee");
  /// final cnt = await db.runInTransaction(() async {
  ///   final c = await db.selectOne(sql: "select count(*) as CNT from T");
  ///   await db.execute(sql: "delete from T");
  ///   return c["CNT"];
  /// });
  /// print("Deleted $cnt rows");
  /// ```
  Future<T?> runInTransaction<T>(
    Future<T?> Function() toRun, {
    bool rethrowException = true,
  }) async {
    var ownTransaction = false;
    try {
      if (!await inTransaction()) {
        await startTransaction();
        ownTransaction = true;
      }
      final result = await toRun();
      if (ownTransaction) {
        await commit();
      }
      return result;
    } catch (_) {
      try {
        if (ownTransaction) {
          await rollback();
        }
      } catch (_) {
        // intentionally empty
      }
      if (rethrowException) {
        rethrow;
      } else {
        return null;
      }
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
        [fromWorker.sendPort, libPath, mem is TracingAllocator],
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
  static Map<String, dynamic> _argsToMap({
    String? host,
    int? port,
    required String database,
    String? user,
    String? password,
    String? role,
    FbOptions? options,
  }) {
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
  Future<FbDbResponse> _askWorker(
    FbDbControlOp op,
    List<dynamic> args, [
    SendPort? toWorker,
  ]) async {
    toWorker ??= _toWorker;
    if (_worker == null || toWorker == null) {
      throw FbClientException(
        "No active worker isolate associated with the connection",
      );
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
///
/// In order to know, how to pass query parameters correctly and what to expect
/// when fetching query results, one has to know, how the SQL data types
/// in the Firebird database are mapped by FbDb to their corresponding types
/// in Dart.
///
/// The type mappings are as follows:
/// - SQL textual types (`CHAR` and `VARCHAR`) are mapped to `String` in Dart,
/// - SQL integer types (`SMALLINT`, `INTEGER`, `BIGINT`) are mapped
///   to `int` (64-bit integer) in Dart,
/// - SQL integer type `INT128` is mapped to `double` in Dart
///   (there's no 128-bit integer type available),
/// - SQL real numbers (`DOUBLE PRECISION`, `NUMERIC(N,M)`, `DECIMAL(N,M)`)
///   are mapped to `double` in Dart,
/// - SQL date and time types (`DATE`, `TIME`, `TIMESTAMP`) are mapped
///   to Dart `DateTime` objects,
/// - the same applies to SQL types `TIME WITH TIME ZONE`
///   and `TIMESTAMP WITH TIME ZONE` (they are both mapped to `DateTime`
///   in Dart), which is unfortunate, because currently Dart's `DateTime`
///   does not support arbitrary time zones (it only supports UTC and the
///   local time zone of the host); this issue will be addressed in the
///   future releases of fbdb,
/// - SQL `BOOLEAN` is mapped to `bool` in Dart,
/// - parameters of the SQL `BLOB` type can be passed to a query
///   as `ByteBuffer` objects, any `TypedData` objects (from which
///   a byte buffer can be obtained), as `String` objects (in which case
///   they will be encoded as UTF8 and passed byte-by-byte) or as `FbBlobId`
///   objects (for BLOBs stored beforehand); the returned values are always
///   either `ByteBuffer` objects or `FbBlobId` objects (depending
///   on whether BLOB inlining is turned on or off for a particular query).
class FbQuery {
  /// Creates a query object associated with the specific database connection.
  FbQuery.forDb(this._db);

  /// Closes the query (if active).
  ///
  /// Releases all internal data associated with the active query.
  /// If a query contains an explicitly prepared SQL statement
  /// (i.e. the [FbQuery.prepare] method was called on this query),
  /// the statement is invalidated and all its internal resources are
  /// released.
  /// If there is no active (executed but not closed) statement associated
  /// with this query object, nor a prepared one, the call has no effect
  /// (but will not throw).
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
    FbTransaction? inTransaction,
  }) async {
    if (_db == null) {
      throw FbClientException("No active database connection");
    }
    await close(); // close the previously associated worker, if any
    final msg = await _db?._askWorker(FbDbControlOp.queryExec, [
      sql,
      parameters,
      inlineBlobs,
      if (inTransaction != null) inTransaction.handle,
    ]);
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
    FbTransaction? inTransaction,
  }) async {
    if (_db == null) {
      throw FbClientException("No active database connection");
    }
    await close(); // close the previously associated worker, if any
    final msg = await _db?._askWorker(FbDbControlOp.queryOpen, [
      sql,
      parameters,
      inlineBlobs,
      if (inTransaction != null) inTransaction.handle,
    ]);
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

  /// An alias for [FbQuery.openCursor].
  ///
  /// This method serves only as a shorthand alias of [openCursor],
  /// because many other database access libraries customarily use
  /// `open` to execute a query returning a data set.
  /// For a detailed description of the parameters, please refer to
  /// the [FbQuery.openCursor] manual.
  Future<FbQuery> open({
    required String sql,
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
    FbTransaction? inTransaction,
  }) async {
    return openCursor(
      sql: sql,
      parameters: parameters,
      inlineBlobs: inlineBlobs,
      inTransaction: inTransaction,
    );
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

  /// An alias for [FbQuery.fetchAsMaps].
  ///
  /// Since fetching rows as maps is the most frequently used
  /// variant, this alias was introduced, to make client
  /// code shorter.
  Future<List<Map<String, dynamic>>> fetch([int rowCount = 1]) async {
    return fetchAsMaps(rowCount);
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
  /// // allRows is a list of maps (possibly empty)
  /// print(allRows[0]["DEPT_NO"]);
  /// await q.close();
  /// // allRows retains the data after the query gets closed
  /// ```
  Future<List<Map<String, dynamic>>> fetchAllAsMaps() async {
    return rows().toList();
  }

  /// An alias for [FbQuery.fetchAllAsMaps].
  ///
  /// Since fetching rows as maps is the most frequently used
  /// variant, this alias was introduced, to make client
  /// code shorter.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    return fetchAllAsMaps();
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
  /// // allRows is a list (possibly empty) of lists
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
  /// print(row?["DEPT_NO"]); // row is nullable, hence the ? operator
  /// await q.close();
  /// // row retains the data after the query gets closed
  /// ```
  Future<Map<String, dynamic>?> fetchOneAsMap() async {
    if (_toWorker == null) {
      throw FbClientException(
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.fetchNext, [
      FbRowFormat.asMap,
    ], _toWorker);
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return null;
    } else {
      return r.data[0];
    }
  }

  /// An alias for [FbQuery.fetchOneAsMap].
  ///
  /// Since fetching rows as maps is the most frequently used
  /// variant, this alias was introduced, to make client
  /// code shorter.
  Future<Map<String, dynamic>?> fetchOne() async {
    return fetchOneAsMap();
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
  /// // row is a list of values only (nullable)
  /// print(row?[0]); // print the first column
  /// await q.close();
  /// // row retains the data after the query gets closed
  /// ```
  Future<List<dynamic>?> fetchOneAsList() async {
    if (_toWorker == null) {
      throw FbClientException(
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.fetchNext, [
      FbRowFormat.asList,
    ], _toWorker);
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
        "No active query associated with this query object",
      );
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
        "No active query associated with this query object",
      );
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
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.getOutput, [
      FbRowFormat.asMap,
    ], _toWorker);
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return {};
    } else {
      return r.data[0];
    }
  }

  /// An alias to [FbQuery.getOutputAsMap] to shorten the calls.
  ///
  /// Getting output as maps is the most frequently used variant,
  /// so to make the client code shorter, this alias was introduced.
  Future<Map<String, dynamic>> getOutput() async {
    return getOutputAsMap();
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
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.getOutput, [
      FbRowFormat.asList,
    ], _toWorker);
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty || r.data[0] == null) {
      return null;
    } else {
      return r.data[0];
    }
  }

  /// Prepares a statement to be executed later.
  ///
  /// When an SQL statement is expected to get executed multiple times,
  /// possibly with different data passed as query parameters,
  /// it is more efficient to prepare the statement once, and then
  /// execute it multiple times, without the need to prepare it before
  /// each execution.
  /// A query containing a prepared statement exposes
  /// the [FbQuery.executePrepared] and [FbQuery.openPrepared] methods
  /// to actually execute the prepared statement.
  /// The method returns the reference to the target [FbQuery] object,
  /// to allow for easy chaining.
  /// If a non-null [FbTransaction] object is provided as [inTransaction],
  /// the query will be prepared in the context of the transaction.
  /// Otherwise, it will be prepared in the context of a connection-wise
  /// explicit transaction (if one has been started), or an internal
  /// transaction will be spawned and committed immediately after
  /// preparation of the statement.
  /// Throws exceptions when any errors are encountered.
  ///
  /// Example:
  /// ```dart
  /// // db is an active attachment
  /// var q = db.query();
  /// await q.prepare(sql: "insert into T(FLD_INT, FLD_STR) values (?, ?)");
  /// await q.executePrepared(parameters: [1, "ABC"]);
  /// // note: no extra q.prepare() here, we still
  /// // use the same INSERT statement prepared earlier
  /// await q.executePrepared(parameters: [2, "DEF"]);
  /// await q.close();
  /// ```
  Future<FbQuery> prepare({
    required String sql,
    FbTransaction? inTransaction,
  }) async {
    if (_db == null) {
      throw FbClientException("No active database connection");
    }
    await close(); // close the previously associated worker, if any
    final msg = await _db?._askWorker(FbDbControlOp.prepareQuery, [
      sql,
      if (inTransaction != null) inTransaction.handle,
    ]);
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

  /// Executes a prepared query without allocating a database cursor.
  ///
  /// This method is an equivalent of [FbQuery.execute], but for a previously
  /// prepared statement (see also [FbQuery.prepare]).
  /// You can pass values of query parameters (if the query requires any)
  /// via the [parameters] list.
  /// The [inlineBlobs] parameter decides whether blob values should
  /// be returned as data buffers (`true`) or as blob IDs, to be fetched
  /// later via blob routines of [FbDb].
  /// The method returns the reference to the target [FbQuery] object,
  /// to allow for easy chaining.
  /// If a non-null [FbTransaction] object is provided as [inTransaction],
  /// the query will be executed in the context of the transaction.
  /// Otherwise, it will be executed in the context of a connection-wise
  /// explicit transaction (if one has been started), or an internal
  /// transaction will be spawned and committed immediately after
  /// execution of the query.
  /// Throws exceptions when any errors are encountered.
  /// Please see also the documentation of the [FbQuery.execute] method.
  ///
  /// Example:
  /// ```dart
  /// // db is an active attachment
  /// var q = db.query();
  /// await q.prepare(sql: "insert into T(FLD_INT, FLD_STR) values (?, ?)");
  /// await q.executePrepared(parameters: [1, "ABC"]);
  /// // note: no extra q.prepare() here, we still
  /// // use the same INSERT statement prepared earlier
  /// await q.executePrepared(parameters: [2, "DEF"]);
  /// await q.close();
  /// ```
  Future<FbQuery> executePrepared({
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
    FbTransaction? inTransaction,
  }) async {
    if (_toWorker == null) {
      throw FbClientException(
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.execQueryPrepared, [
      parameters,
      inlineBlobs,
      if (inTransaction != null) inTransaction.handle,
    ], _toWorker);
    _throwIfErrorResponse(msg);
    return this;
  }

  /// Executes a prepared query, allocating a database cursor to fetch records.
  ///
  /// This method is an equivalent of [FbQuery.openCursor], but for a previously
  /// prepared statement (see also [FbQuery.prepare]).
  /// You can pass values of query parameters (if the query requires any)
  /// via the [parameters] list.
  /// The [inlineBlobs] parameter decides whether blob values should
  /// be returned as data buffers (`true`) or as blob IDs, to be fetched
  /// later via blob routines of [FbDb].
  /// The method returns the reference to the target [FbQuery] object,
  /// to allow for easy chaining.
  /// If a non-null [FbTransaction] object is provided as [inTransaction],
  /// the query will be executed in the context of the transaction.
  /// Otherwise, it will be executed in the context of a connection-wise
  /// explicit transaction (if one has been started), or an internal
  /// transaction will be spawned and committed immediately after
  /// the result set of the query is depleted (or the query is closed
  /// before that).
  /// Throws exceptions when any errors are encountered.
  /// Please see also the documentation of the [FbQuery.openCursor] method.
  ///
  /// Example:
  /// ```dart
  /// // db is an active attachment
  /// var q = db.query();
  /// await q.prepare(sql: "select FLD_STR from T where FLD_INT=?");
  /// await q.openPrepared(parameters: [1]);
  /// final r1 = await q.fetchOneAsMap();
  /// // process r1["FLD_STR"]
  /// // note: no extra q.prepare() here, we still
  /// // use the same SELECT statement prepared earlier
  /// await q.openPrepared(parameters: [2]);
  /// final r2 = await q.fetchOneAsMap();
  /// // process r2["FLD_STR"]
  /// await q.close();
  /// ```
  Future<FbQuery> openPrepared({
    List<dynamic> parameters = const [],
    bool inlineBlobs = true,
    FbTransaction? inTransaction,
  }) async {
    if (_toWorker == null) {
      throw FbClientException(
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(FbDbControlOp.openQueryPrepared, [
      parameters,
      inlineBlobs,
      if (inTransaction != null) inTransaction.handle,
    ], _toWorker);
    _throwIfErrorResponse(msg);
    return this;
  }

  /// Informs whether the query contains a prepared SQL statement.
  ///
  /// Yoy can use this method to check whether a particular query
  /// object currently contains an explicitly prepared SQL statement
  /// (if the [FbQuery.prepare] method was called for this query).
  Future<bool> isPrepared() async {
    if (_toWorker == null) {
      throw FbClientException(
        "No active query associated with this query object",
      );
    }
    final msg = await _db?._askWorker(
      FbDbControlOp.isQueryPrepared,
      [],
      _toWorker,
    );
    _throwIfErrorResponse(msg);
    final r = msg as FbDbResponse;
    if (r.data.isEmpty) {
      return false;
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

class FbTransaction {
  FbDb db; // the attachment this DB is related to
  int handle; // key in worker isolate's ITransaction map

  FbTransaction(this.db, this.handle);

  Future<void> commit() async {
    await db.commit(transaction: this);
  }

  Future<void> rollback() async {
    await db.rollback(transaction: this);
  }

  Future<bool> isActive() async {
    return handle != 0 && await db.inTransaction(transaction: this);
  }
}
