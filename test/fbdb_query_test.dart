@TestOn("vm")
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import "test_utils.dart";

void main() async {
  group("Date and time conversions", () {
    test("SELECT dates and timestamps", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.openCursor(sql: "select D, TS from T where PK_INT=1 ");
        final row = await q.fetchOneAsMap();
        await q.close();
        expect(row, isNotNull);
        if (row != null) {
          expect(row["D"], equals(DateTime(2024, 1, 1)));
          expect(row["TS"], equals(DateTime(2024, 1, 1, 1, 10, 11)));
        }
      }); // withNewDb1
    }); // test "SELECT dates and timestamps"
  }); // group "Date and time conversions"

  group("SELECT statements", () {
    test("SELECT with fetching by row", () async {
      await withNewDb1((db) async {
        var q = db.query();
        await q.openCursor(
          sql: "select * from T where PK_INT in (?, ?)"
              "order by PK_INT",
          parameters: [1, 2],
        );
        final mrow = await q.fetchOneAsMap();
        final lrow = await q.fetchOneAsList();
        final nrow = await q.fetchOneAsMap();
        await q.close();
        expect(mrow, isNotNull);
        expect(lrow, isNotNull);
        expect(nrow, isNull);

        expect(mrow?["PK_INT"], 1);
        expect(mrow?["C_5"].toString().trimRight(), "row_1");
        expect(mrow?["VC_50"], "This is the first row");
        expect(mrow?["DP"], closeTo(1.1, 0.0001));
        expect(mrow?["DEC_10_3"], closeTo(111.111, 0.0001));
        expect(mrow?["D"], DateTime(2024, 1, 1));
        expect(mrow?["TS"], DateTime(2024, 1, 1, 1, 10, 11));
        expect(
          List<int>.from(Uint8List.view(mrow?["B"])),
          equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
        );

        expect(lrow?[0], 2);
        expect(lrow?[1].toString().trimRight(), "row_2");
        expect(lrow?[2], "This is the second row");
        expect(lrow?[3], closeTo(2.2, 0.0001));
        expect(lrow?[4], closeTo(222.222, 0.0001));
        expect(lrow?[5], DateTime(2024, 2, 2));
        expect(lrow?[6], DateTime(2024, 2, 2, 2, 20, 22));
        expect(
          List<int>.from(Uint8List.view(lrow?[7])),
          equals([2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
        );
      }); // with newDb1
    }); // test "SELECT with fetching by row"
    test("SELECT with fetching from a stream", () async {
      await withNewDb1((db) async {
        var q = db.query();
        await q.openCursor(sql: "select * from T order by PK_INT");
        final rows = await q.rows().toList();
        await q.close();

        expect(rows.length, 3);
        expect(rows[0]["PK_INT"], 1);
        expect(rows[1]["PK_INT"], 2);
        expect(rows[2]["PK_INT"], 3);
      }); // withNewDb1
    }); // test "SELECT with fetching from a stream"
    test("SELECT null value", () async {
      await withNewDb1((db) async {
        var q = db.query();
        await q.openCursor(sql: r"select NULL as VAL from RDB$DATABASE");
        var row = await q.fetchOneAsMap();
        await q.close();
        expect(row, isNotNull);
        if (row != null) {
          expect(row["VAL"], isNull);
        }
      }); // withNewDb1
    }); // test "SELECT null value"

    test("selectOne, selectAll utility methods", () async {
      await withNewDb1((db) async {
        final row = await db.selectOne(
          sql: "select PK_INT from T where PK_INT=?",
          parameters: [1],
        );
        expect(row, isNotNull);
        if (row != null) {
          expect(row["PK_INT"], equals(1));
        }

        final rows = await db.selectAll(
          sql: "select PK_INT from T where PK_INT between ? and ? "
              "order by PK_INT",
          parameters: [1, 3],
        );
        expect(rows, isNotNull);
        if (rows != null) {
          expect(rows.length, equals(3));
          if (rows.length >= 3) {
            expect(rows[0]["PK_INT"], equals(1));
            expect(rows[2]["PK_INT"], equals(3));
          }
        }
      }); // withNewDb1
    }); // test "selectOne, selectAll utility methods"

    test("NULL handling", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
            sql: "insert into T(PK_INT, C_5) values (?, ?)",
            parameters: [4, null]);
        await q.close();
        final row = await db.selectOne(
          sql: "select PK_INT from T where PK_INT=?",
          parameters: [4],
        );
        expect(row, isNotNull);
        if (row != null) {
          expect(row["PK_INT"], equals(4));
          expect(row["C_5"], isNull);
        }
      }); // withNewDb1
    }); // test "selectOne, selectAll utility methods"
  }); // group "SELECT statements"

  group("INSERT statements", () {
    test("INSERT with parameters", () async {
      await withNewDb1((db) async {
        final List<dynamic> testRow = [
          4,
          "row_4",
          "This is the fourth row",
          4.44,
          444.444,
          DateTime(2024, 4, 4),
          DateTime(2024, 4, 4, 14, 44, 44),
          Uint8List.fromList([4, 5, 6, 7, 8, 9, 10])
        ];
        final q = db.query();
        await q.execute(
          sql: "insert into T(PK_INT, C_5, VC_50, DP, DEC_10_3, D, TS, B) "
              "values (?, ?, ?, ?, ?, ?, ?, ?)",
          parameters: testRow,
        );
        var ar = await q.affectedRows();
        expect(ar, equals(1));

        await q.openCursor(
          sql: "select * from T where PK_INT=?",
          parameters: [4],
        );
        final row = await q.fetchOneAsList();
        await q.close();
        expect(row, isNotNull);
        if (row != null) {
          row[1] = row[1].toString().trimRight();
          row[7] = Uint8List.view(row[7]);
          expect(row, equals(testRow));
        }
      }); // withNewDb1
    }); // test "INSERT with parameters"

    test("INSERT with primary key error", () async {
      await withNewDb1((db) async {
        expect(() async {
          final q = db.query();
          await q.execute(
            sql: "insert into T(PK_INT) values (?)",
            parameters: [1],
          );
        }, throwsException);
      }); // withNewDb1
    }); // test "INSERT with primary key error"
  }); // group "INSERT statements"

  group("UPDATE statements", () {
    test("UPDATE with parameters", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
          sql: "update T set DP=? where PK_INT=? ",
          parameters: [3000.03, 1],
        );
        final ar = await q.affectedRows();
        expect(ar, equals(1));

        await q.openCursor(
          sql: "select DP from T where PK_INT=? ",
          parameters: [1],
        );
        final row = await q.fetchOneAsMap();
        await q.close();
        expect(row, isNotNull);
        if (row != null) {
          expect(row["DP"], closeTo(3000.03, 0.0001));
        }
      }); // withNewDb1
    }); // test "UPDATE with parameters"

    test("UPDATE with error", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await expectLater((() async {
          await q.execute(
            sql: "update T set PK_INT=? where PK_INT=?",
            parameters: [1, 2],
          );
        })(), throwsException);
        await q.close();
      }); // withNewDb1
    }); // test "UPDATE with error"
  }); // group "UPDATE statements"

  group("DELETE statements", () {
    test("DELETE with parameters", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
          sql: "delete from T where PK_INT in (?, ?)",
          parameters: [1, 2],
        );
        final r = await q.affectedRows();
        expect(r, equals(2));
        await q.close();
      }); // withNewDb1
    }); // test "DELETE with parameters"

    test("DELETE with no affected rows", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
          sql: "delete from T where PK_INT=?",
          parameters: [-1],
        );
        final r = await q.affectedRows();
        expect(r, isZero);
        await q.close();
      }); // withNewDb1
    }); // test "DELETE with no affected rows"
  }); // group "DELETE statements"

  group("CREATE statements", () {
    test("CREATE table", () async {
      await withNewDb1((db) async {
        final q = db.query();
        expect(() async {
          await q.execute(
            sql: "create table T2(afield INTEGER)",
          );
          await q.close();
        }, returnsNormally);
      }); // withNewDb1
    }); // test "CREATE table"

    test("CREATE duplicated table", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
          sql: "create table T2(afield INTEGER)",
        );
        await expectLater((() async {
          await q.execute(
            sql: "create table T2(afield INTEGER)",
          );
        })(), throwsException);
        await q.close();
      }); // withNewDb1
    }); // test "CREATE duplicated table"
  }); // group "CREATE statements"

  group("DROP statements", () {
    test("DROP existing table", () async {
      await withNewDb1((db) async {
        final q = db.query();
        expect(() async {
          await q.execute(
            sql: "drop table T",
          );
          await q.close();
        }, returnsNormally);
      }); // withNewDb1
    }); // test "DROP existing table"

    test("DROP non-existing table", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.execute(
          sql: "drop table T",
        );
        await expectLater((() async {
          await q.execute(
            sql: "drop table T",
          );
        })(), throwsException);
        await q.close();
      }); // withNewDb1
    }); // test "DROP non-existing table"
  }); // group "DROP statements"

  group("Github issues", () {
    test("issue #4", () async {
      await withNewDb2((db) async {
        final q = db.query();
        final testData = "3408108B67544334A99AA8FB237D4EE5";
        await q.execute(
          sql: "insert into T(PK_INT, VC32) values (?, ?)",
          parameters: [1, testData],
        );
        final dataBack = await db.selectOne(
          sql: "select VC32 from T where PK_INT=1",
        );
        expect(dataBack?.isNotEmpty, isTrue);
        if (dataBack != null) {
          expect(dataBack["VC32"], equals(testData));
        }
      });
    });
  });
}
