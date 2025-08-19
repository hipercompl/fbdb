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
  int rc = 0;

  try {
    print("Obtaining initial interfaces");
    IStatus status = master.getStatus();
    IProvider prov = master.getDispatcher();

    // prepare DPB with 4k page size and auth info
    print("Preparing to create database (building DPB)");
    dpb = utl.getXpbBuilder(status, IXpbBuilder.dpb);
    dpb.insertInt(status, FbConsts.isc_dpb_page_size, 4 * 1024);
    dpb.insertInt(status, FbConsts.isc_dpb_sql_dialect, 3);
    dpb.insertString(status, FbConsts.isc_dpb_user_name, userName);
    dpb.insertString(status, FbConsts.isc_dpb_password, userPassword);
    dpb.insertString(status, FbConsts.isc_dpb_lc_ctype, "UTF8");

    // create an empty database
    print("Creating database tests.fdb");
    att = prov.createDatabase(
      status,
      "fbtests.fdb",
      dpb.getBufferLength(status),
      dpb.getBuffer(status),
    );
    print("Database tests.fdb created");

    // start transaction
    print("Starting a new transaction");
    tra = att.startTransaction(status);

    // create table
    print("Creating table dates_table");
    att.execute(status, tra, "create table DATES_TABLE (d1 DATE)");
    tra.commitRetaining(status);
    print("Table dates_table created");

    // insert a row
    print("Inserting a row into dates_table");
    att.execute(status, tra, "insert into DATES_TABLE values (CURRENT_DATE)");
    tra.commit(status); // commit closes the transaction interface
    tra = null; // so that we don't call release() later on this interface
    print("A row was added to dates_table");

    // detach from the database
    print("Detaching from tests.fdb");
    att.detach(status); // aslo closes the interface
    att = null; // so that we don't call release() on the closed attachment

    status.dispose();
    prov.release();
  } on FbStatusException catch (ce) {
    final msg = utl.formattedStatus(ce.status);
    print("Error: $msg");
    rc = 1;
  }

  att?.release();
  tra?.release();
  dpb?.dispose();
  return rc;
}
