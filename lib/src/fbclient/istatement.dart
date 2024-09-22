import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IStatement extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  static const preparePrefetchNone = 0x0;
  static const preparePrefetchType = 0x1;
  static const preparePrefetchInputParameters = 0x2;
  static const preparePrefetchOutputParameters = 0x4;
  static const preparePrefetchLegacyPlan = 0x8;
  static const preparePrefetchDetailedPlan = 0x10;
  static const preparePrefetchAffectedRecords = 0x20;
  static const preparePrefetchFlags = 0x40;
  static const preparePrefetchMetadata = preparePrefetchType |
      preparePrefetchFlags |
      preparePrefetchInputParameters |
      preparePrefetchOutputParameters;
  static const preparePrefetchAll = preparePrefetchMetadata |
      preparePrefetchLegacyPlan |
      preparePrefetchDetailedPlan |
      preparePrefetchAffectedRecords;
  static const flagHasCursor = 0x1;
  static const flagRepeatExecute = 0x2;
  static const cursorTypeScrollable = 0x1;

  late void Function(FbInterface self, FbInterface status, int itemsLength,
      Pointer<Uint8> items, int bufferLength, Pointer<Uint8> buffer) _getInfo;
  late int Function(FbInterface self, FbInterface status) _getType;
  late Pointer<Utf8> Function(
      FbInterface self, FbInterface status, int detailed) _getPlan;
  late int Function(FbInterface self, FbInterface status) _getAffectedRecords;
  late FbInterface Function(FbInterface self, FbInterface status)
      _getInputMetadata;
  late FbInterface Function(FbInterface self, FbInterface status)
      _getOutputMetadata;
  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      FbInterface inMetadata,
      Pointer<Uint8> inBuffer,
      FbInterface outMetadata,
      Pointer<Uint8> outBuffer) _execute;
  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      FbInterface inMetadata,
      Pointer<Uint8> inBuffer,
      FbInterface outMetadata,
      int flags) _openCursor;
  late void Function(FbInterface self, FbInterface status, Pointer<Utf8> name)
      _setCursorName;
  late void Function(FbInterface self, FbInterface status) _deprecatedFree;
  late int Function(FbInterface self, FbInterface status) _getFlags;
  late int Function(FbInterface self, FbInterface status) _getTimeout;
  late void Function(FbInterface self, FbInterface status, int timeout)
      _setTimeout;
  late FbInterface Function(FbInterface self, FbInterface status,
      FbInterface inMetadata, int parLength, Pointer<Uint8> par) _createBatch;
  late void Function(FbInterface self, FbInterface status) _free;

  IStatement(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 15 : 11);
    var idx = startIndex;
    _getInfo = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();

    _getType = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();

    _getPlan = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface, FbInterface,
                    FbBoolean)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getAffectedRecords = Pointer<
            NativeFunction<
                Uint64 Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getInputMetadata = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getOutputMetadata = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _execute = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<Uint8>,
                    FbInterface,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _openCursor = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<Uint8>,
                    FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setCursorName = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    if (version >= 4) {
      _deprecatedFree = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    } else {
      _free = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
    _getFlags = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getTimeout = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setTimeout = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _createBatch = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface,
                    UnsignedInt, Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    if (version >= 4) {
      _free = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
  }

  void getInfo(IStatus status, int itemsLength, Pointer<Uint8> items,
      int bufferLength, Pointer<Uint8> buffer) {
    _getInfo(self, status.self, itemsLength, items, bufferLength, buffer);
    status.checkStatus();
  }

  int getType(IStatus status) {
    final res = _getType(self, status.self);
    status.checkStatus();
    return res;
  }

  String getPlan(IStatus status, bool detailed) {
    final res = _getPlan(self, status.self, detailed ? 1 : 0);
    status.checkStatus();
    return res.toDartString(); // we don't free res - it's a static buffer
  }

  int getAffectedRecords(IStatus status) {
    final res = _getAffectedRecords(self, status.self);
    status.checkStatus();
    return res;
  }

  IMessageMetadata getInputMetadata(IStatus status) {
    final res = _getInputMetadata(self, status.self);
    status.checkStatus();
    return IMessageMetadata(res);
  }

  IMessageMetadata getOutputMetadata(IStatus status) {
    final res = _getOutputMetadata(self, status.self);
    status.checkStatus();
    return IMessageMetadata(res);
  }

  ITransaction execute(IStatus status, ITransaction transaction,
      [IMessageMetadata? inMetadata,
      Pointer<Uint8>? inBuffer,
      IMessageMetadata? outMetadata,
      Pointer<Uint8>? outBuffer]) {
    final res = _execute(
        self,
        status.self,
        transaction.self,
        inMetadata?.self ?? nullptr,
        inBuffer ?? nullptr,
        outMetadata?.self ?? nullptr,
        outBuffer ?? nullptr);
    status.checkStatus();
    return ITransaction(res);
  }

  IResultSet openCursor(IStatus status, ITransaction transaction,
      [IMessageMetadata? inMetadata,
      Pointer<Uint8>? inBuffer,
      IMessageMetadata? outMetadata,
      int flags = 0]) {
    final res = _openCursor(
        self,
        status.self,
        transaction.self,
        inMetadata?.self ?? nullptr,
        inBuffer ?? nullptr,
        outMetadata?.self ?? nullptr,
        flags);
    status.checkStatus();
    return IResultSet(res);
  }

  void setCursorName(IStatus status, String name) {
    final nameUtf = name.toNativeUtf8(allocator: mem);
    try {
      _setCursorName(self, status.self, nameUtf);
      status.checkStatus();
    } finally {
      mem.free(nameUtf);
    }
  }

  void deprecatedFree(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    _deprecatedFree(self, status.self);
    status.checkStatus();
  }

  int getFlags(IStatus status) {
    final res = _getFlags(self, status.self);
    status.checkStatus();
    return res;
  }

  int getTimeout(IStatus status) {
    final res = _getTimeout(self, status.self);
    status.checkStatus();
    return res;
  }

  void setTimeout(IStatus status, int timeout) {
    _setTimeout(self, status.self, timeout);
    status.checkStatus();
  }

  IBatch createBatch(IStatus status,
      [IMessageMetadata? inMetadata, int parLength = 0, Pointer<Uint8>? par]) {
    final res = _createBatch(self, status.self, inMetadata?.self ?? nullptr,
        parLength, par ?? nullptr);
    status.checkStatus();
    return IBatch(res);
  }

  void free(IStatus status) {
    _free(self, status.self);
    status.checkStatus();
  }
}
