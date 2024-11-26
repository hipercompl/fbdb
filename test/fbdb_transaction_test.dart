@TestOn("vm")
library;

import 'package:test/test.dart';
import 'package:fbdb/fbdb.dart';
import 'test_config.dart';
import "test_utils.dart";

void main() async {
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
        final cnt =
            (await db.selectOne(sql: "select count(*) as CNT from T"))?["CNT"];
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

  test("FbDb.runInTransaction utility method - pending transaction", () async {
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
}
