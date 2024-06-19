// Demonstrates how to obtain the number of rows affected by a DML query.
//
// NOTICE: change the user name and/or password to match your Firebird setup.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating ex_07.fdb");
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.createDatabase(
      database: "ex_07.fdb",
      user: userName,
      password: userPassword,
    );
    print("Created.");

    var q = db.query();

    print("Creating table TEST_TBL");
    q.execute(sql: "create table TEST_TBL (F integer)");
    print("Table created.");

    const rowCnt = 10;
    print("Inserting $rowCnt rows");

    for (var i = 1; i <= 10; i++) {
      await q.execute(
        sql: "insert into TEST_TBL (F) values (?)",
        parameters: [i],
      );
      // affectedRows should return 1 (one inserted row)
      final ar = await q.affectedRows();
      print("Inserted $ar row(s) with value $i");
    }

    print("Updating all rows");
    await q.execute(sql: "update TEST_TBL set F=F+20");
    final ar = await q.affectedRows();
    print("Number of rows affected by the update: $ar (should be 10)");

    await q.close();
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping the database");
      await db.dropDatabase();
      print("Dropped.");
    }
  }
}
