@TestOn("vm")
library;

import 'package:test/test.dart';
import 'package:fbdb/fbdb.dart';
import "test_config.dart";
import 'test_utils.dart';

/// Tests connecting and disconnecting to/from databases
/// and creating / dropping databases.
void main() async {
  group("Attaching tests", () {
    test("Attaching to employee and detaching", () async {
      FbDb? db;

      final dbFut = FbDb.attach(
        database: TestConfig.employeeDB,
        user: TestConfig.dbUser,
        password: TestConfig.dbPassword,
      );
      await expectLater(dbFut, completes);
      db = await dbFut;

      final detFut = db.detach();
      await expectLater(detFut, completes);

      await expectLater(
        (() async {
          await db?.ping();
        })(),
        throwsException,
      );
    });

    test("Attaching with an error", () {
      expect(() async {
        await FbDb.attach(
          database: TestConfig.employeeDB,
          user: "bad_user",
          password: "!!!bad_password",
        );
      }, throwsException);
    });

    test("Attaching with non-ASCII database path", () async {
      try {
        await FbDb.attach(
          host: "localhost",
          database: "Неудаетсянайтиуказанныйфайл.fdb",
          user: TestConfig.dbUser,
          password: TestConfig.dbPassword,
        );
      } on FbServerException catch (e) {
        final invMsg = !e.messageValid && e.message.contains("\u{FFFD}");
        final valMsg = e.messageValid && !e.message.contains("\u{FFFD}");
        // either valid or invalid, never both or neither
        expect(invMsg ^ valMsg, isTrue);
      } on Exception {
        Skip("Other kind of exception detected");
      }
    });
  });

  group("Creating databases", () {
    test("Creating and dropping database", () async {
      FbDb? db;
      final dbFut = FbDb.createDatabase(
        database: getTmpDbLoc(),
        user: TestConfig.dbUser,
        password: TestConfig.dbPassword,
      );
      await expectLater(dbFut, completes);
      db = await dbFut;

      final dropFut = db.dropDatabase();
      await expectLater(dropFut, completes);

      await expectLater(
        (() async {
          return db?.ping();
        })(),
        throwsException,
      );
    });

    test("Creating database with an error", () {
      expect(() async {
        await FbDb.createDatabase(database: "");
      }, throwsException);
    });

    test("Creating database with collation", () async {
      FbDb? db;
      final dbFut = FbDb.createDatabase(
        database: getTmpDbLoc(),
        user: TestConfig.dbUser,
        password: TestConfig.dbPassword,
        options: FbOptions(dbCharset: "UTF8", dbCollation: "UNICODE_CI_AI"),
      );
      await expectLater(dbFut, completes);
      db = await dbFut;

      final qFut = db.selectOne(
        sql:
            "select RDB\$DEFAULT_COLLATE_NAME "
            "from RDB\$CHARACTER_SETS "
            "where RDB\$CHARACTER_SET_NAME=? ",
        parameters: ["UTF8"],
      );
      await expectLater(dbFut, completes);

      final rec = await qFut;
      expect(rec, isNotNull);

      if (rec != null) {
        expect(
          rec["RDB\$DEFAULT_COLLATE_NAME"].toString().trim(),
          equals("UNICODE_CI_AI"),
        );
      }

      final dropFut = db.dropDatabase();
      await expectLater(dropFut, completes);
    });

    test("Creating database without collation", () async {
      FbDb? db;
      final dbFut = FbDb.createDatabase(
        database: getTmpDbLoc(),
        user: TestConfig.dbUser,
        password: TestConfig.dbPassword,
        options: FbOptions(dbCharset: "UTF8"),
      );
      await expectLater(dbFut, completes);
      db = await dbFut;

      final qFut = db.selectOne(
        sql:
            "select RDB\$DEFAULT_COLLATE_NAME "
            "from RDB\$CHARACTER_SETS "
            "where RDB\$CHARACTER_SET_NAME=? ",
        parameters: ["UTF8"],
      );
      await expectLater(dbFut, completes);

      final rec = await qFut;
      expect(rec, isNotNull);

      if (rec != null) {
        expect(
          rec["RDB\$DEFAULT_COLLATE_NAME"].toString().trim(),
          equals("UTF8"),
        );
      }

      final dropFut = db.dropDatabase();
      await expectLater(dropFut, completes);
    });
  });

  group("Multiple connections", () {
    test("Two simultaneous connections", () async {
      await expectLater(
        (() async {
          final db1 = await FbDb.attach(
            database: TestConfig.employeeDB,
            user: TestConfig.dbUser,
            password: TestConfig.dbPassword,
          );
          final db2 = await FbDb.attach(
            database: TestConfig.employeeDB,
            user: TestConfig.dbUser,
            password: TestConfig.dbPassword,
          );
          final r1 = await db1.selectAll(
            sql: "select 1 as VAL from RDB\$DATABASE",
          );
          final r2 = await db1.selectAll(
            sql: "select 1 as VAL from RDB\$DATABASE",
          );
          expect(r1.length, equals(1));
          expect(r2.length, equals(1));
          await db1.detach();
          await db2.detach();
        })(),
        completes,
      );
    });

    test("Opening, closing, and opening again", () async {
      await expectLater(
        (() async {
          final db1 = await FbDb.attach(
            database: TestConfig.employeeDB,
            user: TestConfig.dbUser,
            password: TestConfig.dbPassword,
          );
          final r1 = await db1.selectAll(
            sql: "select 1 as VAL from RDB\$DATABASE",
          );
          expect(r1.length, equals(1));
          await db1.detach();
          final db2 = await FbDb.attach(
            database: TestConfig.employeeDB,
            user: TestConfig.dbUser,
            password: TestConfig.dbPassword,
          );
          final r2 = await db2.selectAll(
            sql: "select 1 as VAL from RDB\$DATABASE",
          );
          expect(r2.length, equals(1));
          await db2.detach();
        })(),
        completes,
      );
    });

    test("Multiple simultaneous connections", () async {
      await expectLater(
        (() async {
          // the number of connections to open
          const conCount = 20;
          List<FbDb> dbs = [];
          for (var i = 0; i < conCount; i++) {
            final db = await FbDb.attach(
              database: TestConfig.employeeDB,
              user: TestConfig.dbUser,
              password: TestConfig.dbPassword,
            );
            dbs.add(db);
          }
          // 1. all connections should be working at this moment
          for (var db in dbs) {
            await expectLater(
              (() async {
                final r = await db.selectAll(
                  sql: "select 1 as VAL from RDB\$DATABASE",
                );
                expect(r.length, equals(1));
              })(),
              completes,
            );
          }
          // 2. closing connections one by one
          for (var closed = 0; closed < conCount; closed++) {
            await dbs[closed].detach();

            // all closed connections shouldn't work
            for (var i = 0; i <= closed; i++) {
              await expectLater(
                (() async {
                  await dbs[i].selectAll(
                    sql: "select 1 as VAL from RDB\$DATABASE",
                  );
                })(),
                throwsA(isA<FbClientException>()),
              );
            }

            // all remaining open connections should work
            for (var i = closed + 1; i < conCount; i++) {
              await expectLater(
                (() async {
                  final r = await dbs[i].selectAll(
                    sql: "select 1 as VAL from RDB\$DATABASE",
                  );
                  expect(r.length, equals(1));
                })(),
                completes,
              );
            }
          }
        })(),
        completes,
      );
    });
  });
}
