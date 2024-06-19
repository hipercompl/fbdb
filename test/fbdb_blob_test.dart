@TestOn("vm")
library;

import 'dart:io';
import 'package:test/test.dart';
import 'dart:typed_data';
import 'package:fbdb/fbdb.dart';
import 'test_utils.dart';

void main() async {
  group("Reading BLOB", () {
    test("Reading BLOB inline", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await q.openCursor(sql: "select B from T where PK_INT=1");
        final row = await q.fetchOneAsMap();
        expect(row, isNotNull);
        await q.close();
        if (row != null) {
          expect(
            Uint8List.view(row["B"]),
            equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
          );
        }
      }); // withNewDb1
    }); // test "Reading BLOB inline"

    test("Readin BLOB in segments", () async {
      await withNewDb1((db) async {
        final q = db.query();
        await db.startTransaction();
        await q.openCursor(
          sql: "select B from T where PK_INT=1",
          inlineBlobs: false,
        );
        final row = await q.fetchOneAsMap();
        expect(row, isNotNull);
        await q.close();
        if (row == null) {
          return;
        }
        FbBlobId blobId = row["B"];
        final data = List<int>.empty(growable: true);
        await for (var segment in await db.openBlob(id: blobId)) {
          data.addAll(Uint8List.view(segment));
        }
        await db.commit();
        expect(data, equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
      }); // withNewDb1
    }); // test "Reading BLOB in segments"
  }); // group "Reading BLOB"

  group("Writing BLOB", () {
    test("Writing BLOB inline", () async {
      await withNewDb1((db) async {
        final data = Uint8List.fromList([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

        final q = db.query();
        await q.execute(
          sql: "insert into T(PK_INT, B) values(?, ?)",
          parameters: [4, data.buffer],
        );
        final ar = await q.affectedRows();
        expect(ar, equals(1));

        await q.openCursor(sql: "select B from T where PK_INT=4");
        final row = await q.fetchOneAsList();
        expect(row, isNotNull);
        final dataBack = Uint8List.view(row?[0]);
        await q.close();
        expect(dataBack, equals(data));
      }); // withNewDb1
    }); // test "Writing BLOB inline"

    test("Writing BLOB in segments", () async {
      await withNewDb1((db) async {
        final data = Uint8List.fromList([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
        // divide data into 2 segments
        final seg1 = data.sublist(0, 5);
        final seg2 = data.sublist(5);
        await db.startTransaction();
        final blobId = await db.createBlob();
        // put each segment separately
        await db.putBlobSegment(id: blobId, data: seg1.buffer);
        await db.putBlobSegment(id: blobId, data: seg2.buffer);
        await db.closeBlob(id: blobId);

        final q = db.query();
        await q.execute(
          sql: "insert into T(PK_INT, B) values(?, ?)",
          parameters: [4, blobId],
        );
        final ar = await q.affectedRows();
        expect(ar, equals(1));
        await db.commit();

        await q.openCursor(sql: "select B from T where PK_INT=4");
        final row = await q.fetchOneAsList();
        expect(row, isNotNull);
        final dataBack = Uint8List.view(row?[0]);
        await q.close();
        expect(dataBack, equals(data));
      }); // withNewDb1
    }); // test "Writing BLOB in segments"
  }); // group "Writing BLOB"

  group("BLOB from/to file", () {
    test("Blob from/to file", () async {
      await withNewDb1((db) async {
        final fileLoc1 = "blob_in.bin";
        final fileLoc2 = "blob_out.bin";
        final data = Uint8List.fromList([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
        if (await File(fileLoc1).exists()) {
          await File(fileLoc1).delete();
        }
        if (await File(fileLoc2).exists()) {
          await File(fileLoc2).delete();
        }

        await File(fileLoc1).writeAsBytes(data, flush: true);
        await db.startTransaction();
        final blobIdIn = await db.createBlob();
        await db.blobFromFile(id: blobIdIn, file: File(fileLoc1));
        await db.closeBlob(id: blobIdIn);
        final q = db.query();
        await q.execute(
          sql: "insert into T(PK_INT, B) values(?, ?)",
          parameters: [4, blobIdIn],
        );
        final ar = await q.affectedRows();
        expect(ar, equals(1));
        await db.commit();

        await db.startTransaction();
        await q.openCursor(
          sql: "select B from T where PK_INT=4",
          inlineBlobs: false,
        );
        final row = await q.fetchOneAsList();
        expect(row, isNotNull);
        if (row == null) {
          return;
        }

        FbBlobId blobIdOut = row[0];
        await db.blobToFile(id: blobIdOut, file: File(fileLoc2));
        await db.commit();

        final dataBack = await File(fileLoc2).readAsBytes();
        expect(dataBack, equals(data));

        await File(fileLoc1).delete();
        await File(fileLoc2).delete();
      }); // withNewDb1
    }); // test "Blob from/to file"
  }); // group "BLOB from/to file"
}
