@TestOn("vm")
library;

import 'package:test/test.dart';
import 'package:fbdb/fbdb.dart';
import 'test_config.dart';
import "test_utils.dart";

void main() async {
  group("Built-in transactions", () {
    test("Transaction committed", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await db.startTransaction();
        await q.openCursor(sql: "select count(*) as CNT from T");
        var r = await q.fetchOneAsMap();
        expect(r, isNotNull);
        if (r == null) {
          return;
        }
        expect(r["CNT"], equals(3));

        await q.execute(sql: "insert into T(PK_INT) values (4)");
        final ar = await q.affectedRows();
        expect(ar, equals(1));

        await db.commit();
        await q.openCursor(sql: "select count(*) as CNT from T");
        r = await q.fetchOneAsMap();
        expect(r, isNotNull);
        if (r == null) {
          return;
        }
        expect(r["CNT"], equals(4));
      }); // withNewDb1
    }); // test "Transaction committed"

    test("Transaction rolled back", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await db.startTransaction();
        await q.openCursor(sql: "select count(*) as CNT from T");
        var r = await q.fetchOneAsMap();
        expect(r, isNotNull);
        if (r == null) {
          return;
        }
        expect(r["CNT"], equals(3));

        await q.execute(sql: "insert into T(PK_INT) values (4)");
        final ar = await q.affectedRows();
        expect(ar, equals(1));

        await db.rollback();
        await q.openCursor(sql: "select count(*) as CNT from T");
        r = await q.fetchOneAsMap();
        expect(r, isNotNull);
        if (r == null) {
          return;
        }
        expect(r["CNT"], equals(3));
      }); // withNewDb1
    }); // test "Transaction rolled back"

    test("Lock conflict", () async {
      await withNewDb1((db) async {
        final db2 = await FbDb.attach(
          database: lastTestDbLoc,
          user: TestConfig.dbUser,
          password: TestConfig.dbPassword,
          options: FbOptions(transactionFlags: fbTrWriteNoWait),
        );
        try {
          final q1 = db.query();
          final q2 = db2.query();
          await db.startTransaction();
          await q1.execute(sql: "update T set C_5='tst1' where PK_INT=1");
          final ar = await q1.affectedRows();
          expect(ar, equals(1));

          await db2.startTransaction();
          await expectLater((() async {
            await q2.execute(sql: "update T set C_5='tst2' where PK_INT=1");
          })(), throwsException);

          await db.commit();
          await db2.commit();
          await q1.close();
          await q2.close();
        } finally {
          await db2.detach();
        }
      }); // withNewDb1
    }); // test "Lock conflict"

    test("FbDb.runInTransaction utility method - committed", () async {
      await withNewDb1((db) async {
        final initialCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(await db.inTransaction(), isFalse);
        final cnt1 = await db.runInTransaction(() async {
          expect(await db.inTransaction(), isTrue);
          final cnt = (await db.selectOne(
              sql: "select count(*) as CNT from T"))?["CNT"];
          await db.execute(sql: "delete from T");
          return cnt;
        });
        expect(cnt1, equals(initialCnt));
        expect(await db.inTransaction(), isFalse);
        final cnt2 =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(cnt2, equals(0));
      }); // withNewDb1
    });

    test("FbDb.runInTransaction utility method - rolled back", () async {
      await withNewDb1((db) async {
        final initialCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(await db.inTransaction(), isFalse);
        try {
          await db.runInTransaction(() async {
            await db.execute(sql: "delete from T");
            await db.execute(
              sql: "insert into T (PK_INT) values (?)",
              parameters: [1],
            );
            await db.execute(
              sql: "insert into T (PK_INT) values (?)",
              parameters: [1],
            ); // key violation
            expect(true, false); // this code should not be reachable
          });
        } catch (_) {}
        expect(await db.inTransaction(), isFalse);
        final cnt2 =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(cnt2, equals(initialCnt)); // DELETE should have been rolled back
      }); // withNewDb1
    });

    test("FbDb.runInTransaction utility method - pending transaction",
        () async {
      await withNewDb1((db) async {
        expect(await db.inTransaction(), isFalse);
        await db.startTransaction();
        final initialCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(await db.inTransaction(), isTrue);
        final cnt1 = await db.runInTransaction(() async {
          return await db.execute(
            sql: "delete from T",
            returnAffectedRows: true,
          );
        });
        expect(cnt1, equals(initialCnt));
        expect(await db.inTransaction(), isTrue);
        final cnt2 =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(cnt2, equals(0));
        await db.rollback();
        expect(await db.inTransaction(), isFalse);
        final finalCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(finalCnt, equals(initialCnt));
      }); // withNewDb1
    }); // test "FbDb.runInTransaction utility method - pending transaction"

    test("FbDb.runInTransaction utility method - pending transaction and error",
        () async {
      await withNewDb1((db) async {
        expect(await db.inTransaction(), isFalse);
        final initialCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        await db.startTransaction();
        final cnt1 = await db.runInTransaction(
          () async {
            await db.execute(
              sql: "insert into T (PK_INT) values (?)",
              parameters: [-1],
            );
            return await db.execute(
              sql: "insert into T (PK_INT) values (?)",
              parameters: [1],
              returnAffectedRows: true,
            ); // key violation
          },
          rethrowException: false,
        );
        expect(await db.inTransaction(), isTrue);
        expect(cnt1, isNull);
        final cnt2 =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(cnt2, equals(initialCnt + 1)); // 1 row inserted before error
        await db.rollback();
        expect(await db.inTransaction(), isFalse);
        final finalCnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
        expect(finalCnt, equals(initialCnt));
      }); // withNewDb1
    }); // test "FbDb.runInTransaction utility method - pending transaction and error"
  }); // group "Built-in transactions"

  group("Multiple concurrent transactions", () {
    test("Selects in independent transaction", () async {
      await withNewDb1((db) async {
        final q = db.query();
        final t = await db.newTransaction();
        expect(await t.isActive(), isTrue);
        final rows1 = await db.selectAll(
          sql: "select * from T where PK_INT between ? and ?",
          parameters: [1, 3],
          inTransaction: t,
        );
        await q.open(
          sql: "select * from T where PK_INT between ? and ?",
          parameters: [1, 3],
          inTransaction: t,
        );
        final rows2 = await q.fetchAllAsMaps();
        await q.close();
        await t.commit();
        expect(await t.isActive(), isFalse);
        expect(rows1, isNotNull);
        expect(rows2, isNotNull);
        if (rows1 != null) {
          expect(rows1.length, equals(3));
          expect(rows2.length, equals(rows1.length));
          for (var i = 0; i < rows1.length; i++) {
            expect(rows1[i]['PK_INT'], equals(i + 1));
            expect(rows2[i]['PK_INT'], equals(i + 1));
          }
        }
      }); // withNewDb1
    }); // test "Independent transaction committed"

    test("Independent transaction committed", () async {
      await withNewDb1((db) async {
        final rows1 = await db.selectAll(sql: "select PK_INT from T");
        final t = await db.newTransaction();
        final q = db.query();
        await q.execute(
          sql: "delete from T",
          inTransaction: t,
        );
        await q.close();
        final rows2 = await db.selectAll(
          sql: "select PK_INT from T",
          inTransaction: t,
        );
        await t.commit();
        final rows3 = await db.selectAll(sql: "select PK_INT from T");

        expect(
          rows1.isEmpty,
          isFalse,
          reason: 'before DELETE, T should not be empty',
        );
        expect(
          rows2.isEmpty,
          isTrue,
          reason: 'after DELETE, T should be empty in the same transaction',
        );
        expect(
          rows3.isEmpty,
          isTrue,
          reason: 'after COMMIT, T should be empty in all transactions',
        );
      }); // withNewDb1
    }); // test "Independent transaction committed"

    test("Independent transaction committed, shortcut methods", () async {
      await withNewDb1((db) async {
        final rows1 = await db.selectAll(sql: "select PK_INT from T");
        final t = await db.newTransaction();
        await db.execute(
          sql: "delete from T",
          inTransaction: t,
        );
        final rows2 = await db.selectAll(
          sql: "select PK_INT from T",
          inTransaction: t,
        );
        await t.commit();
        final rows3 = await db.selectAll(sql: "select PK_INT from T");

        expect(
          rows1.isEmpty,
          isFalse,
          reason: 'before DELETE, T should not be empty',
        );
        expect(
          rows2.isEmpty,
          isTrue,
          reason: 'after DELETE, T should be empty in the same transaction',
        );
        expect(
          rows3.isEmpty,
          isTrue,
          reason: 'after COMMIT, T should be empty in all transactions',
        );
      }); // withNewDb1
    }); // test "Independent transaction committed, shortcut methods"

    test("Independent transaction rolled back", () async {
      await withNewDb1((db) async {
        final rows1 = await db.selectAll(sql: "select PK_INT from T");
        final t = await db.newTransaction();
        final q = db.query();
        await q.execute(
          sql: "delete from T",
          inTransaction: t,
        );
        await q.close();
        final rows2 = await db.selectAll(
          sql: "select PK_INT from T",
          inTransaction: t,
        );
        await t.rollback();
        final rows3 = await db.selectAll(sql: "select PK_INT from T");

        expect(
          rows1.isEmpty,
          isFalse,
          reason: 'before DELETE, T should be not empty',
        );
        expect(
          rows2.isEmpty,
          isTrue,
          reason: 'after DELETE, T should be empty in the same transaction',
        );
        expect(
          rows3.isEmpty,
          isFalse,
          reason: 'after ROLLBACK, T should return to being non empty',
        );
      }); // withNewDb1
    }); // test "Independent transaction rolled back"

    test("Independent transaction rolled back, shortcut methods", () async {
      await withNewDb1((db) async {
        final rows1 = await db.selectAll(sql: "select PK_INT from T");
        final t = await db.newTransaction();
        await db.execute(
          sql: "delete from T",
          inTransaction: t,
        );
        final rows2 = await db.selectAll(
          sql: "select PK_INT from T",
          inTransaction: t,
        );
        await t.rollback();
        final rows3 = await db.selectAll(sql: "select PK_INT from T");

        expect(
          rows1.isEmpty,
          isFalse,
          reason: 'before DELETE, T should be not empty',
        );
        expect(
          rows2.isEmpty,
          isTrue,
          reason: 'after DELETE, T should be empty in the same transaction',
        );
        expect(
          rows3.isEmpty,
          isFalse,
          reason: 'after ROLLBACK, T should return to being non empty',
        );
      }); // withNewDb1
    }); // test "Independent transaction rolled back, shortcut methods"

    test("Independent transaction with errors", () async {
      await withNewDb1((db) async {
        //TODO
      }); // withNewDb1
    }); // test "Independent transaction with errors"

    test("Concurrent transactions - basic isolation", () async {
      await withNewDb1((db) async {
        //TODO
      }); // withNewDb1
    }); // test "Concurrent transactions - basic isolation"

    test("Concurrent transactions - isolation flags", () async {
      await withNewDb1((db) async {
        //TODO
      }); // withNewDb1
    }); // test "Concurrent transactions - isolation flags"

    test(
      "Concurrent transactions - lock conflict",
      () async {
        await withNewDb1((db) async {
          //TODO
        }); // withNewDb1
      },
      // longer test timeout to make sure the deadlock occurs
      timeout: Timeout(Duration(seconds: 5)),
    ); // test "Concurrent transactions - lock conflict"
  }); // group "Multiple concurrent transactions"
}
