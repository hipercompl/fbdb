import "dart:ffi";
import "package:fbdb/fbclient.dart";
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

  IAttachment? att;
  ITransaction? tra;
  IXpbBuilder? dpb;
  IMessageMetadata? meta;
  IResultSet? curs;

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
    print("Starting a new transaction");
    tra = att.startTransaction(status);

    // the select statement
    const sql = r"""
      select * from RDB$RELATIONS
      where RDB$RELATION_ID < 10
      or RDB$VIEW_SOURCE is not null
    """;

    // execute the query and open cursor
    print("Executing query and opening cursor");
    curs = att.openCursor(status, tra, sql);
    meta = curs.getMetadata(status);

    // get the list of columns
    print('Processing output metadata');
    int cols = meta.getCount(status);

    // parse columns
    print("Parsing column info");

    // fields is a list of maps with keys:
    // "index", "name", "length" and "offset"
    final fields = <Field>[];

    final supportedTypes = [
      FbConsts.SQL_TEXT,
      FbConsts.SQL_VARYING,
      FbConsts.SQL_SHORT,
      FbConsts.SQL_DOUBLE,
    ];

    for (int index = 0; index < cols; index++) {
      final type = meta.getType(status, index) & ~1; // mask null bit
      final name = meta.getField(status, index);
      if (supportedTypes.contains(type) ||
          (type == FbConsts.SQL_BLOB &&
              (meta.getSubType(status, index) == 1))) {
        fields.add(Field(name, type, meta.getLength(status, index),
            meta.getOffset(status, index), meta.getNullOffset(status, index)));
      }
    }

    final bufLen = meta.getMessageLength(status);
    final buf = mem.allocate<Uint8>(bufLen);
    try {
      while (curs.fetchNext(status, buf) == IStatus.resultOK) {
        for (var f in fields) {
          print(f.asString(status, att, tra, buf));
        }
        print("-" * 40);
      }
    } finally {
      mem.free(buf);
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
  }
  meta?.release();
  curs?.release();
  att?.release();
  tra?.release();
  dpb?.dispose();
}

class Field {
  String name;
  int type;
  int length;
  int offset;
  int nullOffset;

  Field(this.name, this.type, this.length, this.offset, this.nullOffset);

  String asString(
      IStatus status, IAttachment att, ITransaction tra, Pointer<Uint8> buf) {
    final s = StringBuffer();
    s.write("$name: ");
    if (buf.readInt16(nullOffset) != 0) {
      s.write("<Null>");
    } else {
      switch (type) {
        case FbConsts.SQL_TEXT:
          final v = buf.readString(offset, length).trimRight();
          s.write(v);
        case FbConsts.SQL_VARYING:
          final v = buf.readVarchar(offset).trimRight();
          s.write(v);
        case FbConsts.SQL_SHORT:
          s.write(buf.readInt16(offset).toString());
        case FbConsts.SQL_DOUBLE:
          s.write(buf.readDouble(offset).toString());
        case FbConsts.SQL_BLOB:
          IBlob? blob = att.openBlob(
              status, tra, Pointer<IscQuad>.fromAddress(buf.address + offset));
          const segBufLen = 16;
          final segBuf = mem.allocate<Uint8>(segBufLen);
          final len = mem.allocate<UnsignedInt>(sizeOf<UnsignedInt>());
          try {
            for (;;) {
              final cc = blob.getSegment(status, segBufLen, segBuf, len);
              if (![IStatus.resultOK, IStatus.resultSegment].contains(cc)) {
                break;
              }
              s.write(segBuf.readString(0, len.value));
            }
            blob.close(status);
            blob = null;
          } finally {
            mem.free(segBuf);
            if (blob != null) {
              blob.release();
            }
          }
        default:
          throw FbClientException(
              "Unknown type $type for field $name (in print)");
      }
    }
    return s.toString();
  }
}
