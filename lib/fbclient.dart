/// Access Firebird databases via libfbclient native client library.
///
/// This package implements a wrapper around the new, object-oriented
/// Firebird database access routines.
/// It wraps the versioned interfaces and allows to relatively
/// easy interact with native code from libfbclient on all platforms
/// where libfbclient dynamic library is available.
/// Code using fbclient package should be coupled with actual
/// libfbclient binary from official Firebird distribution.
/// The currently supported libfbclient version is 4.x,
/// so it's best to use the client library from Firebird v4 distribution.
/// See the [FbClient] class docs for remarks about the exact location
/// of the libfbclient with respect to the final application executable.
/// Also, please refer to the doc/Using_OO_API.html document in
/// the Firebird installation folder for an overview of using
/// the new OO Firebird API.

library;

// low-level libfbclient API
export "src/fbclient/fbconsts.dart";
export 'src/fbclient/fbclient_lib.dart';
export "src/fbclient/iattachment.dart";
export "src/fbclient/ibatch.dart";
export "src/fbclient/ibatchcompletionstate.dart";
export "src/fbclient/iblob.dart";
export "src/fbclient/iconfig.dart";
export "src/fbclient/iconfigentry.dart";
export "src/fbclient/iconfigmanager.dart";
export "src/fbclient/icryptkeycallback.dart";
export "src/fbclient/idecfloat16.dart";
export "src/fbclient/idecfloat34.dart";
export "src/fbclient/idtc.dart";
export "src/fbclient/idtcstart.dart";
export "src/fbclient/ieventcallback.dart";
export "src/fbclient/ievents.dart";
export "src/fbclient/ifirebirdconf.dart";
export "src/fbclient/iint128.dart";
export "src/fbclient/imaster.dart";
export "src/fbclient/imessagemetadata.dart";
export "src/fbclient/imetadatabuilder.dart";
export "src/fbclient/interfaces.dart";
export "src/fbclient/ioffsetscallback.dart";
export "src/fbclient/ipluginbase.dart";
export "src/fbclient/ipluginconfig.dart";
export "src/fbclient/ipluginfactory.dart";
export "src/fbclient/ipluginmanager.dart";
export "src/fbclient/ipluginmodule.dart";
export "src/fbclient/ipluginset.dart";
export "src/fbclient/iprovider.dart";
export "src/fbclient/ireplicator.dart";
export "src/fbclient/irequest.dart";
export "src/fbclient/iresultset.dart";
export "src/fbclient/iservice.dart";
export "src/fbclient/istatement.dart";
export "src/fbclient/istatus.dart";
export "src/fbclient/itimer.dart";
export "src/fbclient/itimercontrol.dart";
export "src/fbclient/itransaction.dart";
export "src/fbclient/iutil.dart";
export "src/fbclient/iversioncallback.dart";
export "src/fbclient/ixpbbuilder.dart";
export "src/fbclient/mem.dart";
export "src/fbclient/types.dart";
