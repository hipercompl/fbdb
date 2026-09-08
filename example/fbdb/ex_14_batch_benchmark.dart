// A basic batch benchmarking.
//
// Checks the speed of INSERT statements executed independently
// and in batches (of different sizes).
// The tests are performed for INSERTs with and without blobs.

import "dart:convert";
import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

// ----- CONFIGURATION (edit to match your environment) -----

/// Database host.
const dbHost = "localhost";

/// Database path / alias.
const dbPath = "/tmp/ex_14.fdb";

/// Create the database (true) or use an existing database (false).
/// If an existing database is to be used, it should already contain
/// tables T1_1, T1_2, T1_3, T2_1, T2_2 and T2_3 with proper structure
/// (see the end of this source file for the required table structures).
const doCreateDB = true;

/// Drop the database when the tests complete.
const doDropDB = true;

/// The Firebird user and password are imported from ex_auth.dart,
/// change it there if necessary.

// The number of inserts to T1 (inserts without blobs).
const _t1InsertCount = 50000;

// The number of inserts to T2 (inserts with blobs).
const _t2InsertCount = 20000;

// Different batch sizes to benchmark.
const _batchSizes = [10, 50, 100, 200];

// ----- END OF CONFIGURATION -----

Future<void> main() async {
  final db = await (doCreateDB ? _createDB() : _connect());

  print("Constructig test data");
  final t1data = _t1TestData(_t1InsertCount);
  final t2data = _t2TestData(_t2InsertCount);

  print("");
  print("--- Benchmarking $_t1InsertCount INSERTs without blobs ---");
  print("* individual inserts (unprepared)");
  final iuBench1 = await _benchmarkInsertsUnprepared(
    db,
    "insert into T1_1(PK, VC) values(?, ?)",
    t1data,
  );
  print("* individual inserts (prepared)");
  final ipBench1 = await _benchmarkInsertsPrepared(
    db,
    "insert into T1_2(PK, VC) values(?, ?)",
    t1data,
  );

  final bBench1 = List<(Duration, double)>.empty(growable: true);
  for (final batchSize in _batchSizes) {
    print("* batch inserts (batch size: $batchSize)");
    await db.execute(sql: "delete from T1_3");
    final b = await _benchmarkBatch(
      db,
      "insert into T1_3(PK, VC) values(?, ?)",
      t1data,
      batchSize,
    );
    bBench1.add(b);
  }

  print("");
  print("--- Benchmarking $_t2InsertCount INSERTs with blobs ---");
  print("* individual inserts (unprepared)");
  final iuBench2 = await _benchmarkInsertsUnprepared(
    db,
    "insert into T2_1(PK, B) values(?, ?)",
    t2data,
  );
  print("* individual inserts (prepared)");
  final ipBench2 = await _benchmarkInsertsPrepared(
    db,
    "insert into T2_2(PK, B) values(?, ?)",
    t2data,
  );

  final bBench2 = List<(Duration, double)>.empty(growable: true);
  for (final batchSize in _batchSizes) {
    print("* batch inserts (batch size: $batchSize)");
    await db.execute(sql: "delete from T2_3");
    final b = await _benchmarkBatch(
      db,
      "insert into T2_3(PK, B) values(?, ?)",
      t1data,
      batchSize,
    );
    bBench2.add(b);
  }

  print("");
  print("----- BENCHMARK RESULTS -----");
  _printBenchmark(
    "INSERT without blobs",
    _t1InsertCount,
    iuBench1,
    ipBench1,
    bBench1,
    iuBench1.$1,
  );
  _printBenchmark(
    "INSERT with blobs",
    _t2InsertCount,
    iuBench2,
    ipBench2,
    bBench2,
    iuBench2.$1,
  );

  if (doDropDB) {
    print("Dropping the test database");
    await db.dropDatabase();
  } else {
    print("Detaching from the test database");
    await db.detach();
  }
}

void _printBenchmark(
  String name,
  int count,
  (Duration, double) iu,
  ip,
  List<(Duration, double)> bs,
  Duration ref100,
) {
  print("* $name ($count rows):");
  print("  * unprepared queries:");
  print("    * total time: ${iu.$1}");
  print("    * average per 1 INSERT: ${iu.$2} ms");
  print(
    "    * relative to unprepared: ${((iu.$1.inMilliseconds / ref100.inMilliseconds) * 100.0).toStringAsFixed(2)}%",
  );
  print("  * prepared queries:");
  print("    * total time: ${ip.$1}");
  print("    * average per 1 INSERT: ${ip.$2} ms");
  print(
    "    * relative to unprepared: ${((ip.$1.inMilliseconds / ref100.inMilliseconds) * 100.0).toStringAsFixed(2)}%",
  );
  assert(bs.length == _batchSizes.length);
  for (var i = 0; i < bs.length; i++) {
    print("  * batches of size ${_batchSizes[i]}:");
    print("    * total time: ${bs[i].$1}");
    print("    * average per 1 INSERT: ${bs[i].$2} ms");
    print(
      "    * relative to unprepared: ${((bs[i].$1.inMilliseconds / ref100.inMilliseconds) * 100.0).toStringAsFixed(2)}%",
    );
  }
  print("");
}

/// Benchmarks individual inserts (unprepared). Returns the total duration
/// and the average time for an insert (in milliseconds).
Future<(Duration, double)> _benchmarkInsertsUnprepared(
  FbDb db,
  String sql,
  List<List<dynamic>> parameterSet,
) async {
  int insertCount = parameterSet.length;

  await db.startTransaction();

  final sw = Stopwatch()..start();
  for (var i = 0; i < insertCount; i++) {
    // each insert is prepared independently
    await db.execute(sql: sql, parameters: parameterSet[i]);
  }
  await db.commit();
  sw.stop();
  return (sw.elapsed, sw.elapsedMilliseconds / insertCount);
}

/// Benchmarks individual inserts (prepared). Returns the total duration and the
/// average time for an insert (in milliseconds).
Future<(Duration, double)> _benchmarkInsertsPrepared(
  FbDb db,
  String sql,
  List<List<dynamic>> parameterSet,
) async {
  int insertCount = parameterSet.length;

  await db.startTransaction();

  final sw = Stopwatch()..start();
  final query = db.query();
  // prepare once, then just execute with different data
  await query.prepare(sql: sql);
  for (var i = 0; i < insertCount; i++) {
    await query.executePrepared(parameters: parameterSet[i]);
  }
  await query.close();
  await db.commit();
  sw.stop();
  return (sw.elapsed, sw.elapsedMilliseconds / insertCount);
}

/// Benchmars inserts in batches. Returns the total duration and the
/// average time for an insert (in milliseconds).
Future<(Duration, double)> _benchmarkBatch(
  FbDb db,
  String sql,
  List<List<dynamic>> parameterSet,
  int batchSize,
) async {
  int insertCount = parameterSet.length;

  await db.startTransaction();

  final sw = Stopwatch()..start();
  final batch = await db.batch(sql: sql);
  var waitingStatements = false;
  for (var i = 0; i < insertCount; i++) {
    await batch.add(parameters: parameterSet[i]);
    waitingStatements = true;
    if (i > 0 && i % batchSize == 0) {
      await batch.execute();
      waitingStatements = false;
    }
  }
  if (waitingStatements) {
    // execute the last batch
    await batch.execute();
  }
  await batch.close();
  await db.commit();
  sw.stop();
  return (sw.elapsed, sw.elapsedMilliseconds / insertCount);
}

/// Prepare the test data for inserts into T1.
List<List<dynamic>> _t1TestData(int count) {
  List<List<dynamic>> res = [];
  for (var i = 1; i <= count; i++) {
    res.add([i, "Text data for record $i"]);
  }
  return res;
}

/// Prepare test data for inserts into T2.
List<List<dynamic>> _t2TestData(int count) {
  const blobSuffix =
      "This is an artificial combination of bytes "
      "to make the blobs slightly larger.";
  List<List<dynamic>> res = [];
  for (var i = 1; i <= count; i++) {
    res.add([i, utf8.encode("Blob data for record $i. $blobSuffix").buffer]);
  }
  return res;
}

Future<FbDb> _createDB() async {
  print("Creating the test database");
  final db = await FbDb.createDatabase(
    host: dbHost,
    database: dbPath,
    user: userName,
    password: userPassword,
    options: FbOptions(pageSize: 8192),
  );
  await db.execute(sql: _createT1_1);
  await db.execute(sql: _createT1_2);
  await db.execute(sql: _createT1_3);
  await db.execute(sql: _createT2_1);
  await db.execute(sql: _createT2_2);
  await db.execute(sql: _createT2_3);
  return db;
}

Future<FbDb> _connect() async {
  print("Attaching to the test database");
  final db = await FbDb.attach(
    host: dbHost,
    database: dbPath,
    user: userName,
    password: userPassword,
  );
  await db.execute(sql: "delete from T1_1");
  await db.execute(sql: "delete from T1_2");
  await db.execute(sql: "delete from T1_3");
  await db.execute(sql: "delete from T2_1");
  await db.execute(sql: "delete from T2_2");
  await db.execute(sql: "delete from T2_3");
  return db;
}

// DDL to create test tables.

const _createT1_1 = """
create table T1_1 (
  PK integer not null primary key,
  VC varchar(100)
)
""";

const _createT1_2 = """
create table T1_2 (
  PK integer not null primary key,
  VC varchar(100)
)
""";

const _createT1_3 = """
create table T1_3 (
  PK integer not null primary key,
  VC varchar(100)
)
""";

const _createT2_1 = """
create table T2_1 (
  PK integer not null primary key,
  B blob sub_type binary
)
""";

const _createT2_2 = """
create table T2_2 (
  PK integer not null primary key,
  B blob sub_type binary
)
""";

const _createT2_3 = """
create table T2_3 (
  PK integer not null primary key,
  B blob sub_type binary
)
""";
