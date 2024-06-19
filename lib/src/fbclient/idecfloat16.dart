import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IDecFloat16 extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(FbInterface self, Pointer<FbDec16> from, Pointer<Int> sign,
      Pointer<Uint8> bcd, Pointer<Int> exp) _toBcd;
  late void Function(FbInterface self, FbInterface status,
      Pointer<FbDec16> from, int bufferLength, Pointer<Utf8> buffer) _toString;
  late void Function(FbInterface self, int sign, Pointer<Uint8> bcd, int exp,
      Pointer<FbDec16> to) _fromBcd;
  late void Function(FbInterface self, FbInterface status, Pointer<Utf8> from,
      Pointer<FbDec16> to) _fromString;

  IDecFloat16(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 4;
    var idx = startIndex;
    _toBcd = Pointer<
            NativeFunction<
                Void Function(FbInterface, Pointer<FbDec16>, Pointer<Int>,
                    Pointer<Uint8>, Pointer<Int>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _toString = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Pointer<FbDec16>,
                    UnsignedInt, Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fromBcd = Pointer<
            NativeFunction<
                Void Function(FbInterface, Int, Pointer<Uint8>, Int,
                    Pointer<FbDec16>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fromString = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Pointer<Utf8>,
                    Pointer<FbDec16>)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void toBcd(Pointer<FbDec16> from, Pointer<Int> sign, Pointer<Uint8> bcd,
      Pointer<Int> exp) {
    _toBcd(self, from, sign, bcd, exp);
  }

  String toStr(IStatus status, Pointer<FbDec16> from) {
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

  void fromBcd(int sign, Pointer<Uint8> bcd, int exp, Pointer<FbDec16> to) {
    _fromBcd(self, sign, bcd, exp, to);
  }

  void fromStr(IStatus status, String from, Pointer<FbDec16> to) {
    final fromUtf = from.toNativeUtf8(allocator: mem);
    try {
      _fromString(self, status.self, fromUtf, to);
      status.checkStatus();
    } finally {
      mem.free(fromUtf);
    }
  }
}
