@TestOn("vm")
library;

import 'package:test/test.dart';
import "test_utils.dart";

void main() async {
  group("Prepared DML queries", () {
    test("Prepared INSERT", () async {
      await withNewDb1((db) async {
        final q = db.query();
        final cnt1 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt1, isNotNull);
        if (cnt1 != null) {
          expect(cnt1["CNT"], equals(3));
        }
        await q.prepare(sql: "insert into T(PK_INT, VC_50) values(?, ?)");
        await q.executePrepared(parameters: [10, "Row with PK 10"]);
        await q.executePrepared(parameters: [11, "Row with PK 11"]);
        final cnt2 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt2, isNotNull);
        if (cnt2 != null) {
          expect(cnt2["CNT"], equals(5));
        }
        final r11 = await db.selectOne(
          sql: "select VC_50 from T where PK_INT=?",
          parameters: [11],
        );
        expect(r11, isNotNull);
        if (r11 != null) {
          expect(r11["VC_50"], equals("Row with PK 11"));
        }
        await q.close();
      }); // withNewDb1
    }); // test "Prepared INSERT"

    test("Prepared UPDATE", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.prepare(sql: "update T set VC_50=? where PK_INT=?");
        await q.executePrepared(parameters: ["UPDATED 1", 1]);
        await q.executePrepared(parameters: ["UPDATED 2", 2]);

        final r1 = await db.selectOne(
          sql: "select VC_50 from T where PK_INT=1",
        );
        expect(r1, isNotNull);
        if (r1 != null) {
          expect(r1["VC_50"], equals("UPDATED 1"));
        }

        final r2 = await db.selectOne(
          sql: "select VC_50 from T where PK_INT=2",
        );
        expect(r2, isNotNull);
        if (r2 != null) {
          expect(r2["VC_50"], equals("UPDATED 2"));
        }

        await q.close();
      }); // withNewDb1
    }); // test "Prepared UPDATE"

    test("Prepared DELETE", () async {
      await withNewDb1((db) async {
        final cnt1 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt1, isNotNull);
        if (cnt1 != null) {
          expect(cnt1["CNT"], equals(3));
        }
        final q = db.query();
        await q.prepare(sql: "delete from T where PK_INT=?");
        await q.executePrepared(parameters: [1]);
        await q.executePrepared(parameters: [2]);
        final cnt2 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt2, isNotNull);
        if (cnt2 != null) {
          expect(cnt2["CNT"], equals(1));
        }
        await q.close();
      }); // withNewDb1
    }); // test "Prepared DELETE"

    test("Prepared INSERT in committed transaction", () async {
      await withNewDb1((db) async {
        final q = db.query();
        final cnt1 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt1, isNotNull);
        if (cnt1 != null) {
          expect(cnt1["CNT"], equals(3));
        }
        await db.startTransaction();
        await q.prepare(sql: "insert into T(PK_INT, VC_50) values(?, ?)");
        await q.executePrepared(parameters: [10, "Row with PK 10"]);
        await q.executePrepared(parameters: [11, "Row with PK 11"]);
        await db.commit();
        final cnt2 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt2, isNotNull);
        if (cnt2 != null) {
          expect(cnt2["CNT"], equals(5));
        }
        final r11 = await db.selectOne(
          sql: "select VC_50 from T where PK_INT=?",
          parameters: [11],
        );
        expect(r11, isNotNull);
        if (r11 != null) {
          expect(r11["VC_50"], equals("Row with PK 11"));
        }
        await q.close();
      }); // withNewDb1
    }); // test "Prepared INSERT in committed transaction"

    test("Prepared INSERT in rolled back transaction", () async {
      await withNewDb1((db) async {
        final q = db.query();
        final cnt1 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt1, isNotNull);
        if (cnt1 != null) {
          expect(cnt1["CNT"], equals(3));
        }
        await q.prepare(sql: "insert into T(PK_INT, VC_50) values(?, ?)");
        await db.startTransaction();
        await q.executePrepared(parameters: [10, "Row with PK 10"]);
        await q.executePrepared(parameters: [11, "Row with PK 11"]);
        await db.rollback();
        final cnt2 = await db.selectOne(sql: "select count(*) as CNT from T");
        expect(cnt2, isNotNull);
        if (cnt2 != null) {
          expect(cnt2["CNT"], equals(3));
        }
        await q.close();
      }); // withNewDb1
    }); // test "Prepared INSERT in rolled back transaction"
  }); // group "Prepared DML queries"

  group("Prepared DQL queries", () {
    test("Prepared SELECT", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.prepare(sql: "select PK_INT from T where PK_INT=?");

        await q.openPrepared(parameters: [1]);
        final r1 = await q.fetchOneAsMap();
        expect(r1, isNotNull);
        await q.openPrepared(parameters: [2]);
        final r2 = await q.fetchOneAsMap();
        expect(r2, isNotNull);
        await q.openPrepared(parameters: [3]);
        final r3 = await q.fetchOneAsMap();
        expect(r3, isNotNull);

        if (r1 != null) {
          expect(r1["PK_INT"], equals(1));
        }
        if (r2 != null) {
          expect(r2["PK_INT"], equals(2));
        }
        if (r3 != null) {
          expect(r3["PK_INT"], equals(3));
        }

        await q.openPrepared(parameters: [-1]); // non-exixtent key
        final rn1 = await q.fetchOneAsMap();
        expect(rn1, isNull);

        await q.close();
      }); // withNewDb1
    }); // test "Prepared SELECT"
  }); // group "Prepared DQL queries"

  group("Prepared queries with errors", () {
    test("SQL syntax error", () async {
      await expectLater(() async {
        await withNewDb1((db) async {
          final q = db.query();
          await q.prepare(
            sql: "insert intoo T(PK_INT) values (?)", // syntax error: "intoo"
          );
        }); // withNewDb1
      }, throwsException);
    }); // test "SQL syntax error"

    test("Prepared key violation", () async {
      await expectLater(() async {
        await withNewDb1((db) async {
          final q = db.query();
          await q.prepare(sql: "insert into T(PK_INT) values (?)");
          await q.executePrepared(parameters: [1]); // key violation
        }); // withNewDb1
      }, throwsException);
    }); // test "Prepared key violation"

    test("Executing unprepared query", () async {
      await expectLater(() async {
        await withNewDb1((db) async {
          final q = db.query();
          await q.executePrepared(parameters: []);
        }); // withNewDb1
      }, throwsException);
      await expectLater(() async {
        await withNewDb1((db) async {
          final q = db.query();
          await q.openPrepared(parameters: []);
        }); // withNewDb1
      }, throwsException);
    }); // test "Executing unprepared query"
  }); // group "Prepared queries with errors"
}
