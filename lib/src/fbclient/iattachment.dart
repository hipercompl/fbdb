import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IAttachment extends IReferenceCounted {
  @override
  int minSupportedVersion() => 5;

  late void Function(FbInterface self, FbInterface status, int itemsLength,
      Pointer<Uint8> items, int bufferLength, Pointer<Uint8> buffer) _getInfo;
  late FbInterface Function(FbInterface self, FbInterface status, int tpbLength,
      Pointer<Uint8> tpb) _startTransaction;
  late FbInterface Function(
          FbInterface self, FbInterface status, int length, Pointer<Uint8> id)
      _reconnectTransaction;
  late FbInterface Function(FbInterface self, FbInterface status, int blrLength,
      Pointer<Uint8> blr) _compileRequest;
  late void Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int blrLength,
      Pointer<Uint8> blr,
      int inMsgLength,
      Pointer<Uint8> inMsg,
      int outMsgLength,
      Pointer<Uint8> outMsg) _transactRequest;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      Pointer<IscQuad> id,
      int bpbLength,
      Pointer<Uint8> bpb) _createBlob;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      Pointer<IscQuad> id,
      int bpbLength,
      Pointer<Uint8> bpb) _openBlob;

  late int Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      Pointer<IscQuad> id,
      int sdlLength,
      Pointer<Uint8> sdl,
      int paramLength,
      Pointer<Uint8> param,
      int sliceLength,
      Pointer<Uint8> slice) _getSlice;

  late void Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      Pointer<IscQuad> id,
      int sdlLength,
      Pointer<Uint8> sdl,
      int paramLength,
      Pointer<Uint8> param,
      int sliceLength,
      Pointer<Uint8> slice) _putSlice;

  late void Function(FbInterface self, FbInterface status,
      FbInterface transaction, int length, Pointer<Uint8> dyn) _executeDyn;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int stmtLength,
      Pointer<Utf8> sqlStmt,
      int dialect,
      int flags) _prepare;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int stmtLength,
      Pointer<Utf8> sqlStmt,
      int dialect,
      FbInterface inMetadata,
      Pointer<Uint8> inBuffer,
      FbInterface outMetadata,
      Pointer<Uint8> outBuffer) _execute;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int stmtLength,
      Pointer<Utf8> sqlStmt,
      int dialect,
      FbInterface inMetadata,
      Pointer<Uint8> inBuffer,
      FbInterface outMetadata,
      Pointer<Utf8> cursorName,
      int cursorFlags) _openCursor;

  late FbInterface Function(FbInterface self, FbInterface status,
      FbInterface callback, int length, Pointer<Uint8> events) _queEvents;

  late void Function(FbInterface self, FbInterface status, int option)
      _cancelOperation;

  late void Function(FbInterface self, FbInterface status) _ping;

  late void Function(FbInterface self, FbInterface status) _deprecatedDetach;

  late void Function(FbInterface self, FbInterface status)
      _deprecatedDropDatabase;

  late int Function(FbInterface self, FbInterface status) _getIdleTimeout;

  late void Function(FbInterface self, FbInterface status, int timeOut)
      _setIdleTimeout;

  late int Function(FbInterface self, FbInterface status) _getStatementTimeout;

  late void Function(FbInterface self, FbInterface status, int timeOut)
      _setStatementTimeout;

  late FbInterface Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int stmtLength,
      Pointer<Utf8> sqlStmt,
      int dialect,
      FbInterface inMetadata,
      int parLength,
      Pointer<Uint8> par) _createBatch;

  late FbInterface Function(FbInterface self, FbInterface status)
      _createReplicator;

  late void Function(FbInterface self, FbInterface status) _detach;

  late void Function(FbInterface self, FbInterface status) _dropDatabase;

  IAttachment(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 26;
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
    _startTransaction = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _reconnectTransaction = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _compileRequest = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _transactRequest = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _createBlob = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<IscQuad>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _openBlob = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<IscQuad>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getSlice = Pointer<
            NativeFunction<
                Int Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<IscQuad>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    Int,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _putSlice = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Pointer<IscQuad>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    Int,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _executeDyn = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, FbInterface,
                    UnsignedInt, Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _prepare = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Utf8>,
                    UnsignedInt,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _execute = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Utf8>,
                    UnsignedInt,
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
                    UnsignedInt,
                    Pointer<Utf8>,
                    UnsignedInt,
                    FbInterface,
                    Pointer<Uint8>,
                    FbInterface,
                    Pointer<Utf8>,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _queEvents = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface,
                    UnsignedInt, Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _cancelOperation = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface, Int)>>.fromAddress(vtable[idx++])
        .asFunction();
    _ping = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _deprecatedDetach = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _deprecatedDropDatabase = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getIdleTimeout = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setIdleTimeout = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getStatementTimeout = Pointer<
            NativeFunction<
                UnsignedInt Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setStatementTimeout = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _createBatch = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Utf8>,
                    UnsignedInt,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _createReplicator = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _detach = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _dropDatabase = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void getInfo(IStatus status, int itemsLength, Pointer<Uint8> items,
      int bufferLength, Pointer<Uint8> buffer) {
    _getInfo(self, status.self, itemsLength, items, bufferLength, buffer);
    status.checkStatus();
  }

  ITransaction startTransaction(IStatus status,
      [int tpbLength = 0, Pointer<Uint8>? tpb]) {
    final res = _startTransaction(self, status.self, tpbLength, tpb ?? nullptr);
    status.checkStatus();
    return ITransaction(res);
  }

  ITransaction reconnectTransaction(IStatus status,
      [int length = 0, Pointer<Uint8>? id]) {
    final res = _reconnectTransaction(self, status.self, length, id ?? nullptr);
    status.checkStatus();
    return ITransaction(res);
  }

  IRequest compileRequest(IStatus status, int blrLength, Pointer<Uint8> blr) {
    final res = _compileRequest(self, status.self, blrLength, blr);
    status.checkStatus();
    return IRequest(res);
  }

  void transactRequest(IStatus status, ITransaction transaction, int blrLength,
      Pointer<Uint8> blr,
      [int inMsgLength = 0,
      Pointer<Uint8>? inMsg,
      int outMsgLength = 0,
      Pointer<Uint8>? outMsg]) {
    _transactRequest(self, status.self, transaction.self, blrLength, blr,
        inMsgLength, inMsg ?? nullptr, outMsgLength, outMsg ?? nullptr);
    status.checkStatus();
  }

  IBlob createBlob(
      IStatus status, ITransaction transaction, Pointer<IscQuad> id,
      [int bpbLength = 0, Pointer<Uint8>? bpb]) {
    final res = _createBlob(
        self, status.self, transaction.self, id, bpbLength, bpb ?? nullptr);
    status.checkStatus();
    return IBlob(res);
  }

  IBlob openBlob(IStatus status, ITransaction transaction, Pointer<IscQuad> id,
      [int bpbLength = 0, Pointer<Uint8>? bpb]) {
    final res = _openBlob(
        self, status.self, transaction.self, id, bpbLength, bpb ?? nullptr);
    status.checkStatus();
    return IBlob(res);
  }

  int getSlice(
      IStatus status,
      ITransaction transaction,
      Pointer<IscQuad> id,
      int sdlLength,
      Pointer<Uint8> sdl,
      int paramLength,
      Pointer<Uint8> param,
      int sliceLength,
      Pointer<Uint8> slice) {
    final res = _getSlice(self, status.self, transaction.self, id, sdlLength,
        sdl, paramLength, param, sliceLength, slice);
    status.checkStatus();
    return res;
  }

  void putSlice(
      IStatus status,
      ITransaction transaction,
      Pointer<IscQuad> id,
      int sdlLength,
      Pointer<Uint8> sdl,
      int paramLength,
      Pointer<Uint8> param,
      int sliceLength,
      Pointer<Uint8> slice) {
    _putSlice(self, status.self, transaction.self, id, sdlLength, sdl,
        paramLength, param, sliceLength, slice);
    status.checkStatus();
  }

  void executeDyn(IStatus status, ITransaction transaction, int length,
      Pointer<Uint8> dyn) {
    _executeDyn(self, status.self, transaction.self, length, dyn);
    status.checkStatus();
  }

  IStatement prepare(IStatus status, ITransaction transaction, String sqlStmt,
      [int dialect = FbConsts.sqlDialectCurrent, int flags = 0]) {
    final sqlUtf = sqlStmt.toNativeUtf8(allocator: mem);
    try {
      final res = _prepare(
          self, status.self, transaction.self, 0, sqlUtf, dialect, flags);
      status.checkStatus();
      return IStatement(res);
    } finally {
      mem.free(sqlUtf);
    }
  }

  ITransaction execute(IStatus status, ITransaction transaction, String sqlStmt,
      [int dialect = FbConsts.sqlDialectCurrent,
      IMessageMetadata? inMetadata,
      Pointer<Uint8>? inBuffer,
      IMessageMetadata? outMetadata,
      Pointer<Uint8>? outBuffer]) {
    final stmtUtf = sqlStmt.toNativeUtf8(allocator: mem);
    try {
      final res = _execute(
          self,
          status.self,
          transaction.self,
          0,
          stmtUtf,
          dialect,
          inMetadata?.self ?? nullptr,
          inBuffer ?? nullptr,
          outMetadata?.self ?? nullptr,
          outBuffer ?? nullptr);
      status.checkStatus();
      return ITransaction(res);
    } finally {
      mem.free(stmtUtf);
    }
  }

  IResultSet openCursor(
      IStatus status, ITransaction transaction, String sqlStmt,
      [int dialect = FbConsts.sqlDialectCurrent,
      IMessageMetadata? inMetadata,
      Pointer<Uint8>? inBuffer,
      IMessageMetadata? outMetadata,
      String? cursorName,
      int cursorFlags = 0]) {
    final sqlUtf = sqlStmt.toNativeUtf8(allocator: mem);
    try {
      final nameUtf = cursorName?.toNativeUtf8(allocator: mem) ?? nullptr;
      try {
        final res = _openCursor(
            self,
            status.self,
            transaction.self,
            0,
            sqlUtf,
            dialect,
            inMetadata?.self ?? nullptr,
            inBuffer ?? nullptr,
            outMetadata?.self ?? nullptr,
            nameUtf,
            cursorFlags);
        status.checkStatus();
        return IResultSet(res);
      } finally {
        if (nameUtf != nullptr) {
          mem.free(nameUtf);
        }
      }
    } finally {
      mem.free(sqlUtf);
    }
  }

  IEvents queEvents(IStatus status, IEventCallback callback, int length,
      Pointer<Uint8> events) {
    final res = _queEvents(self, status.self, callback.self, length, events);
    status.checkStatus();
    return IEvents(res);
  }

  void cancelOperation(IStatus status, [int option = 0]) {
    _cancelOperation(self, status.self, option);
    status.checkStatus();
  }

  void ping(IStatus status) {
    _ping(self, status.self);
    status.checkStatus();
  }

  void deprecatedDetach(IStatus status) {
    _deprecatedDetach(self, status.self);
    status.checkStatus();
  }

  void deprecatedDropDatabase(IStatus status) {
    _deprecatedDropDatabase(self, status.self);
    status.checkStatus();
  }

  int getIdleTimeout(IStatus status) {
    final res = _getIdleTimeout(self, status.self);
    status.checkStatus();
    return res;
  }

  void setIdleTimeout(IStatus status, int timeOut) {
    _setIdleTimeout(self, status.self, timeOut);
    status.checkStatus();
  }

  int getStatementTimeout(IStatus status) {
    final res = _getStatementTimeout(self, status.self);
    status.checkStatus();
    return res;
  }

  void setStatementTimeout(IStatus status, int timeOut) {
    _setStatementTimeout(self, status.self, timeOut);
    status.checkStatus();
  }

  IBatch createBatch(IStatus status, ITransaction transaction, String sqlStmt,
      [int dialect = FbConsts.sqlDialectCurrent,
      IMessageMetadata? inMetadata,
      int parLength = 0,
      Pointer<Uint8>? par]) {
    final sqlUtf = sqlStmt.toNativeUtf8(allocator: mem);
    try {
      final res = _createBatch(self, status.self, transaction.self, 0, sqlUtf,
          dialect, inMetadata?.self ?? nullptr, parLength, par ?? nullptr);
      status.checkStatus();
      return IBatch(res);
    } finally {
      mem.free(sqlUtf);
    }
  }

  IReplicator createReplicator(IStatus status) {
    final res = _createReplicator(self, status.self);
    status.checkStatus();
    return IReplicator(res);
  }

  void detach(IStatus status) {
    _detach(self, status.self);
    status.checkStatus();
  }

  void dropDatabase(IStatus status) {
    _dropDatabase(self, status.self);
    status.checkStatus();
  }
}
