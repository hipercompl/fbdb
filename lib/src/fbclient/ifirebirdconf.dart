import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IFirebirdConf extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late int Function(FbInterface self, Pointer<Utf8> name) _getKey;
  late int Function(FbInterface self, int key) _asInteger;
  late Pointer<Utf8> Function(FbInterface self, int key) _asString;
  late int Function(FbInterface self, int key) _asBoolean;
  late int Function(FbInterface self, FbInterface status) _getVersion;

  IFirebirdConf(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 5;
    var idx = startIndex;
    _getKey = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _asInteger = Pointer<
            NativeFunction<
                Int64 Function(
                    FbInterface, UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _asString = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(
                    FbInterface, UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _asBoolean = Pointer<
            NativeFunction<
                FbBoolean Function(
                    FbInterface, UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getVersion = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  int getKey(String name) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      return _getKey(self, nameUtf);
    } finally {
      mem.free(nameUtf);
    }
  }

  int asInteger(int key) {
    return _asInteger(self, key);
  }

  String asString(int key) {
    return _asString(self, key).toDartString();
  }

  bool asBoolean(int key) {
    return _asBoolean(self, key) != 0;
  }

  int getVersion(IStatus status) {
    final res = _getVersion(self, status.self);
    status.checkStatus();
    return res;
  }
}
