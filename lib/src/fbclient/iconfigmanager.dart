import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IConfigManager extends IVersioned {
  @override
  int minSupportedVersion() => 3;

  late Pointer<Utf8> Function(FbInterface self, int code) _getDirectory;
  late FbInterface Function(FbInterface self) _getFirebirdConf;
  late FbInterface Function(FbInterface self, Pointer<Utf8> dbName)
      _getDatabaseConf;
  late FbInterface Function(FbInterface self, Pointer<Utf8> configuredPlugin)
      _getPluginConfig;
  late Pointer<Utf8> Function(FbInterface self) _getInstallDirectory;
  late Pointer<Utf8> Function(FbInterface self) _getRootDirectory;
  late Pointer<Utf8> Function(FbInterface self) _getDefaultSecurityDb;

  IConfigManager(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 7;
    var idx = startIndex;
    _getDirectory = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(
                    FbInterface, UnsignedInt)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getFirebirdConf =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _getDatabaseConf = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getPluginConfig = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getInstallDirectory = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getRootDirectory = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getDefaultSecurityDb = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  String getDirectory(int code) {
    return _getDirectory(self, code).toDartString();
  }

  IFirebirdConf getFirebirdConf() {
    return IFirebirdConf(_getFirebirdConf(self));
  }

  IFirebirdConf getDatabaseConf(String dbName) {
    final dbNameUtf = dbName.toNativeUtf8(allocator: mem);
    try {
      return IFirebirdConf(_getDatabaseConf(self, dbNameUtf));
    } finally {
      mem.free(dbNameUtf);
    }
  }

  IConfig getPluginConfig(String configuredPlugin) {
    final pluginUtf = configuredPlugin.toNativeUtf8(allocator: mem);
    try {
      return IConfig(_getPluginConfig(self, pluginUtf));
    } finally {
      mem.free(pluginUtf);
    }
  }

  String getInstallDirectory() {
    return _getInstallDirectory(self).toDartString();
  }

  String getRootDirectory() {
    return _getRootDirectory(self).toDartString();
  }

  String getDefaultSecurityDb() {
    return _getDefaultSecurityDb(self).toDartString();
  }
}
