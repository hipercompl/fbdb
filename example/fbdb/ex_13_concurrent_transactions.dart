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
  //TODO
}

void createDbStructure(FbDb db) async {
  //TODO
}
