// Demonstrates a simple SELECT scenario.
// Attaches to the employee database, selects the list of employees
// (a constrained one, with the constraint value passed as a query
// parameter), and iterates over the result set, displaying the employee
// data. Additionally, fetches and displays the data column
// definitions of the data set.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";
import "ex_util.dart";

void main() async {
  FbDb? db;
  try {
    print("Attaching to localhost:employee");
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.attach(
      database: "inet://localhost:3050/employee",
      user: userName,
      password: userPassword,
    );
    print("Attached.");

    print("Getting the list of employees (for EMP_NO < 30)");

    // creates a FbQuery object
    final q = db.query();

    // executes the statement, opens a cursor and gets ready
    // to fetch rows of data
    await q.openCursor(
      sql:
          "select EMP_NO, FIRST_NAME, LAST_NAME, PHONE_EXT, HIRE_DATE, SALARY "
          "from EMPLOYEE "
          "where EMP_NO < ?",
      parameters: [30],
    );
    print("Query executed");
    print("-" * 60);
    print("Fetching field definitions");
    print("-" * 60);
    // get a collection of FbFieldDef objects
    final defs = (await q.fieldDefs()) ?? [];
    for (var d in defs) {
      print(d);
    }

    print("-" * 60);
    print("Fetching rows");
    print("-" * 60);

    // FbQuery.rows returns a stream of rows, each being a map of the form
    // column name => column value
    await for (var r in q.rows()) {
      print(mapToString(r));
      print("-" * 60);
    }
  } catch (e) {
    print("Error detected: $e");
  } finally {
    // remember to detach from the database, otherwise the worker
    // isolate, being still active, may prevent your application
    // from exiting to the OS
    print("Detaching from the database");
    await db?.detach();
    print("Detached.");
  }
}
