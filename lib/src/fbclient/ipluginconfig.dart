import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IPluginConfig extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late Pointer<Utf8> Function(FbInterface self) _getConfigFileName;
  late FbInterface Function(FbInterface self, FbInterface status)
  _getDefaultConfig;
  late FbInterface Function(FbInterface self, FbInterface status)
  _getFirebirdConf;
  late void Function(FbInterface self, FbInterface status, int microSeconds)
  _setReleaseDelay;

  IPluginConfig(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 4;
    var idx = startIndex;
    _getConfigFileName =
        Pointer<
              NativeFunction<Pointer<Utf8> Function(FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getDefaultConfig =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getFirebirdConf =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _setReleaseDelay =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface, Uint64)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  String getConfigFileName() {
    return _getConfigFileName(self).toDartString();
  }

  IConfig getDefaultConfig(IStatus status) {
    final res = _getDefaultConfig(self, status.self);
    status.checkStatus();
    return IConfig(res);
  }

  IFirebirdConf getFirebirdConf(IStatus status) {
    final res = _getFirebirdConf(self, status.self);
    status.checkStatus();
    return IFirebirdConf(res);
  }

  void setReleaseDelay(IStatus status, int microSeconds) {
    _setReleaseDelay(self, status.self, microSeconds);
    status.checkStatus();
  }
}
