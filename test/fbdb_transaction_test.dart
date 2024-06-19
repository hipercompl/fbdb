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
}
