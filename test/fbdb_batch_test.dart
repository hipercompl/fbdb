@TestOn("vm")
library;

import 'dart:convert';
import 'dart:typed_data';

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
          await b.add(parameters: [i, "Record $i"]);
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
          await b.add(parameters: [i, "Record $i"]);
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
          await b.add(parameters: [i, "Record $i"]);
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
          await b.add(
            parameters: [i + recordCount, "Record ${i + recordCount}"],
          );
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
          await b.add(
            parameters: ["updated", recordCount + 1, recordCount + 1],
          );
        }
        for (var i = 2; i <= recordCount; i++) {
          // the first row will not be updated
          // each update updates 1 row less than the previous one
          await b.add(parameters: ["updated", i, recordCount]);
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
          await b.add(
            parameters: [
              i,
              "Record $i",
              utf8.encode("Blob in record $i").buffer,
            ],
          );
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
          var blob = row["B"];
          expect(blob, isA<ByteBuffer>());
          if (blob is ByteBuffer) {
            expect(
              utf8.decode(blob.asUint8List()),
              equals("Blob in record $rno"),
            );
          }
          rno++;
        }
      });
    });
    test("pre-created blobs", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;
        await db.startTransaction(); // required to create blobs
        final b = await db.batch(
          sql: "insert into T2(PK, VC, B) values(?, ?, ?)",
        );
        for (var i = 1; i <= recordCount; i++) {
          final blobId = await db.createBlob();
          final blobData = utf8.encode("Blob in record $i");
          await db.putBlobSegment(id: blobId, data: blobData.buffer);
          await db.closeBlob(id: blobId);
          await b.add(parameters: [i, "Record $i", blobId]);
        }
        final r = await b.execute();
        await b.close();
        await db.commit();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        final rows = await db.selectAll(sql: "select * from T2 order by PK");
        expect(rows.length, equals(recordCount));
        var rno = 1;
        for (var row in rows) {
          expect(row["PK"], equals(rno));
          expect(row["VC"], equals("Record $rno"));
          var blob = row["B"];
          expect(blob, isA<ByteBuffer>());
          if (blob is ByteBuffer) {
            expect(
              utf8.decode(blob.asUint8List()),
              equals("Blob in record $rno"),
            );
          }
          rno++;
        }
      });
    });
  });

  group("Batch with errors", () {
    test("no multierror", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          options: FbBatchOptions(multiError: false, recordCounts: false),
        );
        await b.add(parameters: [1, "Record 1"]);
        await b.add(parameters: [2, "Record 2"]);
        await b.add(parameters: [1, "Record 1.2"]); // PK violation
        await b.add(parameters: [1, "Record 1.3"]); // PK violation
        await b.add(parameters: [3, "Record 3"]);
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(1));
        final errors = r.errors();
        expect(errors.length, equals(1));
        expect(r.statuses.length, equals(3));
        if (r.statuses.isNotEmpty) {
          expect(r.statuses.last, isA<FbServerException>());
        }
        expect(errors.containsKey(2), isTrue);
        if (errors.isNotEmpty) {
          expect(errors[2], isA<FbServerException>());
          if (errors[2] is FbServerException) {
            expect(errors[2]?.message.contains("violation of PRIMARY"), isTrue);
          }
        }

        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(2));
        if (rows.length == 2) {
          expect(rows[0]["PK"], equals(1));
          expect(rows[0]["VC"], equals("Record 1"));
          expect(rows[1]["PK"], equals(2));
          expect(rows[1]["VC"], equals("Record 2"));
        }
      });
    });
    test("with multierror", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          options: FbBatchOptions(multiError: true, recordCounts: false),
        );
        await b.add(parameters: [1, "Record 1"]);
        await b.add(parameters: [2, "Record 2"]);
        await b.add(parameters: [1, "Record 1.2"]); // PK violation
        await b.add(parameters: [1, "Record 1.3"]); // PK violation
        await b.add(parameters: [3, "Record 3"]);
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(2));
        final errors = r.errors();
        expect(errors.length, equals(2));
        expect(r.statuses.length, equals(5));
        if (r.statuses.length == 5) {
          expect(r.statuses[0], equals(FbBatchResult.successNoInfo));
          expect(r.statuses[1], equals(FbBatchResult.successNoInfo));
          expect(r.statuses[4], equals(FbBatchResult.successNoInfo));
          expect(r.statuses[2], isA<FbServerException>());
          expect(r.statuses[3], isA<FbServerException>());
        }
        expect(errors.containsKey(2), isTrue);
        expect(errors.containsKey(3), isTrue);
        if (errors.isNotEmpty) {
          expect(errors[2], isA<FbServerException>());
          if (errors[2] is FbServerException) {
            expect(errors[2]?.message.contains("violation of PRIMARY"), isTrue);
          }
          expect(errors[3], isA<FbServerException>());
          if (errors[3] is FbServerException) {
            expect(errors[3]?.message.contains("violation of PRIMARY"), isTrue);
          }
        }

        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(3));
        if (rows.length == 2) {
          expect(rows[0]["PK"], equals(1));
          expect(rows[0]["VC"], equals("Record 1"));
          expect(rows[1]["PK"], equals(2));
          expect(rows[1]["VC"], equals("Record 2"));
          expect(rows[2]["PK"], equals(3));
          expect(rows[2]["VC"], equals("Record 3"));
        }
      });
    });
    test("with multierror, exceeding max detailed error count", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          options: FbBatchOptions(
            multiError: true,
            recordCounts: false,
            maxDetailedErrors: 2, // up to 2 errors from status vectors
          ),
        );
        await b.add(parameters: [1, "Record 1"]);
        await b.add(parameters: [2, "Record 2"]);
        await b.add(parameters: [1, "Record 1.2"]); // PK violation
        await b.add(parameters: [1, "Record 1.3"]); // PK violation
        await b.add(parameters: [1, "Record 1.4"]); // PK violation
        await b.add(parameters: [3, "Record 3"]);
        final r = await b.execute();
        await b.close();
        expect(r, isNotNull);
        expect(r.errorCount, equals(3));
        final errors = r.errors();
        expect(errors.length, equals(3));
        expect(r.statuses.length, equals(6));
        if (r.statuses.length == 5) {
          // successes
          expect(r.statuses[0], equals(FbBatchResult.successNoInfo));
          expect(r.statuses[1], equals(FbBatchResult.successNoInfo));
          expect(r.statuses[5], equals(FbBatchResult.successNoInfo));
          // errors
          expect(r.statuses[2], isA<FbServerException>());
          expect(r.statuses[3], isA<FbServerException>());
          expect(r.statuses[4], isA<FbServerException>());
        }
        expect(errors.containsKey(2), isTrue);
        expect(errors.containsKey(3), isTrue);
        if (errors.isNotEmpty) {
          expect(errors[2], isA<FbServerException>());
          if (errors[2] is FbServerException) {
            expect(errors[2]?.message.contains("violation of PRIMARY"), isTrue);
          }
          expect(errors[3], isA<FbServerException>());
          if (errors[3] is FbServerException) {
            expect(errors[3]?.message.contains("violation of PRIMARY"), isTrue);
          }
          expect(errors[4], isA<FbServerException>());
          if (errors[4] is FbServerException) {
            // the third error should contain a generic error message
            expect(
              errors[4]?.message.contains("violation of PRIMARY"),
              isFalse,
            );
            expect(errors[4]?.message.contains("no details available"), isTrue);
            expect(errors[4]?.errors.length, equals(1));
            if (errors[4]?.errors.length == 1) {
              expect(errors[4]?.errors[0], equals(FbBatchResult.executeFailed));
            }
          }
        }

        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(3));
        if (rows.length == 2) {
          expect(rows[0]["PK"], equals(1));
          expect(rows[0]["VC"], equals("Record 1"));
          expect(rows[1]["PK"], equals(2));
          expect(rows[1]["VC"], equals("Record 2"));
          expect(rows[2]["PK"], equals(3));
          expect(rows[2]["VC"], equals("Record 3"));
        }
      });
    });
  });

  group("Batch in explicit transaction", () {
    test("batch committed", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;

        await db.startTransaction();
        final b = await db.batch(sql: "insert into T1(PK, VC) values(?, ?)");
        for (var i = 1; i <= recordCount; i++) {
          await b.add(parameters: [i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        await db.commit();
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
    test("batch rolled back", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;

        await db.startTransaction();
        final b = await db.batch(sql: "insert into T1(PK, VC) values(?, ?)");
        for (var i = 1; i <= recordCount; i++) {
          await b.add(parameters: [i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        await db.rollback();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(0));
      });
    });
  });

  group("batch in separate transaction", () {
    test("separate transaction committed", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;

        final t = await db.newTransaction();
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          inTransaction: t,
        );
        for (var i = 1; i <= recordCount; i++) {
          await b.add(parameters: [i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        await t.commit();
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

    test("separate transaction rolled back", () async {
      await withNewDbForBatch((FbDb db) async {
        const recordCount = 50;

        final t = await db.newTransaction();
        final b = await db.batch(
          sql: "insert into T1(PK, VC) values(?, ?)",
          inTransaction: t,
        );
        for (var i = 1; i <= recordCount; i++) {
          await b.add(parameters: [i, "Record $i"]);
        }
        final r = await b.execute();
        await b.close();
        await t.rollback();
        expect(r, isNotNull);
        expect(r.errorCount, equals(0));
        final rows = await db.selectAll(sql: "select * from T1 order by PK");
        expect(rows.length, equals(0));
      });
    });
  });

  group("internal batch errors", () {
    test("invalid creation parameters", () async {
      await withNewDbForBatch((FbDb db) async {
        await expectLater((() async {
          await db.batch(sql: "this is an invalid SQL");
        }), throwsA(isA<FbServerException>()));

        // This is rather strange, but Firebird allows creating a batch
        // with nonsense parameters and doesn't complain in any way.
        // The batch works normally.
        // It's not clear whether invalid parameters are left with
        // their default values, or are clamped by the allowed range.
        await expectLater(
          (() async {
            final b = await db.batch(
              sql: "insert into T1(PK) values(?)",
              options: FbBatchOptions(bufferSize: -1, maxDetailedErrors: -1),
            );
            await b.add(parameters: [1]);
            await b.execute();
            await b.close();
            final rows = await db.selectAll(sql: "select * from T1");
            expect(rows.length, equals(1));
          })(),
          completes,
        );
      });
    });

    test("invalid number of values in add", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(sql: "insert into T1(PK, VC) values(?, ?)");

        // too many parameters
        await expectLater(
          (() async {
            await b.add(parameters: [1, "valid", "invalid"]);
          })(),
          throwsA(isA<FbClientException>()),
        );

        // too few parameters
        await expectLater(
          (() async {
            await b.add(parameters: [1]);
          })(),
          throwsA(isA<FbClientException>()),
        );
      });
    });

    test("invalid types of values in add", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(sql: "insert into T1(PK, VC) values(?, ?)");

        // string instead of int
        await expectLater(
          (() async {
            await b.add(parameters: ["invalid", "valid"]);
          })(),
          throwsA(isA<TypeError>()),
        );
      });
    });

    test("buffer overflow", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(
          sql: "insert into T2(PK, B) values(?, ?)",
          options: FbBatchOptions(bufferSize: 128 * 1024),
        );
        final i1 = await b.getInfo();
        expect(i1.maxBufferSize, equals(128 * 1024));

        Uint8List blob = Uint8List(1024);
        blob.fillRange(0, blob.length - 1, 10);

        for (var i = 0; i < 129; i++) {
          await b.add(parameters: [i, blob.buffer]);
        }

        final i2 = await b.getInfo();
        expect(i2.blobSize + i2.dataSize > i2.maxBufferSize, isTrue);
        await expectLater(
          (() async {
            await b.execute();
          })(),
          throwsA(isA<FbServerException>()),
        );
        await b.close();
      });
    });
  });

  group("batch info", () {
    test("basic batch info", () async {
      await withNewDbForBatch((FbDb db) async {
        final b = await db.batch(sql: "insert into T2(PK, B) values(?, ?)");
        final i1 = await b.getInfo();
        expect(i1.maxBufferSize > 0, isTrue);
        expect(i1.dataSize == 0, isTrue);
        expect(i1.blobSize == 0, isTrue);

        for (var i = 0; i < 100; i++) {
          await b.add(
            parameters: [i, utf8.encode("Blob data for record $i").buffer],
          );
        }

        final i2 = await b.getInfo();
        expect(i2.maxBufferSize > 0, isTrue);
        expect(i2.dataSize > 0, isTrue);
        expect(i2.blobSize > 0, isTrue);
      });
    });
  });
}
