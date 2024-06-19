import "dart:ffi";

import "package:fbdb/fbclient.dart";

/// The master interface, which is an entry point to all other
/// specialized interfaces.
class IMaster extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late FbInterface Function(FbInterface self) _getStatus;
  late FbInterface Function(FbInterface self) _getDispatcher;
  late FbInterface Function(FbInterface self) _getPluginManager;
  late FbInterface Function(FbInterface self) _getTimerControl;
  late FbInterface Function(FbInterface self) _getDtc;
  late FbInterface Function(
          FbInterface self, FbInterface provider, FbInterface attachment)
      _registerAttachment;
  late FbInterface Function(
          FbInterface self, FbInterface provider, FbInterface transaction)
      _registerTransaction;
  late FbInterface Function(
      FbInterface self, FbInterface status, int fieldCount) _getMetadataBuilder;
  late int Function(FbInterface self, int mode) _serverMode;
  late FbInterface Function(FbInterface self) _getUtilInterface;
  late FbInterface Function(FbInterface self) _getConfigManager;
  late int Function(FbInterface self) _getProcessExiting;

  /// Construct a wrapper around the native IMaster interface.
  /// The [self] argument should be the raw pointer returned by
  /// [FbClient.fbGetMasterInterface] method.
  IMaster(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 12;
    var idx = startIndex;
    _getStatus =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getDispatcher =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getPluginManager =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getTimerControl =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getDtc =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _registerAttachment = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface,
                    FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _registerTransaction = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface,
                    FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getMetadataBuilder = Pointer<
            NativeFunction<
                FbInterface Function(FbInterface, FbInterface,
                    UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _serverMode =
        Pointer<NativeFunction<Int Function(FbInterface, Int)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getUtilInterface =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getConfigManager =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getProcessExiting =
        Pointer<NativeFunction<FbBoolean Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
  }

  /// Allocate and return a new IStatus interface.
  /// When no longer needed, it should be disposed of (by calling dispose).
  IStatus getStatus() {
    return IStatus(_getStatus(self));
  }

  IProvider getDispatcher() {
    return IProvider(_getDispatcher(self));
  }

  IProvider getProvider() {
    return getDispatcher();
  }

  IPluginManager getPluginManager() {
    return IPluginManager(_getPluginManager(self));
  }

  ITimerControl getTimerControl() {
    return ITimerControl(_getTimerControl(self));
  }

  IDtc getDtc() {
    return IDtc(_getDtc(self));
  }

  IAttachment registerAttachment(IProvider provider, IAttachment attachment) {
    return IAttachment(
        _registerAttachment(self, provider.self, attachment.self));
  }

  ITransaction registerTransaction(
      IProvider provider, ITransaction transaction) {
    return ITransaction(
        _registerTransaction(self, provider.self, transaction.self));
  }

  IMetadataBuilder getMetadataBuilder(IStatus status, [int fieldCount = 0]) {
    final res = _getMetadataBuilder(self, status.self, fieldCount);
    status.checkStatus();
    return IMetadataBuilder(res);
  }

  int serverMode(int mode) {
    return _serverMode(self, mode);
  }

  IUtil getUtilInterface() {
    return IUtil(_getUtilInterface(self));
  }

  IConfigManager getConfigManager() {
    return IConfigManager(_getConfigManager(self));
  }

  bool getProcessExiting() {
    return _getProcessExiting(self) != 0;
  }
}
