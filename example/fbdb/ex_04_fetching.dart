// Demonstrates different ways of fetching rows
// from query results.
// Uses the employee database from the default Firebird installation.

import "dart:io";
import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Attaching to localhost:employee");
    // change the user / password to match your Firebird setup
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.attach(
      database: "employee",
      host: "localhost",
      user: userName,
      password: userPassword,
    );
    print("Attached.");

    final q = db.query();

    print("Getting the first 5 employees");

    // Fetch the rows as a stream of tuples
    print("Fetching from a stream of maps");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    await for (var r in q.rows()) {
      print(r);
    }
    print("-" * 60);

    // Fetch the rows as a stream of lists
    print("Fetching from a stream of lists");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    await for (var r in q.rowValues()) {
      print(r);
    }
    print("-" * 60);

    // Fetch the rows one by one
    print("Fetching one by one as maps");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    for (;;) {
      final r = await q.fetchOneAsMap();
      if (r == null) {
        break;
      }
      print(r);
    }
    print("-" * 60);

    print("Fetching one by one as lists");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    for (;;) {
      final r = await q.fetchOneAsList();
      if (r == null) {
        break;
      }
      print(r);
    }
    print("-" * 60);

    // Fetch all rows at once
    print("Fetching all rows as maps in one go");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    final rowMaps = await q.fetchAllAsMaps();
    print("Got ${rowMaps.length} rows:");
    for (var r in rowMaps) {
      print(r);
    }
    print("-" * 60);

    print("Fetching all rows as lists in one go");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    final rowLists = await q.fetchAllAsLists();
    print("Got ${rowLists.length} rows:");
    for (var r in rowLists) {
      print(r);
    }
    print("-" * 60);

    // fetch in chunks
    print("Fetching as maps in chunks of 2");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    var chunk = 0;
    for (;;) {
      final r = await q.fetchAsMaps(2);
      if (r.isEmpty) {
        break;
      }
      chunk++;
      print("Chunk $chunk:");
      print(r);
    }
    print("-" * 60);

    print("Fetching as lists in chunks of 2");
    await q.openCursor(
      sql: "select first(5) EMP_NO, FIRST_NAME from EMPLOYEE order by EMP_NO",
    );
    chunk = 0;
    for (;;) {
      final r = await q.fetchAsLists(2);
      if (r.isEmpty) {
        break;
      }
      chunk++;
      print("Chunk $chunk:");
      print(r);
    }
    print("-" * 60);
  } catch (e) {
    print("Error detected: $e");
  } finally {
    // remember to detach from the database, otherwise the worker
    // isolate, being still active, may prevent your application
    // from exiting to the OS
    print("Detaching from the database");
    await db?.detach();
    print("Detached.");
    exit(0);
  }
}
