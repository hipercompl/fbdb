// Demonstrates the ability to open multiple independent databse connections
// in the same application.
// Uses the employee demo database from the Firebird installation.
//
// Assumes the Firebird client libary is located in the current directory.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  // change the user / password to match your Firebird setup
  // in ex_auth.dart
  const user = userName;
  const password = userPassword;
  const host = "localhost";
  const database = "employee";

  // IDs of employees from the EMPLOYEE table
  // each employee will be selected in a different database attachment
  const empIds = [2, 4, 5, 8, 9, 11];

  final List<FbDb> dbs = [];
  final List<FbQuery> queries = [];
  try {
    // Prepare a separate connection for each employee id
    for (var i = 0; i < empIds.length; i++) {
      print("Opening attachment no. ${i + 1}");
      dbs.add(
        await FbDb.attach(
          host: host,
          database: database,
          user: user,
          password: password,
        ),
      );
      queries.add(dbs.last.query());
    }

    const querySql = """
      select EMP_NO, FIRST_NAME, LAST_NAME
      from EMPLOYEE
      where EMP_NO = ?
    """;
    final List<Future<void>> pendingQueries = [];

    // The order, in which employees are printed does not need to
    // correspond with the order of their IDs in empIds.
    // It depends which query will be handled faster by Firebird
    // and which data gets streamed sooner.
    // It all takes place in separate isolates (each DB connection
    // spawns its own isolate).
    for (var i = 0; i < empIds.length; i++) {
      print("Selecting employee with id ${empIds[i]}");
      // we keep track of pending queries to wait for all of them
      // to finish with Future.wait
      pendingQueries.add(
        queries[i].openCursor(sql: querySql, parameters: [empIds[i]]).then((
          q,
        ) async {
          await for (var r in q.rows()) {
            print(r);
          }
        }),
      );
    }
    // wait for all queries to finish processing
    await Future.wait(pendingQueries);
  } catch (e) {
    print("Error detected: $e");
  } finally {
    print("Closing queries");
    for (var q in queries) {
      await q.close();
    }
    queries.clear();
    print("Closing connections");
    for (var d in dbs) {
      await d.detach();
    }
    dbs.clear();
  }
}
