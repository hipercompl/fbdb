import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IInt128 extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<FbI128> from,
    int bufferLength,
    Pointer<Utf8> buffer,
  )
  _toString;
  late void Function(
    FbInterface self,
    FbInterface status,
    int scale,
    Pointer<Utf8> from,
    Pointer<FbI128> to,
  )
  _fromString;
  IInt128(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 5;
    var idx = startIndex;
    _toString =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  Pointer<FbI128>,
                  UnsignedInt,
                  Pointer<Utf8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _fromString =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  Int,
                  Pointer<Utf8>,
                  Pointer<FbI128>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  String toStr(IStatus status, Pointer<FbI128> from) {
    const slen = 80;
    String s = " " * slen;
    final sUtf = s.toNativeUtf8(allocator: mem);
    try {
      _toString(self, status.self, from, slen, sUtf);
      status.checkStatus();
      return sUtf.toDartString();
    } finally {
      mem.free(sUtf);
    }
  }

  void fromStr(IStatus status, int scale, String from, Pointer<FbI128> to) {
    final fromUtf = from.toNativeUtf8(allocator: mem);
    try {
      _fromString(self, status.self, scale, fromUtf, to);
      status.checkStatus();
    } finally {
      mem.free(fromUtf);
    }
  }
}
