import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IMetadataBuilder extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self, FbInterface status, int index, int type)
      _setType;
  late void Function(
      FbInterface self, FbInterface status, int index, int subType) _setSubType;
  late void Function(
      FbInterface self, FbInterface status, int index, int length) _setLength;
  late void Function(
      FbInterface self, FbInterface status, int index, int charSet) _setCharSet;
  late void Function(FbInterface self, FbInterface status, int index, int scale)
      _setScale;
  late void Function(FbInterface self, FbInterface status, int count) _truncate;
  late void Function(
          FbInterface self, FbInterface status, Pointer<Utf8> name, int index)
      _moveNameToIndex;
  late void Function(FbInterface self, FbInterface status, int index) _remove;
  late int Function(FbInterface self, FbInterface status) _addField;
  late FbInterface Function(FbInterface self, FbInterface status) _getMetadata;
  late void Function(
          FbInterface self, FbInterface status, int index, Pointer<Utf8> field)
      _setField;
  late void Function(FbInterface self, FbInterface status, int index,
      Pointer<Utf8> relation) _setRelation;
  late void Function(
          FbInterface self, FbInterface status, int index, Pointer<Utf8> owner)
      _setOwner;
  late void Function(
          FbInterface self, FbInterface status, int index, Pointer<Utf8> alias)
      _setAlias;

  IMetadataBuilder(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 14 : 10);
    var idx = startIndex;
    _setType = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setSubType = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setLength = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setCharSet = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setScale = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    Int)>>.fromAddress(vtable[idx++])
        .asFunction();
    _truncate = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _moveNameToIndex = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Pointer<Utf8>,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _remove = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _addField = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getMetadata = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    if (version >= 4) {
      _setField = Pointer<
              NativeFunction<
                  Void Function(FbInterface, FbInterface, UnsignedInt,
                      Pointer<Utf8>)>>.fromAddress(vtable[idx++])
          .asFunction();
      _setRelation = Pointer<
              NativeFunction<
                  Void Function(FbInterface, FbInterface, UnsignedInt,
                      Pointer<Utf8>)>>.fromAddress(vtable[idx++])
          .asFunction();
      _setOwner = Pointer<
              NativeFunction<
                  Void Function(FbInterface, FbInterface, UnsignedInt,
                      Pointer<Utf8>)>>.fromAddress(vtable[idx++])
          .asFunction();
      _setAlias = Pointer<
              NativeFunction<
                  Void Function(FbInterface, FbInterface, UnsignedInt,
                      Pointer<Utf8>)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
  }

  void setType(IStatus status, int index, int type) {
    _setType(self, status.self, index, type);
    status.checkStatus();
  }

  void setSubType(IStatus status, int index, int subType) {
    _setSubType(self, status.self, index, subType);
    status.checkStatus();
  }

  void setLength(IStatus status, int index, int length) {
    _setLength(self, status.self, index, length);
    status.checkStatus();
  }

  void setCharSet(IStatus status, int index, int charSet) {
    _setCharSet(self, status.self, index, charSet);
    status.checkStatus();
  }

  void setScale(IStatus status, int index, int scale) {
    _setScale(self, status.self, index, scale);
    status.checkStatus();
  }

  void truncate(IStatus status, int count) {
    _truncate(self, status.self, count);
    status.checkStatus();
  }

  void moveNameToIndex(IStatus status, String name, int index) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      _moveNameToIndex(self, status.self, nameUtf, index);
      status.checkStatus();
    } finally {
      mem.free(nameUtf);
    }
  }

  void remove(IStatus status, int index) {
    _remove(self, status.self, index);
    status.checkStatus();
  }

  int addField(IStatus status) {
    final res = _addField(self, status.self);
    status.checkStatus();
    return res;
  }

  IMessageMetadata getMetadata(IStatus status) {
    final res = _getMetadata(self, status.self);
    status.checkStatus();
    return IMessageMetadata(res);
  }

  void setField(IStatus status, int index, String field) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final fieldUtf = field.toNativeUtf8(allocator: mem);
    try {
      _setField(self, status.self, index, fieldUtf);
      status.checkStatus();
    } finally {
      mem.free(fieldUtf);
    }
  }

  void setRelation(IStatus status, int index, String relation) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final relationUtf = relation.toNativeUtf8(allocator: mem);
    try {
      _setRelation(self, status.self, index, relationUtf);
      status.checkStatus();
    } finally {
      mem.free(relationUtf);
    }
  }

  void setOwner(IStatus status, int index, String owner) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final ownerUtf = owner.toNativeUtf8(allocator: mem);
    try {
      _setOwner(self, status.self, index, ownerUtf);
      status.checkStatus();
    } finally {
      mem.free(ownerUtf);
    }
  }

  void setAlias(IStatus status, int index, String alias) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    final aliasUtf = alias.toNativeUtf8(allocator: mem);
    try {
      _setAlias(self, status.self, index, aliasUtf);
      status.checkStatus();
    } finally {
      mem.free(aliasUtf);
    }
  }
}
