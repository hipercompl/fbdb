import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IPluginManager extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(
    FbInterface self,
    int pluginType,
    Pointer<Utf8> defaultName,
    FbInterface plFactory,
  )
  _registerPluginFactory;
  late void Function(FbInterface self, FbInterface cleanup) _registerModule;
  late void Function(FbInterface self, FbInterface cleanup) _unregisterModule;
  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    int pluginType,
    Pointer<Utf8> namesList,
    FbInterface firebirdConf,
  )
  _getPlugins;
  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    Pointer<Utf8> filename,
  )
  _getConfig;
  late void Function(FbInterface self, FbInterface plugin) _releasePlugin;

  IPluginManager(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 6;
    var idx = startIndex;
    _registerPluginFactory =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  UnsignedInt,
                  Pointer<Utf8>,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _registerModule =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _unregisterModule =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getPlugins =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Utf8>,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getConfig =
        Pointer<
              NativeFunction<
                FbInterface Function(FbInterface, FbInterface, Pointer<Utf8>)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _releasePlugin =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  void registerPluginFactory(
    int pluginType,
    String defaultName,
    IPluginFactory plFactory,
  ) {
    final nameUtf = defaultName.toNativeUtf8(allocator: mem);
    try {
      _registerPluginFactory(self, pluginType, nameUtf, plFactory.self);
    } finally {
      mem.free(nameUtf);
    }
  }

  void registerModule(IPluginModule cleanup) {
    _registerModule(self, cleanup.self);
  }

  void unregisterModule(IPluginModule cleanup) {
    _unregisterModule(self, cleanup.self);
  }

  IPluginSet getPlugins(
    IStatus status,
    int pluginType,
    String namesList,
    IFirebirdConf firebirdConf,
  ) {
    final namesUtf = namesList.toNativeUtf8(allocator: mem);
    try {
      final res = _getPlugins(
        self,
        status.self,
        pluginType,
        namesUtf,
        firebirdConf.self,
      );
      status.checkStatus();
      return IPluginSet(res);
    } finally {
      mem.free(namesUtf);
    }
  }

  IConfig getConfig(IStatus status, String fileName) {
    final nameUtf = fileName.toNativeUtf8(allocator: mem);
    try {
      final res = _getConfig(self, status.self, nameUtf);
      status.checkStatus();
      return IConfig(res);
    } finally {
      mem.free(nameUtf);
    }
  }

  void releasePlugin(IPluginBase plugin) {
    _releasePlugin(self, plugin.self);
  }
}
