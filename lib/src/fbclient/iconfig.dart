import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IConfig extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late FbInterface Function(
      FbInterface self, FbInterface status, Pointer<Utf8> name) _find;
  late FbInterface Function(FbInterface self, FbInterface status,
      Pointer<Utf8> name, Pointer<Utf8> value) _findValue;
  late FbInterface Function(
          FbInterface self, FbInterface status, Pointer<Utf8> name, int pos)
      _findPos;

  IConfig(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 3;
    var idx = startIndex;
    _find = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface,
                    Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _findValue = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, Pointer<Utf8>,
                    Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _findPos = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, Pointer<Utf8>,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  IConfigEntry find(IStatus status, String name) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      final res = _find(self, status.self, nameUtf);
      status.checkStatus();
      return IConfigEntry(res);
    } finally {
      mem.free(nameUtf);
    }
  }

  IConfigEntry findValue(IStatus status, String name, String value) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      final valueUtf = value.toNativeUtf8(allocator: mem);
      try {
        final res = _findValue(self, status.self, nameUtf, valueUtf);
        status.checkStatus();
        return IConfigEntry(res);
      } finally {
        mem.free(valueUtf);
      }
    } finally {
      mem.free(nameUtf);
    }
  }

  IConfigEntry findPos(IStatus status, String name, int pos) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      final res = _findPos(self, status.self, nameUtf, pos);
      status.checkStatus();
      return IConfigEntry(res);
    } finally {
      mem.free(nameUtf);
    }
  }
}
