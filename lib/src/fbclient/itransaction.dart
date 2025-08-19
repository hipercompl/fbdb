import "dart:ffi";
import "package:fbdb/fbclient.dart";

class ITransaction extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late final void Function(
    FbInterface self,
    FbInterface status,
    int itemsLength,
    Pointer<Uint8> items,
    int bufferLength,
    Pointer<Uint8> buffer,
  )
  _getInfo;
  late final void Function(
    FbInterface self,
    FbInterface status,
    int msgLength,
    Pointer<Uint8> message,
  )
  _prepare;
  late final void Function(FbInterface self, FbInterface status)
  _deprecatedCommit;
  late final void Function(FbInterface self, FbInterface status)
  _commitRetaining;
  late final void Function(FbInterface self, FbInterface status)
  _deprecatedRollback;
  late final void Function(FbInterface self, FbInterface status)
  _rollbackRetaining;
  late final void Function(FbInterface self, FbInterface status)
  _deprecatedDisconnect;
  late final FbInterface Function(
    FbInterface self,
    FbInterface status,
    FbInterface transaction,
  )
  _join;
  late final FbInterface Function(
    FbInterface self,
    FbInterface status,
    FbInterface attachment,
  )
  _validate;
  late final FbInterface Function(FbInterface self, FbInterface status)
  _enterDtc;
  late final void Function(FbInterface self, FbInterface status) _commit;
  late final void Function(FbInterface self, FbInterface status) _rollback;
  late final void Function(FbInterface self, FbInterface status) _disconnect;

  ITransaction(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 13 : 10);
    var idx = startIndex;
    _getInfo =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _prepare =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _deprecatedCommit =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    } else {
      _commit =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    }
    _commitRetaining =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _deprecatedRollback =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    } else {
      _rollback =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    }
    _rollbackRetaining =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _deprecatedDisconnect =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    } else {
      _disconnect =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    }
    _join =
        Pointer<
              NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _validate =
        Pointer<
              NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _enterDtc =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _commit =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _rollback =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _disconnect =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    }
  }

  void getInfo(
    IStatus status,
    int itemsLength,
    Pointer<Uint8> items,
    int bufferLength,
    Pointer<Uint8> buffer,
  ) {
    _getInfo(self, status.self, itemsLength, items, bufferLength, buffer);
    status.checkStatus();
  }

  void prepare(IStatus status, int msgLength, Pointer<Uint8> message) {
    _prepare(self, status.self, msgLength, message);
    status.checkStatus();
  }

  void deprecatedCommit(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _deprecatedCommit(self, status.self);
    status.checkStatus();
  }

  void commitRetaining(IStatus status) {
    _commitRetaining(self, status.self);
    status.checkStatus();
  }

  void deprecatedRollback(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _deprecatedRollback(self, status.self);
    status.checkStatus();
  }

  void rollbackRetaining(IStatus status) {
    _rollbackRetaining(self, status.self);
    status.checkStatus();
  }

  void deprecatedDisconnect(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _deprecatedDisconnect(self, status.self);
    status.checkStatus();
  }

  ITransaction join(IStatus status, ITransaction transaction) {
    final res = _join(self, status.self, transaction.self);
    status.checkStatus();
    return ITransaction(res);
  }

  ITransaction validate(IStatus status, IAttachment attachment) {
    final res = _validate(self, status.self, attachment.self);
    status.checkStatus();
    return ITransaction(res);
  }

  ITransaction enterDtc(IStatus status) {
    final res = _enterDtc(self, status.self);
    status.checkStatus();
    return ITransaction(res);
  }

  void commit(IStatus status) {
    _commit(self, status.self);
    status.checkStatus();
  }

  void rollback(IStatus status) {
    _rollback(self, status.self);
    status.checkStatus();
  }

  void disconnect(IStatus status) {
    _disconnect(self, status.self);
    status.checkStatus();
  }
}
