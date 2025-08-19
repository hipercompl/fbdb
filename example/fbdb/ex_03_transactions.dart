// Demonstrates transaction handling in FbDb.
// Uses both explicit and implicit transactions.
// Creates a new database to issue statements and finally
// drops the database.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating ex_03.fdb");
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.createDatabase(
      database: "ex_03.fdb",
      user: userName,
      password: userPassword,
      options: FbOptions(
        pageSize: 8192, // non-default page size, 8k instead of default 4k
      ),
    );
    print("Created.");

    // the single query object q will be used for all kinds of queries
    // throughout the whole example
    final q = db.query();

    print("Creating table TEST_TBL");
    await q.execute(
      sql:
          "create table TEST_TBL( "
          "   ID integer not null primary key, "
          "   TXT varchar(100) "
          ") ",
    );
    print("Table created.");

    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    var r = await q.fetchOneAsMap();
    if (r != null) {
      print("Current row count: ${r['CNT']} (should be 0)");
    }

    print("Starting transaction");
    // starts an explicit transaction - all queries executed from this
    // point share the same transaction context, until commit or rollback
    await db.startTransaction();

    // 5 inserts in a single transaction
    print("Inserting 5 rows into TEST_TBL");
    for (var (id, txt) in [
      (1, "ABC"),
      (2, "DEF"),
      (3, "GHI"),
      (4, "JKL"),
      (5, "MNO"),
    ]) {
      await q.execute(
        sql:
            "insert into TEST_TBL(ID, TXT) "
            "values (?, ?)",
        parameters: [id, txt],
      );
    }

    // select in the same transaction as inserts above
    print(
      "Checking row count in TEST_TBL (in the same transaction as INSERTs)",
    );
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      // should show 5 rows
      print("Current row count: ${r['CNT']} (should be 5)");
    }

    print("Rolling back the transaction");
    // cancel all 5 inserts
    await db.rollback();

    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      // should show 0 rows, as all the inserts have been rolled back
      print("Current row count: ${r['CNT']} (should be 0)");
    }

    print("Starting transaction");
    // starting another explicit transaction
    await db.startTransaction();

    print("Inserting 2 rows into TEST_TBL");
    for (var (id, txt) in [(1, "ABC"), (2, "DEF")]) {
      await q.execute(
        sql:
            "insert into TEST_TBL(ID, TXT) "
            "values (?, ?)",
        parameters: [id, txt],
      );
    }

    print(
      "Checking row count in TEST_TBL (in the same transaction as INSERTs)",
    );
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      // should show 2 rows
      print("Current row count: ${r['CNT']} (should be 2)");
    }

    print("Committing the transaction");
    // now the inserts are confirmed and officially visible
    await db.commit();

    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      // should still show 2 rows
      print("Current row count: ${r['CNT']} (should be 2)");
    }

    print("Inserting 1 row in an implicit transaction");
    // now we perform one more insert, but without starting a transaction
    // explicitly - the insert will be executed inside its own transaction
    // and committed immediately afterwards
    await q.execute(
      sql:
          "insert into TEST_TBL(ID, TXT) "
          "values (?, ?)",
      parameters: [3, "GHI"],
    );
    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      // should show 3 rows
      print("Current row count: ${r['CNT']} (should be 3)");
    }

    // The last demo.
    // We start an explicit transaction, perform a select,
    // then end (commit) the transaction and try to fetch a row.
    print("Starting an explicit transaction");
    await db.startTransaction();
    print("Selecting rows from TEST_TBL");
    await q.openCursor(sql: "select * from TEST_TBL");
    print("Committing the transaction");
    await db.commit();
    // committing an explicit transaction invalidates all result sets
    // which were created within the scope of the transaction
    // trying to fetch data from such a result set causes an exception
    print("Trying to fetch a row from the earlier SELECT query");
    print("You should see 'Invalid resultset interface' error below");
    try {
      final rr = await q.fetchOneAsMap();
      print("Fetched row: $rr");
    } catch (e) {
      print("Cannot fetch a row: $e");
    }
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping the database");
      try {
        await db.dropDatabase();
        print("Dropped.");
      } catch (e) {
        print("Couldn't drop database: $e");
      }
    }
  }
}
