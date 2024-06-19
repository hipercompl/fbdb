// This demo shows how to detect, differentiate and handle
// fbdb errors.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  // change the user / password to match your Firebird setup
  // in ex_auth.dart
  const user = userName;
  const passwordValid = userPassword;

  // this password is intentionally invalid
  const passwordInvalid = "yekretsam";

  const host = "localhost";
  const port = 3050;
  const database = "employee";

  // use this employee ID to cause key violation
  // (must point to an existing record in EMPLOYEE)
  const empId = 2;

  FbDb? db;
  FbQuery? q;

  try {
    // login error
    try {
      print("Logging in with an invalid password");
      db = await FbDb.attach(
        host: host,
        port: port,
        database: database,
        user: user,
        password: passwordInvalid,
      );
    } on FbServerException catch (e) {
      print("----- THIS ERROR WAS EXPECTED -----");
      print("$e");
      print("Error vector: ${e.errors}");
    } catch (e) {
      print("Unexpected error of type ${e.runtimeType}: $e");
    }

    try {
      print("Logging in with a valid password");
      db = await FbDb.attach(
        host: host,
        port: port,
        database: database,
        user: user,
        password: passwordValid,
      );
      print("Attached");
    } on FbServerException catch (e) {
      print("$e");
      print("Error vector: ${e.errors}");
      return;
    } catch (e) {
      print("Unexpected error of type ${e.runtimeType}: $e");
      return;
    }

    q = db.query();

    // query error - invalid SQL
    try {
      print("Executing a syntatically invalid SQL statement");
      await q.execute(sql: "UPDATE OR MAYBE SELECT? DON'T DELETE!");
    } on FbServerException catch (e) {
      print("----- THIS ERROR WAS EXPECTED -----");
      print("$e");
      print("Error vector: ${e.errors}");
    } catch (e) {
      print("Unexpected error of type ${e.runtimeType}: $e");
      return;
    }

    // query error - validation error (null value in a not null column)
    try {
      print("Causing a validation error");
      await q.execute(
        sql: "insert into EMPLOYEE(EMP_NO) values (?)",
        parameters: [empId],
      );
    } on FbServerException catch (e) {
      print("----- THIS ERROR WAS EXPECTED -----");
      print("$e");
      print("Error vector: ${e.errors}");
    } catch (e) {
      print("Unexpected error of type ${e.runtimeType}: $e");
      return;
    }

    // query error - fetch data without result set
    try {
      print("Fetching data without a result set");
      await q.fetchOneAsMap();
    } on FbServerException catch (e) {
      print("$e");
      print("Error vector: ${e.errors}");
    } catch (e) {
      print("----- THIS ERROR WAS EXPECTED -----");
      print("${e.runtimeType}: $e");
    }

    // query error - invalid parameters

    // database error - invalid blob handle
  } finally {
    await q?.close();
    q = null;
    await db?.detach();
    db = null;
  }
}
