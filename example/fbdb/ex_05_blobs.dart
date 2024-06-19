// Demonstrates storing and retrieving blob data.
// Creates a new database, defines a table inside it,
// inserts a row containing blobs and selects it back.
// The sequence is executed twice, once for blobs passed to
// and from the query inline (directly as data buffers),
// and the second time for blobs stored and retrieved separately
// to/from the database and just blob IDs passed to and from
// the query.
// The blobs are defined both as text and binary sub-types.
// As the last (third) example, the blob data is transferred
// directly from/to a file.
// Finally the database is dropped.

import "dart:io";
import "dart:typed_data";
import "dart:convert";
import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating ex_05.fdb");
    // change the user / password to match your Firebird setup
    // in ex_auth.dart
    db = await FbDb.createDatabase(
      database: "ex_05.fdb",
      user: userName,
      password: userPassword,
      options: FbOptions(
        pageSize: 4096, // this is the default
        dbCharset: "UTF8", // this is the default
      ),
    );
    print("Created.");

    print("Creating table BLOBS_TBL");
    final q = db.query();
    await q.execute(
      sql: "create table BLOBS_TBL( "
          "   ID integer not null primary key, "
          "   TXT_BLOB blob sub_type text, "
          "   BIN_BLOB blob sub_type binary "
          ") ",
    );
    print("Table created.");

    // Passing
    print("Inserting test data.");
    // binary blob will contain a string of bytes being a binary
    // representation of two 64-bit floats
    final inBin = Uint8List(32);
    final floats = inBin.buffer.asFloat64List();
    floats[0] = 1.1;
    floats[1] = 2.2;
    floats[2] = 3.3;
    floats[3] = 4.4;
    final inTxt = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit, 
sed do eiusmod tempor incididunt ut labore et dolore magna 
aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
ullamco laboris nisi ut aliquip ex ea commodo consequat. 
Duis aute irure dolor in reprehenderit in voluptate velit 
esse cillum dolore eu fugiat nulla pariatur. Excepteur sint 
occaecat cupidatat non proident, sunt in culpa qui officia 
deserunt mollit anim id est laborum.
""";
    await q.execute(
      sql: "insert into BLOBS_TBL (ID, TXT_BLOB, BIN_BLOB) "
          "values (?, ?, ?) ",
      parameters: [1, inTxt, inBin.buffer],
    );
    print("Row inserted.");

    print("Selecting the row.");
    await q.openCursor(sql: "select * from BLOBS_TBL");
    final r = await q.fetchOneAsMap();
    if (r == null) {
      print("No data");
    } else {
      print("Text blob:");
      print(utf8.decode((r['TXT_BLOB'] as ByteBuffer).asUint8List()));
      final f = (r['BIN_BLOB'] as ByteBuffer).asFloat64List();
      print("Binary blob (as floats): ${f[0]} ${f[1]} ${f[2]} ${f[3]}");
    }

    print("Clearing up BLOBS_TBL");
    await q.execute(sql: "delete from BLOBS_TBL");

    print("Starting transaction");
    await db.startTransaction();

    print("Sending text blob in chunks");
    // for demonstration purposes, we divide the text into
    // two halves and use them as blob segments
    final halfLen = inTxt.length ~/ 2;
    final inTxt1 = inTxt.substring(0, halfLen);
    final inTxt2 = inTxt.substring(halfLen);
    final id1 = await db.createBlob();
    print("Sending segment 1");
    await db.putBlobSegmentStr(id: id1, data: inTxt1);
    print("Sending segment 2");
    await db.putBlobSegmentStr(id: id1, data: inTxt2);
    await db.closeBlob(id: id1);

    print("Sending binary blob as stream");
    // for demonstration purposes, we'll stream the binary data
    // byte-by-byte, as 1-byte buffers
    final binStream = (Uint8List l) async* {
      stdout.write("Streaming bytes: ");
      for (var b in l) {
        final buf = Uint8List.fromList([b]);
        stdout.write("*");
        yield buf.buffer;
      }
      print("");
    }(inBin);
    final id2 = await db.createBlob();
    await db.putBlobFromStream(id: id2, stream: binStream);
    await db.closeBlob(id: id2);

    print("Inserting both blobs into BLOBLS_TBL");
    await q.execute(
      sql: "insert into BLOBS_TBL (ID, TXT_BLOB, BIN_BLOB) "
          "values (?, ?, ?) ",
      parameters: [1, id1, id2],
    );
    print("Row inserted.");

    print("Selecting the row with blobs NOT inlined");
    await q.openCursor(sql: "select * from BLOBS_TBL", inlineBlobs: false);
    final r2 = await q.fetchOneAsMap();
    if (r2 == null) {
      print("No data");
    } else {
      final txtId = r2['TXT_BLOB'] as FbBlobId;
      final binId = r2['BIN_BLOB'] as FbBlobId;

      final List<int> codeUnits = [];
      // we set segment size to 16 bytes by purpose
      final txtBlobStream = await db.openBlob(id: txtId, segmentSize: 16);
      stdout.write("Reading text blob in chunks: ");
      await txtBlobStream.forEach((segment) {
        stdout.write("${segment.lengthInBytes},");
        codeUnits.addAll(segment.asUint8List());
      });

      print("");
      print("Text blob:");
      print(utf8.decode(codeUnits));

      stdout.write("Reading binary blob in chunks: ");
      final binBlobStream = await db.openBlob(id: binId, segmentSize: 8);
      final List<int> bytes = [];
      await binBlobStream.forEach((segment) {
        stdout.write("${segment.lengthInBytes},");
        bytes.addAll(segment.asUint8List());
      });
      final flts = Uint8List.fromList(bytes).buffer.asFloat64List();
      print("");
      print("Binary blob (as floats): $flts");
    }
    await q.close(); // close() has to be awaited too!
    print("Ending transaction");
    await db.commit();

    await q.execute(sql: "delete from BLOBS_TBL");

    // Getting blob data directly from a file, storing blob data to a file.
    print("\nSetting and getting the text blob via file system");
    const inFilePath = "blob_in.txt";
    const outFilePath = "blob_out.txt";

    await File(inFilePath).writeAsString(inTxt);
    await db.startTransaction();
    print("Creating new blob");
    final fileBlobId = await db.createBlob();
    print("Transferring blob data from a file");
    await db.blobFromFile(id: fileBlobId, file: File(inFilePath));
    print("Inserting a row with the blob");
    await q.execute(
      sql: "insert into BLOBS_TBL(ID, TXT_BLOB) values(?, ?)",
      parameters: [1, fileBlobId],
    );
    print("Selecting the row back");
    await q.openCursor(
      sql: "select TXT_BLOB from BLOBS_TBL",
      inlineBlobs: false,
    );
    final FbBlobId dbBlobId = (await q.fetchOneAsList())?[0];
    print("Storing the blob data in a file");
    await db.blobToFile(id: dbBlobId, file: File(outFilePath));

    print("Blob contents stored in the file:");
    print(await File(outFilePath).readAsString());

    print("Deleting temporary files");
    await File(inFilePath).delete();
    await File(outFilePath).delete();

    await db.commit();
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping the database");
      await db.dropDatabase();
      print("Dropped.");
    }
  }
}
