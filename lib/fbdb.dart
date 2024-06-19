/// Access Firebird databases via libfbclient native client library.
///
/// This package implements a wrapper around the new, object-oriented
/// Firebird database access routines.
/// It exposes a high-level, Dart-oriented API, based on asynchronous
/// processing, streams and isolates.
/// Under the hood, it uses the low-level Firebird interfaces
/// via FFI.

library;

// high-level FbDb API
export "src/fbdb/fbdbcommon.dart";
export "src/fbdb/fboptions.dart";
export "src/fbdb/fbfielddef.dart";
export "src/fbdb/fbdb.dart";
export "src/fbclient/fbconsts.dart";
export "src/fbclient/types.dart";
export "src/fbclient/mem.dart";
