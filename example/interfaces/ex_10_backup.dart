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

  IXpbBuilder? spb;
  IXpbBuilder? spb2;
  IService? svc;

  try {
    print("Obtaining initial interfaces");

    IStatus status = master.getStatus();
    IProvider prov = master.getDispatcher();

    // prepare DPB to connect to localhost:employee
    // make sure the employee alias is configured
    print("Preparing to attach to the service manager (building SPB)");
    spb = utl.getXpbBuilder(status, IXpbBuilder.spbAttach);
    spb.insertString(status, FbConsts.isc_spb_host_name, "localhost");
    spb.insertString(status, FbConsts.isc_spb_user_name, userName);
    spb.insertString(status, FbConsts.isc_spb_password, userPassword);
    spb.insertString(status, FbConsts.isc_spb_expected_db, "employee");

    // attach to the service manager
    print("Attaching to the service manager on localhost");
    svc = prov.attachServiceManager(
      status,
      "service_mgr",
      spb.getBufferLength(status),
      spb.getBuffer(status),
    );
    print("Attached to localhost:service_mgr");

    print("Querying service manager for server version information");
    const recItemsSize = 1;
    final receiveItems = mem.allocate<Uint8>(recItemsSize);
    const bufSize = 1024;
    final resBuf = mem.allocate<Uint8>(bufSize);
    try {
      print("Backing up employee database via service manager");
      spb2 = utl.getXpbBuilder(status, IXpbBuilder.spbStart);
      spb2.insertTag(status, FbConsts.isc_action_svc_backup);
      spb2.insertString(status, FbConsts.isc_spb_dbname, "employee");
      spb2.insertString(status, FbConsts.isc_spb_bkp_file, "employee.fbk");
      spb2.insertInt(
        status,
        FbConsts.isc_spb_options,
        FbConsts.isc_spb_bkp_no_garbage_collect,
      );

      print("Starting a service for the database employee");
      svc.start(status, spb2.getBufferLength(status), spb2.getBuffer(status));
      print("Service started");

      receiveItems[0] = FbConsts.isc_info_svc_line;

      do {
        resBuf.setAllBytes(bufSize, 0);
        svc.query(
          status,
          0,
          nullptr,
          recItemsSize,
          receiveItems,
          bufSize,
          resBuf,
        );
      } while (printParams(client, resBuf, bufSize));

      print("Done. Backup stored in employee.fbk.");
    } finally {
      mem.free(resBuf);
      mem.free(receiveItems);
    }

    // detach from the service manager
    print("Detaching from the service manager");
    svc.detach(status); // aslo closes the interface
    svc = null; // so that we don't call release() on the closed attachment

    status.dispose();
    prov.release();
  } on FbStatusException catch (ce) {
    final msg = utl.formattedStatus(ce.status);
    print("FB error: $msg");
  }
  svc?.release();
  spb?.dispose();
  spb2?.dispose();
}

// Decodes a single svc query output parameter from the buffer.
// The parameter starts at [offset], the buffer size is [bufSize].
// Returns the offset of the next parameter in the buffer
// and the string read from the buffer.
(int, String) getParamStr(
  FbClient client,
  Pointer<Uint8> buf,
  int offset,
  int bufSize,
) {
  if (offset >= bufSize) {
    return (offset, "");
  }
  int len = buf.readVaxInt16(offset);
  offset += 2;
  final s = buf.readString(offset, len);
  offset += len;
  return (offset, s);
}

// Prints all output svc query parameters from buf.
// Returns true if the end of params (isc_info_end) was not
// reached, i.e. there is more data to be queried about.
// If false is returned, there's no more data
// to be fetched from the service.
bool printParams(FbClient client, Pointer<Uint8> buf, int bufSize) {
  if (bufSize < 0) {
    return false;
  }
  int offset = 0;
  int paramCode = buf[offset];
  var doContinue = false;
  const ignoreTruncation = false;
  while (offset < bufSize && paramCode != FbConsts.isc_info_end) {
    String s = "";
    offset++; // jump behind the code
    switch (paramCode) {
      case FbConsts.isc_info_svc_line:
        var newOffset = offset;
        (newOffset, s) = getParamStr(client, buf, offset, bufSize);
        doContinue = (newOffset > offset + 2);
        offset = newOffset;
        print(s);
      case FbConsts.isc_info_truncated:
        if (!ignoreTruncation) {
          print("\n<< truncated >>");
        }
        doContinue = true;
      case FbConsts.isc_info_svc_timeout:
      case FbConsts.isc_info_data_not_ready:
        doContinue = true;
      default:
        print(
          "Unknown item "
          "0x${paramCode.toRadixString(16).padLeft(2, '0')} "
          "in the result buffer.",
        );
    }
    if (offset < bufSize) {
      paramCode = buf[offset];
    }
  }
  return doContinue;
}
