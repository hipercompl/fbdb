import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IMessageMetadata extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late int Function(FbInterface self, FbInterface status) _getCount;
  late Pointer<Utf8> Function(FbInterface self, FbInterface status, int index)
      _getField;
  late Pointer<Utf8> Function(FbInterface self, FbInterface status, int index)
      _getRelation;
  late Pointer<Utf8> Function(FbInterface self, FbInterface status, int index)
      _getOwner;
  late Pointer<Utf8> Function(FbInterface self, FbInterface status, int index)
      _getAlias;
  late int Function(FbInterface self, FbInterface status, int index) _getType;
  late int Function(FbInterface self, FbInterface status, int index)
      _isNullable;
  late int Function(FbInterface self, FbInterface status, int index)
      _getSubType;
  late int Function(FbInterface self, FbInterface status, int index) _getLength;
  late int Function(FbInterface self, FbInterface status, int index) _getScale;
  late int Function(FbInterface self, FbInterface status, int index)
      _getCharSet;
  late int Function(FbInterface self, FbInterface status, int index) _getOffset;
  late int Function(FbInterface self, FbInterface status, int index)
      _getNullOffset;
  late FbInterface Function(FbInterface self, FbInterface status) _getBuilder;
  late int Function(FbInterface self, FbInterface status) _getMessageLength;
  late int Function(FbInterface self, FbInterface status) _getAlignment;
  late int Function(FbInterface self, FbInterface status) _getAlignedLength;
  IMessageMetadata(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 17 : 15);
    var idx = startIndex;
    _getCount = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getField = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getRelation = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getOwner = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getAlias = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getType = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _isNullable = Pointer<
            NativeFunction<
                FbBoolean Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getSubType = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getLength = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getScale = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getCharSet = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getOffset = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getNullOffset = Pointer<
            NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getBuilder = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getMessageLength = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    if (version >= 4) {
      _getAlignment = Pointer<
              NativeFunction<
                  UnsignedInt Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
      _getAlignedLength = Pointer<
              NativeFunction<
                  UnsignedInt Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
  }

  int getCount(IStatus status) {
    final res = _getCount(self, status.self);
    status.checkStatus();
    return res;
  }

  String getField(IStatus status, int index) {
    final res = _getField(self, status.self, index);
    status.checkStatus();
    return res.toDartString(); // we don't free res, it's a static buffer
  }

  String getRelation(IStatus status, int index) {
    final res = _getRelation(self, status.self, index);
    status.checkStatus();
    return res.toDartString(); // we don't free res, it's a static buffer
  }

  String getOwner(IStatus status, int index) {
    final res = _getOwner(self, status.self, index);
    status.checkStatus();
    return res.toDartString(); // we don't free res, it's a static buffer
  }

  String getAlias(IStatus status, int index) {
    final res = _getAlias(self, status.self, index);
    status.checkStatus();
    return res.toDartString(); // we don't free res, it's a static buffer
  }

  int getType(IStatus status, int index) {
    final res = _getType(self, status.self, index);
    status.checkStatus();
    return res;
  }

  bool isNullable(IStatus status, int index) {
    final res = _isNullable(self, status.self, index);
    status.checkStatus();
    return res != 0;
  }

  int getSubType(IStatus status, int index) {
    final res = _getSubType(self, status.self, index);
    status.checkStatus();
    return res;
  }

  int getLength(IStatus status, int index) {
    final res = _getLength(self, status.self, index);
    status.checkStatus();
    return res;
  }

  int getScale(IStatus status, int index) {
    final res = _getScale(self, status.self, index);
    status.checkStatus();
    return res;
  }

  int getCharSet(IStatus status, int index) {
    final res = _getCharSet(self, status.self, index);
    status.checkStatus();
    return res;
  }

  int getOffset(IStatus status, int index) {
    final res = _getOffset(self, status.self, index);
    status.checkStatus();
    return res;
  }

  int getNullOffset(IStatus status, int index) {
    final res = _getNullOffset(self, status.self, index);
    status.checkStatus();
    return res;
  }

  IMetadataBuilder getBuilder(IStatus status) {
    final res = _getBuilder(self, status.self);
    status.checkStatus();
    return IMetadataBuilder(res);
  }

  int getMessageLength(IStatus status) {
    final res = _getMessageLength(self, status.self);
    status.checkStatus();
    return res;
  }

  int getAlignment(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final res = _getAlignment(self, status.self);
    status.checkStatus();
    return res;
  }

  int getAlignedLength(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final res = _getAlignedLength(self, status.self);
    status.checkStatus();
    return res;
  }
}
