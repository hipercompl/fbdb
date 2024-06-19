// This demo allows to measure memory consumption
// in a particular environment.
// It opens 1000 connections (sequentially, one by one).
// In each connection, it executes 100 SELECT queries,
// fetches results of every SELECT as a stream of maps,
// and finally closes the connection.
//
// Uses the TracingAllocator from the mem module to keep track
// of native memory usage.
// Prints current native memory allocation every 10 iterations
// plus detailed statistics at the end.
// Demonstrates, that TracingAllocator gathers memory stats
// also from the worker isolate (they are transmitted back
// to the main isolate on detach or dropDatabase).
//
// For example, on Windows 11 the process starts with about 4.5 MB
// of memory allocated, then the allocation increases to about 8 MB
// at the beginning of the loop (probably due to the loading of
// libfbclient.dll for the first time), then increases very slowly
// to about 13 MB during the 1000 subsequent database connections.
//
// Please take a close look at the peak allocation - it should stay
// within the range of single kilobytes (in fact a little more
// than 1 kB). That means, at no point there is more native (C heap)
// memory allocated than a few kilobytes.
// All other memory used by the process is Dart memory managed by
// the garbage collector.

import "dart:io";
import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

// Set the user name and password matching your Firebird setup.
const user = userName;
const password = userPassword;

void main() async {
  const connectionCount = 1000;
  const queryCount = 100;

  // Set the library-wide allocator to the tracing allocator.
  mem = TracingAllocator();

  print("Check OS process info and press Enter to start the loop");
  stdin.readLineSync();

  for (var i = 1; i <= connectionCount; i++) {
    FbDb? db;
    FbQuery? q;
    try {
      db = await FbDb.attach(
        host: "localhost",
        database: "employee",
        user: user,
        password: password,
      );
      q = db.query();
      for (var j = 1; j <= queryCount; j++) {
        await q.openCursor(sql: "select * from EMPLOYEE");
        await for (var _ in q.rows()) {}
      }

      if (i % 10 == 0) {
        final a = (mem as TracingAllocator).allocatedSum;
        final f = (mem as TracingAllocator).freedSum;
        final l = a - f;
        print(
          "$i iterations completed, allocated $a B, freed $f B, leaked $l B",
        );
      }
    } finally {
      await q?.close();
      q = null;
      await db?.detach();
      db = null;
    }
  }

  print("");
  print("");
  print(mem);
  print("");
  print("Check OS process info and press Enter to quit");
  stdin.readLineSync();
}
