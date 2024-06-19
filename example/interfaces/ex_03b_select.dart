// An equivalent of ex_03_select.dart, with the following exceptions:
// - the cursor is obtained directly from the attachment,
//   without preparing a statement,
// - the output message metadata is obtained from the cursor
//   instead of the statement.

import "dart:ffi";
import "dart:math";
import "package:fbdb/fbclient.dart";
import "ex_auth.dart";

int main() {
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
    return 1;
  }

  IAttachment? att;
  ITransaction? tra;
  IXpbBuilder? dpb;
  IXpbBuilder? tpb;
  IMetadataBuilder? builder;
  IMessageMetadata? meta;
  IResultSet? curs;
  int rc = 0;

  try {
    print("Obtaining initial interfaces");

    IStatus status = master.getStatus();
    IProvider prov = master.getDispatcher();

    // prepare DPB to connect to localhost:employee
    // make sure the employee alias is configured
    print("Preparing to attach to the database (building DPB)");
    dpb = utl.getXpbBuilder(status, IXpbBuilder.dpb);
    dpb.insertString(status, FbConsts.isc_dpb_host_name, "localhost");
    dpb.insertString(status, FbConsts.isc_dpb_user_name, userName);
    dpb.insertString(status, FbConsts.isc_dpb_password, userPassword);
    dpb.insertString(status, FbConsts.isc_dpb_lc_ctype, "UTF8");

    // attach to the employee database
    print("Attaching to employee on localhost");
    att = prov.attachDatabase(
        status, "employee", dpb.getBufferLength(status), dpb.getBuffer(status));
    print("Attached to the database");

    // start transaction
    print("Preparing to start a transaction (building TPB)");
    tpb = utl.getXpbBuilder(status, IXpbBuilder.tpb);
    tpb.insertTag(status, FbConsts.isc_tpb_read_committed);
    tpb.insertTag(status, FbConsts.isc_tpb_no_rec_version);
    tpb.insertTag(status, FbConsts.isc_tpb_wait);
    tpb.insertTag(status, FbConsts.isc_tpb_read);

    print("Starting a new transaction");
    tra = att.startTransaction(
        status, tpb.getBufferLength(status), tpb.getBuffer(status));

    // the select statement
    const sqlSelect = """
      select LAST_NAME, FIRST_NAME, PHONE_EXT
      from PHONE_LIST
      where LOCATION = 'Monterey'
      order by LAST_NAME, FIRST_NAME
    """;

    // execute the query and open cursor
    print("Executing query and opening cursor");
    curs = att.openCursor(status, tra, sqlSelect);
    meta = curs.getMetadata(status);

    // get the list of columns
    print('Processing output metadata');
    builder = meta.getBuilder(status);
    int cols = meta.getCount(status);
    print("The resulting data set consists of $cols columns");

    // parse columns
    print("Parsing column info");

    // fields is a list of maps with keys:
    // "index", "name", "length" and "offset"
    final fields = <Map<String, dynamic>>[];

    for (int i = 0; i < cols; i++) {
      int t = meta.getType(status, i);
      // from among all fields we will use only text ones
      if (t == FbConsts.SQL_VARYING || t == FbConsts.SQL_TEXT) {
        fields.add({
          "index": i,
          "name": meta.getField(status, i),
          "length": 0,
          "offset": 0,
          "type": t,
        });
      }
    }

    // release the current metadata
    meta.release();

    // get the new metadata with coerced data types
    meta = builder.getMetadata(status);

    // builder not needed any more
    builder.release();
    builder = null;

    // get the offsets and lengths
    for (var f in fields) {
      f["length"] = meta.getLength(status, f["index"]);
      f["offset"] = meta.getOffset(status, f["index"]);
    }

    // allocate ouput buffer
    print("Allocating data buffer");
    final buffer = mem.allocate<Uint8>(meta.getMessageLength(status));
    try {
      print("QUERY RESULT:");
      // print table header
      final hdr = StringBuffer("|Row no.|");
      final sep = StringBuffer("|-------|");
      for (var f in fields) {
        hdr.write("${f['name'].padRight(max(f['length'] as int, 10))}|");
        sep.write("${'-' * max(f['length'] as int, 10)}|");
      }
      print("$sep\n$hdr\n$sep");

      int line = 0;
      while (curs.fetchNext(status, buffer) == IStatus.resultOK) {
        // for every row
        line++;
        final row = StringBuffer("|${line.toString().padLeft(7)}|");
        for (var f in fields) {
          // we use readVarchar extension method (defined in mem.dart)
          final val = buffer.readVarchar(f["offset"]).padRight(f["length"]);
          row.write("${val.padRight(10)}|");
        }
        print(row);
      } // for every row
      print(sep);
    } finally {
      mem.free(buffer);
    }

    print("\nClosing interfaces");

    // close the cursor
    curs.close(status);
    curs = null;

    // free the metadata
    meta.release();
    meta = null;

    // commit the transaction (also closes the interface)
    tra.commit(status);
    tra = null; // to avoid calling release() later

    // detach from the database
    print("Detaching from employee database");
    att.detach(status); // aslo closes the interface
    att = null; // so that we don't call release() on the closed attachment

    status.dispose();
    prov.release();
  } on FbStatusException catch (ce) {
    final msg = utl.formattedStatus(ce.status);
    print("FB error: $msg");
    rc = 1;
  }
  builder?.release();
  meta?.release();
  curs?.release();
  att?.release();
  tra?.release();
  tpb?.dispose();
  dpb?.dispose();
  return rc;
}
