import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IXpbBuilder extends IDisposable {
  @override
  int minSupportedVersion() => 3;

  static const dpb = 1;
  static const spbAttach = 2;
  static const spbStart = 3;
  static const tpb = 4;
  static const batch = 5;
  static const bpb = 6;
  static const spbSend = 7;
  static const spbReceive = 8;
  static const spbResponse = 9;
  static const infoSend = 10;
  static const infoResponse = 11;

  late void Function(FbInterface self, FbInterface status) _clear;
  late void Function(FbInterface self, FbInterface status) _removeCurrent;
  late void Function(FbInterface self, FbInterface status, int tag, int value)
      _insertInt;
  late void Function(FbInterface self, FbInterface status, int tag, int value)
      _insertBigInt;
  late void Function(FbInterface self, FbInterface status, int tag,
      Pointer<Uint8> bytes, int length) _insertBytes;
  late void Function(
          FbInterface self, FbInterface status, int tag, Pointer<Utf8> str)
      _insertString;
  late void Function(FbInterface self, FbInterface status, int tag) _insertTag;
  late int Function(FbInterface self, FbInterface status) _isEof;
  late void Function(FbInterface self, FbInterface status) _moveNext;
  late void Function(FbInterface self, FbInterface status) _rewind;
  late int Function(FbInterface self, FbInterface status, int tag) _findFirst;
  late int Function(FbInterface self, FbInterface status) _findNext;
  late int Function(FbInterface self, FbInterface status) _getTag;
  late int Function(FbInterface self, FbInterface status) _getLength;
  late int Function(FbInterface self, FbInterface status) _getInt;
  late int Function(FbInterface self, FbInterface status) _getBigInt;
  late Pointer<Utf8> Function(FbInterface self, FbInterface status) _getString;
  late Pointer<Uint8> Function(FbInterface self, FbInterface status) _getBytes;
  late int Function(FbInterface self, FbInterface status) _getBufferLength;
  late Pointer<Uint8> Function(FbInterface self, FbInterface status) _getBuffer;

  IXpbBuilder(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 20;
    var idx = startIndex;
    _clear = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _removeCurrent = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _insertInt = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Uint8,
                    Int)>>.fromAddress(vtable[idx++])
        .asFunction();
    _insertBigInt = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Uint8,
                    Int64)>>.fromAddress(vtable[idx++])
        .asFunction();
    _insertBytes = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Uint8, Pointer<Uint8>,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _insertString = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Uint8,
                    Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _insertTag = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    Uint8)>>.fromAddress(vtable[idx++])
        .asFunction();
    _isEof = Pointer<
            NativeFunction<
                FbBoolean Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _moveNext = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _rewind = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _findFirst = Pointer<
            NativeFunction<
                FbBoolean Function(FbInterface, FbInterface,
                    Uint8)>>.fromAddress(vtable[idx++])
        .asFunction();
    _findNext = Pointer<
            NativeFunction<
                FbBoolean Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getTag = Pointer<
            NativeFunction<
                Uint8 Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getLength = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getInt = Pointer<
            NativeFunction<
                Int Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getBigInt = Pointer<
            NativeFunction<
                Int64 Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getString = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getBytes = Pointer<
            NativeFunction<
                Pointer<Uint8> Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getBufferLength = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getBuffer = Pointer<
            NativeFunction<
                Pointer<Uint8> Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void clear(IStatus status) {
    _clear(self, status.self);
    status.checkStatus();
  }

  void removeCurrent(IStatus status) {
    _removeCurrent(self, status.self);
    status.checkStatus();
  }

  void insertInt(IStatus status, int tag, int value) {
    _insertInt(self, status.self, tag, value);
    status.checkStatus();
  }

  void insertBigInt(IStatus status, int tag, int value) {
    _insertBigInt(self, status.self, tag, value);
    status.checkStatus();
  }

  void insertBytes(IStatus status, int tag, Pointer<Uint8> bytes, int length) {
    _insertBytes(self, status.self, tag, bytes, length);
    status.checkStatus();
  }

  void insertString(IStatus status, int tag, String str) {
    Pointer<Utf8> strUtf = str.toNativeUtf8(allocator: mem);
    try {
      _insertString(self, status.self, tag, strUtf);
      status.checkStatus();
    } finally {
      mem.free(strUtf);
    }
  }

  void insertTag(IStatus status, int tag) {
    _insertTag(self, status.self, tag);
  }

  bool isEof(IStatus status) {
    final res = _isEof(self, status.self) != 0;
    status.checkStatus();
    return res;
  }

  void moveNext(IStatus status) {
    _moveNext(self, status.self);
    status.checkStatus();
  }

  void rewind(IStatus status) {
    _rewind(self, status.self);
    status.checkStatus();
  }

  bool findFirst(IStatus status, int tag) {
    final res = _findFirst(self, status.self, tag) != 0;
    status.checkStatus();
    return res;
  }

  bool findNext(IStatus status) {
    final res = _findNext(self, status.self) != 0;
    status.checkStatus();
    return res;
  }

  int getTag(IStatus status) {
    final res = _getTag(self, status.self);
    status.checkStatus();
    return res;
  }

  int getLength(IStatus status) {
    final res = _getLength(self, status.self);
    status.checkStatus();
    return res;
  }

  int getInt(IStatus status) {
    final res = _getInt(self, status.self);
    status.checkStatus();
    return res;
  }

  int getBigInt(IStatus status) {
    final res = _getBigInt(self, status.self);
    status.checkStatus();
    return res;
  }

  String getString(IStatus status) {
    final strUtf = _getString(self, status.self);
    status.checkStatus();
    return strUtf.toDartString();
    // we don't free strUtf, because it's a static buffer inside IXpbBuilder
    // (we didn't allocate it)
  }

  Pointer<Uint8> getBytes(IStatus status) {
    final res = _getBytes(self, status.self);
    status.checkStatus();
    return res;
  }

  int getBufferLength(IStatus status) {
    final res = _getBufferLength(self, status.self);
    status.checkStatus();
    return res;
  }

  Pointer<Uint8> getBuffer(IStatus status) {
    final res = _getBuffer(self, status.self);
    status.checkStatus();
    return res;
  }
}
