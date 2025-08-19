import "dart:ffi";
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
  IStatement? stmt;
  IMetadataBuilder? builder;
  IMessageMetadata? meta;
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
      status,
      "employee",
      dpb.getBufferLength(status),
      dpb.getBuffer(status),
    );
    print("Attached to the database");

    // start transaction
    print("Starting a new transaction");
    tra = att.startTransaction(status);

    // the update statement
    const sqlUpdate = """
      update DEPARTMENT 
      set BUDGET = ? * BUDGET
      where DEPT_NO = ?
    """;

    // prepare the statement
    print("Preparing the update query:");
    print(sqlUpdate);
    stmt = att.prepare(status, tra, sqlUpdate);

    // build the message metadata
    print("Assembling the metadata");
    builder = master.getMetadataBuilder(status, 2);
    builder.setType(status, 0, FbConsts.SQL_DOUBLE + 1); // +1 = nullable
    builder.setType(status, 1, FbConsts.SQL_TEXT + 1); // +1 = nullable
    builder.setLength(status, 1, 3);

    // get the metadata
    meta = builder.getMetadata(status);

    // we no longer need the builder
    builder.release();
    builder = null; // to avoid calling release again

    // the input data
    const updateData = [
      ("622", 0.05),
      ("100", 1.00),
      ("116", 0.075),
      ("900", 0.10),
      ("116", 1000.0), // should cause validation error in the DB
    ];

    // location of parameters in the input message
    final deptOffset = meta.getOffset(status, 1);
    final percOffset = meta.getOffset(status, 0);

    // allocate the input message buffer
    Pointer<Uint8> msg = mem.allocate(meta.getMessageLength(status));
    try {
      // set null flags to not null
      // use the pointer extensions from fbclient (mem.dart)
      // put into the message as 2-byte short ints
      msg.writeUint16(meta.getNullOffset(status, 0), 0);
      msg.writeUint16(meta.getNullOffset(status, 1), 0);

      // version 1: using prepared statement
      print("Version 1 of department budget update (prepared statement)");
      for (var (dept, perc) in updateData) {
        print("Increasing budget for department $dept by $perc");
        try {
          // msg.writeXX are extension methods defined in mem.dart
          msg.writeString(deptOffset, dept);
          msg.writeDouble(percOffset, perc);
          stmt.execute(status, tra, meta, msg);
        } on FbStatusException catch (e) {
          if (e.status.getErrors()[1] == FbErrorCodes.isc_not_valid) {
            print("Department $dept: budget exceeded, not udpated!");
          }
          final msg = utl.formattedStatus(e.status);
          print("Error: $msg");
          status.init(); // reset the error vector
        }
        // rollback the transaction
        tra.rollbackRetaining(status);
      }
    } finally {
      mem.free(msg);
    }
    // free the statement (also closes the interface)
    stmt.free(status);
    stmt = null; // to avoid calling release later

    // version 2: using execute without a prepared statement
    print("\nVersion 2 of department budget update (execute without prepare)");
    for (var (dept, perc) in updateData) {
      print("Increasing budget for department $dept by $perc");
      try {
        // msg.writeXX are extension methods defined in mem.dart
        msg.writeString(deptOffset, dept);
        msg.writeDouble(percOffset, perc);
        att.execute(
          status,
          tra,
          sqlUpdate,
          FbConsts.sqlDialectCurrent,
          meta,
          msg,
        );
      } on FbStatusException catch (e) {
        if (e.status.getErrors()[1] == FbErrorCodes.isc_not_valid) {
          print("Department $dept: budget exceeded, not udpated!");
        }
        final msg = utl.formattedStatus(e.status);
        print("Error: $msg");
        status.init(); // reset the error vector
      }
      // rollback the transaction
      tra.rollbackRetaining(status);
    }

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
  stmt?.release();
  att?.release();
  tra?.release();
  dpb?.dispose();
  return rc;
}
