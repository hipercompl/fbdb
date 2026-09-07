@TestOn("vm")
library;

import 'dart:convert';

import 'package:fbdb/fbdb.dart';
import 'package:test/test.dart';
import "test_utils.dart";

void main() async {
  group("Batch without blobs", () {
    test("INSERT, no multierror, no record count", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;
        final b = await db.batch(sql: "insert into T1(PK, VC) values(?, ?)");
        for (var i = 1; i <= recordCount; i++) {
          await b.add([i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          rno++;
        }
      });
    });

    test("INSERT, multierror, record count", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          options: FbBatchOptions(multiError: true, recordCounts: true),
        );
        for (var i = 1; i <= recordCount; i++) {
          await b.add([i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        expect(r.statuses.length, equals(recordCount));
        expect(
          listsEqual(r.statuses, List<dynamic>.filled(recordCount, 1)),
          isTrue,
        );
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          rno++;
        }
      });
    });

    test("batch reuse", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          options: FbBatchOptions(multiError: true, recordCounts: true),
        );
        for (var i = 1; i <= recordCount; i++) {
          await b.add([i, "Record $i"]);
        }
        final r = await b.execute();
        // no b.close() here, the batch will be reused
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        expect(r.statuses.length, equals(recordCount));
        expect(
          listsEqual(r.statuses, List<dynamic>.filled(recordCount, 1)),
          isTrue,
        );
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          rno++;
        }

        // reuse the same batch
        for (var i = 1; i <= recordCount; i++) {
          await b.add([i + recordCount, "Record ${i + recordCount}"]);
        }
        final r2 = await b.execute();
        await b.close(); // close after the last use
        expect(r2, isNotNull);
        expect(r2.errorCount, equals(0));
        expect(r2.statuses.length, equals(recordCount));
        expect(
          listsEqual(r2.statuses, List<dynamic>.filled(recordCount, 1)),
          isTrue,
        );
        final rows2 = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows2.length, equals(recordCount * 2));
        rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          rno++;
        }
      });
    });

    test("UPDATE, multierror, record count", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 3;
        const missCount = 5;
        for (var i = 1; i <= recordCount; i++) {
          await db.execute(
            sql: "insert into T1(PK, VC) values (?, ?)",
            parameters: [i, "Record $i"],
          );
        }

        final b = await db.batch(
          sql: "update T1 set VC=? where PK between ? and ?",
          options: FbBatchOptions(multiError: true, recordCounts: true),
        );
        for (var i = 0; i < missCount; i++) {
          await b.add(["updated", recordCount + 1, recordCount + 1]);
        }
        for (var i = 2; i <= recordCount; i++) {
          // the first row will not be updated
          // each update updates 1 row less than the previous one
          await b.add(["updated", i, recordCount]);
        }

        final r = await b.execute();
        await b.close();

        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        expect(r.statuses.length, equals(missCount + recordCount - 1));
        expect(
          listsEqual(
            r.statuses.sublist(0, missCount),
            List<dynamic>.filled(missCount, 0),
          ),
          isTrue,
        );
        for (var i = 1; i < recordCount; i++) {
          expect(r.statuses[i + missCount - 1], equals(recordCount - i));
        }
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          if (rno == 1) {
            expect(row["VC"], equals("Record $rno"));
          } else {
            expect(row["VC"], equals("updated"));
          }
          rno++;
        }
      });
    });
  });

  group("Batch with blobs", () {
    test("inline blobs", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;
        final b = await db.batch(
          sql: "insert into T2(PK, VC, B) values(?, ?, ?)",
        );
        for (var i = 1; i <= recordCount; i++) {
          await b.add([
            i,
            "Record $i",
            Utf8Encoder().convert("Blob in record $i"),
          ]);
        }
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        final rows = await db.selectAll(sql: "select * from T2 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          expect(
            Utf8Decoder().convert(row["B"]),
            equals("Blob in record $rno"),
          );
          rno++;
        }
      });
    });
    test("pre-created blobs", () async {});
  });

  group("Batch with errors", () {
    test("no multierror", () async {});
    test("with multierror", () async {});
    test("with multierror, exceeding max detailed error count", () async {});
  });

  group("Batch in explicit transaction", () {
    test("batch committed", () async {});
    test("batch rolled back", () async {});
  });

  group("internal batch errors", () {
    test("invalid creation parameters", () async {});

    test("invalid number of values in add", () async {});

    test("invalid types of values in add", () async {});
  });
}
