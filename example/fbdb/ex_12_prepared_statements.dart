// Shows how to use prepared statements to speed up repetitive queries.

// Generates artificial data to be stored in the database, and then
// inserts the data into two identical tables, with and without
// prepared statements. Compares the total time required to store
// the data and displays the benchmark.

// Timing obtained on a test machine for 30000 records:
// Data storing time without prepared queries: 17.491 s
// Data storing time with prepared queries:    9.431 s
// Speedup: 46 %

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  // generate the data
  print("Generating data ...");
  final recordCount = 30000; // the number of records to store
  final data = [
    // each record is an ID, followed by a short description
    for (var i = 1; i <= recordCount; i++) [i, "Description $i"]
  ];
  print("Done. ${data.length} records generated.");

  FbDb? db;
  try {
    print("Creating database /tmp/ex_12.fdb ...");
    // you may need to change the location of the database
    // and/or authentication data
    db = await FbDb.createDatabase(
      database: "/tmp/ex_12.fdb",
      user: userName,
      password: userPassword,
    );
    print("Database created.");

    print("Creating tables ...");
    await db.execute(sql: "create table T1(I INTEGER, D varchar(50))");
    await db.execute(sql: "create table T2(I INTEGER, D varchar(50))");
    print("Tables created.");

    print("Inserting data without prepared queries ...");
    final upt1 = DateTime.now();
    for (final [i, d] in data) {
      // the query is prepared and executed in a single step,
      // and then immediately closed
      await db.execute(
        sql: "insert into T1 (I, D) values (?, ?)",
        parameters: [i, d],
      );
    }

    final upt2 = DateTime.now();
    final udiff = upt2.difference(upt1).inMilliseconds;
    print("Done.");

    print("Inserting data with prepared queries ...");
    final pt1 = DateTime.now();
    final q = db.query();
    // prepare the query once
    await q.prepare(sql: "insert into T2 (I, D) values (?, ?)");
    for (final [i, d] in data) {
      // execute the query multiple times, with different data
      await q.executePrepared(parameters: [i, d]);
    }
    await q.close();
    final pt2 = DateTime.now();
    final pdiff = pt2.difference(pt1).inMilliseconds;
    print("Done.");

    final uSec = udiff / 1000.0;
    final pSec = pdiff / 1000.0;
    final ratioPerc = ((uSec - pSec) * 100.0 / uSec).round();
    print("Data storing time without prepared queries: $uSec s");
    print("Data storing time with prepared queries:    $pSec s");
    print("Speedup: $ratioPerc %");
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping database ex_12.fdb ...");
      await db.dropDatabase();
      print("Done.");
    }
  }
}
