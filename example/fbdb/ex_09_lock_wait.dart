// Demonstrates different transaction modes.
// Updates a row in one transaction and tries to update the same row
// in another transaction.
// Does it both in wait and no-wait mode to demonstrate the difference.
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

  // use this employee ID (must point to an existing record in EMPLOYEE)
  const empId = 2;

  FbDb? db1;
  FbDb? db2;
  FbQuery? q1;
  FbQuery? q2;

  try {
    print("Opening connection 1");
    db1 = await FbDb.attach(
      database: database,
      host: host,
      user: user,
      password: password,
      options: FbOptions(
        transactionFlags: {FbTrFlag.concurrency, FbTrFlag.write, FbTrFlag.wait},
        lockTimeout: 3,
      ),
    );
    print("Opening connection 2");
    db2 = await FbDb.attach(
      database: database,
      host: host,
      user: user,
      password: password,
      options: FbOptions(
        // explicit transaction flags
        // could have used fbTrWriteWait constant instead
        transactionFlags: {FbTrFlag.concurrency, FbTrFlag.write, FbTrFlag.wait},
        lockTimeout: 3,
      ),
    );
    q1 = db1.query();
    q2 = db2.query();

    print("Case 1: wait transactions with 3 seconds lock timeout");

    print("Starting transactions");
    // the transactions are started with default flags, set during
    // attaching to the database
    await db1.startTransaction();
    await db2.startTransaction();

    // this countdown works because all db calls are asynchronous!
    for (var s = 1; s <= 3; s++) {
      Future.delayed(Duration(seconds: s), () {
        print("$s second${s > 1 ? 's' : ''} passed");
      });
    }
    await _makeConflictingUpdates(
      q1,
      q2,
      empId,
      "An exception should be thrown after 3 seconds",
    );

    print("Rolling back transactions");
    await db1.rollback();
    await db2.rollback();

    print("Case 2: no wait transactions");
    print("Starting transactions");

    // fbTrWriteNoWait is a constant set of flags:
    // {concurrency, write, noWait}.
    await db1.startTransaction(flags: fbTrWriteNoWait);
    await db2.startTransaction(flags: fbTrWriteNoWait);

    await _makeConflictingUpdates(
      q1,
      q2,
      empId,
      "An exception should be thrown immediately",
    );

    print("Rolling back transactions");
    await db1.rollback();
    await db2.rollback();
  } catch (e) {
    print("Error detected: $e");
  } finally {
    print("Closing queries");
    await q1?.close();
    await q2?.close();
    print("Closing connections");
    await db1?.detach();
    db1 = null;
    await db2?.detach();
    db2 = null;
  }
}

Future<void> _makeConflictingUpdates(
  FbQuery q1,
  FbQuery q2,
  int empId,
  String msg,
) async {
  print("Update via connection 1");
  await q1.execute(
    sql: "update EMPLOYEE set FIRST_NAME=? where EMP_NO=?",
    parameters: ["John", empId],
  );

  print("Conflicting update via connection 2");
  print(msg);
  try {
    await q2.execute(
      sql: "update EMPLOYEE set FIRST_NAME=? where EMP_NO=?",
      parameters: ["Jack", empId],
    );
  } on FbServerException catch (e) {
    if (e.hasError(FbErrorCodes.isc_deadlock)) {
      print("DEADLOCK DETECTED !!!");
      print(e);
    } else {
      print("Exception caught: $e");
    }
  }
}
