// Demonstrates creating and dropping databases, together with
// some DDL (data definition language) statements.
// Creates a new database, defines a table inside it,
// inserts a row into that table and checks the row count.
// Finally drops the database.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating ex_02.fdb");
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.createDatabase(
      database: "ex_02.fdb",
      user: userName,
      password: userPassword,
      options: FbOptions(
        // non-default page size, 8k instead of default 4k
        pageSize: 8192,
        // non-default ANSI character encoding (default is UTF-8)
        dbCharset: "WIN1252",
      ),
    );
    print("Created.");

    print("Creating table TEST_TBL");
    final q = db.query();
    await q.execute(
      sql: "create table TEST_TBL( "
          "   ID integer not null primary key, "
          "   TXT varchar(100) "
          ") ",
    );
    print("Table created.");

    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    var r = await q.fetchOneAsMap();
    if (r != null) {
      print("Current row count: ${r['CNT']}");
    }

    print("Inserting a row into TEST_TBL");
    await q.execute(
      sql: "insert into TEST_TBL(ID, TXT) "
          "values (?, ?)",
      parameters: [1, "Abc"],
    );

    print("Checking row count in TEST_TBL");
    await q.openCursor(sql: "select count(*) as CNT from TEST_TBL");
    r = await q.fetchOneAsMap();
    if (r != null) {
      print("Current row count: ${r['CNT']}");
    }
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
