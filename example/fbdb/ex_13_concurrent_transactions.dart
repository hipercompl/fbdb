// Shows how to handle multiple concurrent transactions
// in a single database connection.

// This example is a simplified mutex scenario.
// Imagine a multi-access application, containing a crititcal functionality,
// which can be executed only by a single user at any given moment.
//
// We will use a DB-based mutex to make sure no other user can
// execute the critical functionality.
// The critical function itself will consist of updating two distinct
// records in two separate transactions (independent of the transaction
// required for the mutex functionality).
// The mutex-locking transaction will be kept open the whole time,
// causing deadlocks for all other connections (users), which would
// try to execute the critical function before the current user
// completes his one.
//
// In a real-world scenario the critical function would of course
// be much more complicated than just simple updates, and would
// itself require separate transaction (or multiple ones).
// The most important part of the example is observing that the
// mutexTransaction is active (pending) the whole time, despite
// the updating transactions being started and committed.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating database /tmp/ex_13.fdb ...");
    // you may need to change the location of the database
    // and/or authentication data
    db = await FbDb.createDatabase(
      database: "/tmp/ex_13.fdb",
      user: userName,
      password: userPassword,
    );
    print("Database created.");
    print("Setting up tables ...");
    await setUpDatabase(db);
    print("done.");

    print("Acquiring mutex lock ...");
    // our mutex transaction will have a 3-second timeout
    // i.e. if the mutex cannot be acquired withing 3 seconds,
    // an exception will be thrown by the database server
    final mutexTransaction = await db.newTransaction(
      flags: fbTrWriteWait,
      lockTimeout: 3,
    );
    try {
      await db.execute(
        sql: "update LOCKS set VAL=VAL+1 where MUTEX=?",
        parameters: ["criticalFunction"],
      );
    } on FbServerException catch (e) {
      if (e.message.contains("deadlock")) {
        // a deadlock occured in the mutex transaction
        // which means other transaction updated the mutex
        // and is still in progress
        print(
          "Another user is currently using this critical function. "
          "Please try again later.",
        );
        return;
      } else {
        rethrow;
      }
    }
    print("Lock ackquired. Executing the critical system function.");

    print("Critical function step 1 - in a separate transaction.");
    final t1 = await db.newTransaction();
    await db.execute(
      sql: "update CRITICAL_DATA set VAL=? where ID=?",
      parameters: ["changed value 1", 1],
      inTransaction: t1, // execute in context of this independent transaction!
    );
    await t1.commit(); // does *not* commit the mutexTransaction
    print("Step 1 completed");

    print("Critical function step 2 - in a separate transaction.");
    final t2 = await db.newTransaction();
    await db.execute(
      sql: "update CRITICAL_DATA set VAL=? where ID=?",
      parameters: ["changed value 2", 2],
      inTransaction: t2, // execute in context of this independent transaction!
    );
    await t2.commit(); // does *not* commit the mutexTransaction
    print("Step 2 completed");

    print("Critical function completed. Releasing the lock.");
    // We can end the mutexTransaction either way.
    // Rolling it back brings the lock record back to its original state.
    // Committing it effectively makes the VAL column in LOCKS
    // count the number of times a particular lock was acquired.
    await mutexTransaction.rollback();

    // Just to make sure, let's see what's in the CRITICAL_DATA now.
    print("CRITICAL_DATA contents:");
    final rows = await db.selectAll(
      sql: "select * from CRITICAL_DATA order by ID",
    );
    for (final r in rows) {
      // should print changed values,
      // because t1 and t2 have been committed,
      // rolling back mutexTransaction should have no effect
      // on queries executed in contexts of t1 and t2
      print(r);
    }
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping database /tmp/ex_13.fdb ...");
      await db.dropDatabase();
      print("Done.");
    }
  }
}

Future<void> setUpDatabase(FbDb db) async {
  await db.execute(
    sql: "create table LOCKS ( "
        "MUTEX varchar(20) not null primary key, "
        "VAL integer default 0 "
        ")",
  );
  await db.execute(
    sql: "insert into LOCKS (MUTEX) "
        "values (?) ",
    parameters: ["criticalFunction"],
  );
  await db.execute(
    sql: "create table CRITICAL_DATA ( "
        "ID integer not null primary key, "
        "VAL varchar(30) default '' "
        ")",
  );
  final q = db.query();
  await q.prepare(
    sql: "insert into CRITICAL_DATA (ID, VAL) "
        "values (?, ?)",
  );
  await q.executePrepared(parameters: [1, "value 1"]);
  await q.executePrepared(parameters: [2, "value 2"]);
  await q.close();
}
