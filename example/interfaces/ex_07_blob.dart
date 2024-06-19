import "dart:convert";
import "dart:ffi";
import "package:fbdb/fbclient.dart";
import "package:ffi/ffi.dart";
import "ex_auth.dart";

void main() {
  FbClient? client;
  IMaster? master;
  IUtil? utl;
  try {
    print("Initializing fbclient");
    client = FbClient();
    master = client.fbGetMasterInterface();
    utl = master.getUtilInterface();
  } catch (e) {
    print("Error during the initialization of fbclient: $e");
    return;
  }

  const testData = [
    "This is test data ",
    "that is inserted during example execution ",
    "into blobs_table",
  ];

  IAttachment? att;
  ITransaction? tra;
  IXpbBuilder? dpb;
  IMetadataBuilder? builder;
  IMessageMetadata? meta;
  IBlob? blob;

  try {
    print("Obtaining initial interfaces");

    IStatus status = master.getStatus();
    IProvider prov = master.getDispatcher();

    // prepare DPB to create a local database
    print("Preparing to create the database (building DPB)");
    dpb = utl.getXpbBuilder(status, IXpbBuilder.dpb);
    dpb.insertString(status, FbConsts.isc_dpb_user_name, userName);
    dpb.insertString(status, FbConsts.isc_dpb_password, userPassword);
    dpb.insertString(status, FbConsts.isc_dpb_lc_ctype, "UTF8");
    dpb.insertString(status, FbConsts.isc_dpb_set_db_charset, "UTF8");

    // Create the database
    print("Creating blob_07.fdb");
    att = prov.createDatabase(status, "blob_07.fdb",
        dpb.getBufferLength(status), dpb.getBuffer(status));
    print("Database created");

    // start transaction
    print("Starting a new transaction");
    tra = att.startTransaction(status);

    // create table
    print("Creating table blobs_table");
    att.execute(status, tra, "create table BLOBS_TABLE (B blob sub_type text)");
    tra.commitRetaining(status);
    print("Table blobs_table created successfully");

    // prepare the metadata
    print("Preparing query metadata");
    builder = master.getMetadataBuilder(status, 1);
    builder.setType(status, 0, FbConsts.SQL_BLOB);
    builder.setSubType(status, 0, FbConsts.isc_blob_text);
    meta = builder.getMetadata(status);
    builder.release();
    builder = null;

    // message buffer
    final buf = mem.allocate<Uint8>(meta.getMessageLength(status));
    try {
      print("Creating blob to insert");
      blob = att.createBlob(
          status,
          tra,
          Pointer<IscQuad>.fromAddress(
              buf.address + meta.getOffset(status, 0)));
      for (var txt in testData) {
        final txtUtf = txt.toNativeUtf8(allocator: mem);
        try {
          blob.putSegment(status, txtUtf.length, txtUtf.cast());
        } finally {
          mem.free(txtUtf);
        }
      }
      blob.close(status);
      blob = null;
    } finally {
      mem.free(buf);
    }

    // insert the blob into the table
    print("Inserting blob into blobs_table");
    att.execute(status, tra, "insert into BLOBS_TABLE (B) values (?)",
        FbConsts.sqlDialectCurrent, meta, buf);
    print("Blob inserted successfully");

    // select the blob back from the table
    print("Reading the blob back from the table");
    final obuf = mem.allocate<Uint8>(meta.getMessageLength(status));
    try {
      att.execute(status, tra, "select first(1) B from BLOBS_TABLE",
          FbConsts.sqlDialectCurrent, null, null, meta, obuf);
      blob = att.openBlob(
        status,
        tra,
        (buf + meta.getOffset(status, 0)).cast(),
      );
      print("Reading blob data from the connection");
      final blobBytes = <int>[];
      const blobBufLen = 32;
      final blobBuf = mem.allocate<Uint8>(blobBufLen);
      final len = mem.allocate<UnsignedInt>(sizeOf<UnsignedInt>());
      try {
        for (;;) {
          final cc = blob.getSegment(status, blobBufLen, blobBuf, len);
          if (![IStatus.resultOK, IStatus.resultSegment].contains(cc)) {
            break;
          }
          blobBytes.addAll(blobBuf.toDartMem(len.value));
        }
      } finally {
        mem.free(blobBuf);
        mem.free(len);
      }
      final s = utf8.decode(blobBytes);
      print("Blob text: $s");

      blob.close(status);
      blob = null;
    } finally {
      mem.free(obuf);
    }

    // commit the transaction (also closes the interface)
    tra.commit(status);
    tra = null; // to avoid calling release() later

    // drop the database
    print("Dropping blob_07.fdb");
    try {
      att.dropDatabase(status);
      att = null; // so that we don't call release() on the closed attachment
      print("Database dropped. All clean.");
    } on FbStatusException catch (e) {
      print("Couldn't drop the database. Please drop it manually.");
      final msg = utl.formattedStatus(e.status);
      print("FB error: $msg");
      status.init();
    }
    status.dispose();
    prov.release();
  } on FbStatusException catch (ce) {
    final msg = utl.formattedStatus(ce.status);
    print("FB error: $msg");
  }
  blob?.release();
  builder?.release();
  meta?.release();
  att?.release();
  tra?.release();
  dpb?.dispose();
}
