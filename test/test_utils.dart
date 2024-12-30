import "dart:isolate";
import "dart:typed_data";

import "package:fbdb/fbdb.dart";
import "test_config.dart";

int _dbCounter = 1;
String lastTestDbLoc = "";

/// Execute an external function with a temporarily created,
/// empty database.
Future<void> withNewEmptyDb(Future<void> Function(FbDb) testFunc,
    {FbOptions? options}) async {
  lastTestDbLoc = getTmpDbLoc();
  final db = await FbDb.createDatabase(
    database: lastTestDbLoc,
    user: TestConfig.dbUser,
    password: TestConfig.dbPassword,
    options: options ?? FbOptions(),
  );
  try {
    await testFunc(db);
  } finally {
    await db.dropDatabase();
  }
}

/// Execute an external function with a temporarily created
/// database, containing a single table with three rows of data
/// of different types.
Future<void> withNewDb1(Future<void> Function(FbDb) testFunc,
    {FbOptions? options}) async {
  await withNewEmptyDb(
    (db) async {
      final q = db.query();
      try {
        await q.execute(
          sql: "create table T ( "
              "PK_INT integer not null primary key, "
              "C_1 char(1), "
              "C_5 char(5), "
              "VC_50 varchar(50), "
              "DP double precision, "
              "DEC_10_3 decimal(10, 3), "
              "D date, "
              "TS timestamp, "
              "B blob "
              ") ",
        );
        await q.execute(
          sql:
              "insert into T (PK_INT, C_1, C_5, VC_50, DP, DEC_10_3, D, TS, B) "
              "values (?, ?, ?, ?, ?, ?, ?, ?, ?) ",
          parameters: [
            1,
            "y",
            "row_1",
            "This is the first row",
            1.1,
            111.111,
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 1, 1, 10, 11),
            Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).buffer
          ],
        );
        await q.execute(
          sql:
              "insert into T (PK_INT, C_1, C_5, VC_50, DP, DEC_10_3, D, TS, B) "
              "values (?, ?, ?, ?, ?, ?, ?, ?, ?) ",
          parameters: [
            2,
            "y",
            "row_2",
            "This is the second row",
            2.2,
            222.222,
            DateTime(2024, 2, 2),
            DateTime(2024, 2, 2, 2, 20, 22),
            Uint8List.fromList([2, 3, 4, 5, 6, 7, 8, 9, 10, 11]).buffer
          ],
        );
        await q.execute(
          sql:
              "insert into T (PK_INT, C_1, C_5, VC_50, DP, DEC_10_3, D, TS, B) "
              "values (?, ?, ?, ?, ?, ?, ?, ?, ?) ",
          parameters: [
            3,
            "n",
            "row_3",
            "This is the third row",
            3.3,
            333.333,
            DateTime(2024, 3, 3),
            DateTime(2024, 3, 3, 3, 30, 33),
            Uint8List.fromList([3, 4, 5, 6, 7, 8, 9, 10, 11, 12]).buffer
          ],
        );
      } finally {
        await q.close();
      }
      await testFunc(db);
    },
    options: options,
  ); // withNewEmptyDb
}

/// Execute an external function with a temporarily created
/// database, containing a single table with colums designed
/// to test issue #4 (https://github.com/hipercompl/fbdb/issues/4),
/// that is truncation of varchar query parameters.
Future<void> withNewDb2(Future<void> Function(FbDb) testFunc,
    {FbOptions? options}) async {
  await withNewEmptyDb(
    (db) async {
      final q = db.query();
      try {
        await q.execute(
          sql: "create table T ( "
              "PK_INT integer not null primary key, "
              "VC32 varchar(32) "
              ") ",
        );
      } finally {
        await q.close();
      }
      await testFunc(db);
    },
    options: options,
  ); // withNewEmptyDb
}

/// Calculate and return a new, unique temporary database location.
String getTmpDbLoc() {
  final iid = Isolate.current.hashCode;
  final dbLoc = "${TestConfig.tmpDbDir}testdb_${iid}_$_dbCounter.fdb";
  _dbCounter++;
  return dbLoc;
}
