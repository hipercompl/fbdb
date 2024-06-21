import "dart:io";
import "dart:ffi";
import "package:fbdb/fbclient.dart";

/// Encapsulates the native Firebird client library.
///
/// This class serves both as a native library loader and an entry
/// point to obtain the main Firebird client interface: IMaster.
/// All other interfaces can be obtained via the master interface.
class FbClient {
  /// Firebird client native dynamic library handle.
  DynamicLibrary? lib;

  /// The binding to the fb_get_master_interface native function.
  late final FbInterface Function() _fbGetMasterInterface;

  /// The binding to the isc_vax_integer native function.
  late final int Function(Pointer<Uint8> buf, int byteCnt) _iscVaxInteger;

  /// Opens the Firebird client dynamic library and retrieve the
  /// reference to fb_get_master_interface function.
  ///
  /// Optionally, a path to the libfbclient dynamic library
  /// can be provided in [fbLibPath]. If omitted, a mechanism
  /// default for the current OS will be used to resolve the
  /// location of libfbclient.
  FbClient([String? fbLibPath]) {
    fbLibPath ??= locateFbClient();
    lib = DynamicLibrary.open(fbLibPath);
    if (lib == null) {
      throw FbClientException("Cannot open $fbLibPath");
    }
    _fbGetMasterInterface = lib!
        .lookup<NativeFunction<FbInterface Function()>>(
            "fb_get_master_interface")
        .asFunction();
    _iscVaxInteger = lib!
        .lookup<NativeFunction<Long Function(Pointer<Uint8>, Short)>>(
            "isc_vax_integer")
        .asFunction();
  }

  /// Closes the dynamic library.
  void close() {
    if (lib != null) {
      lib?.close();
      lib = null;
    }
  }

  /// Gets the master interface, which allows to access all other
  /// client functionality.
  IMaster fbGetMasterInterface() {
    if (lib == null) {
      throw FbClientException(
          "Firebird client library not loaded or client already closed.");
    }
    final m = _fbGetMasterInterface();
    if (m == nullptr) {
      throw FbClientException(
          "Cannot access the master interface (NULL returned "
          "by fb_get_master_interface).");
    }
    return IMaster(m);
  }

  /// Deduces the location of the fbclient library.
  ///
  /// First it tries to find the library in the current directory,
  /// with the library file name specific to the platform
  /// (libfbclient.so on Linux, fbclient.dll on Windows,
  /// libfbclient.dylib on Mac). If it is found, returns
  /// the path starting with the current directory ("./").
  /// If the file is not found, it tries to locate the "fb"
  /// subdirectory and find the library file there.
  /// If found, the "./fb/libraryfile" will be returned.
  /// If both of the above fail, it returns just the library
  /// file name, to be located by the OS default resolver.
  String locateFbClient([String version = ""]) {
    final libName = _libName(version);
    var res = libName;
    if (FileSystemEntity.isFileSync(".$dirSep$libName")) {
      res = ".$dirSep$libName";
    } else if (FileSystemEntity.isDirectorySync(".${dirSep}fb")) {
      if (FileSystemEntity.isFileSync(".${dirSep}fb$dirSep$libName")) {
        res = ".${dirSep}fb$dirSep$libName";
      }
    }
    return res;
  }

  /// Converts a fragment of a native buffer to a platform-specific integer.
  ///
  /// Integer values returned by Firebird are encoded as so-called
  /// "VAX" integers, which use little endian representation
  /// that is platform independent.
  /// [iscVaxInteger] takes a byte sequence of length [byteCnt]
  /// from the [buffer], starting at [offset], and converts it from "VAX"
  /// representation to a native integer (valid for the current platform).
  int iscVaxInteger(Pointer<Uint8> buffer, int byteCnt, [int offset = 0]) {
    return _iscVaxInteger(
        Pointer<Uint8>.fromAddress(buffer.address + offset), byteCnt);
  }

  /// The name of the libfbclient dynamic library, system dependent.
  static String _libName([String version = ""]) {
    var lname = "libfbclient$version.so";
    if (Platform.isMacOS) {
      lname = "libfbclient$version.dylib";
    } else if (Platform.isWindows) {
      lname = "fbclient$version.dll";
    }
    return lname;
  }

  /// Directory separator, platform-dependent.
  ///
  /// This attribute is defined as backslash ("\") on Windows
  /// and forwart slash ("/") on all other platforms
  /// (which are Unix-based).
  static final String dirSep = Platform.isWindows ? "\\" : "/";
}
