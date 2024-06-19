import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IPluginSet extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late Pointer<Utf8> Function(FbInterface self) _getName;
  late Pointer<Utf8> Function(FbInterface self) _getModuleName;
  late FbInterface Function(FbInterface self, FbInterface status) _getPlugin;
  late void Function(FbInterface self, FbInterface status) _next;
  late void Function(FbInterface self, FbInterface status, Pointer<Utf8> s)
      _set;

  IPluginSet(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 5;
    var idx = startIndex;
    _getName = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getModuleName = Pointer<
            NativeFunction<
                Pointer<Utf8> Function(FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getPlugin = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _next = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _set = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    Pointer<Utf8>)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  String getName() {
    return _getName(self).toDartString();
  }

  String getModuleName() {
    return _getModuleName(self).toDartString();
  }

  IPluginBase getPlugin(IStatus status) {
    final res = _getPlugin(self, status.self);
    status.checkStatus();
    return IPluginBase(res);
  }

  void next(IStatus status) {
    _next(self, status.self);
    status.checkStatus();
  }

  void set(IStatus status, String s) {
    final sUtf = s.toNativeUtf8(allocator: mem);
    try {
      _set(self, status.self, sUtf);
      status.checkStatus();
    } finally {
      mem.free(sUtf);
    }
  }
}
