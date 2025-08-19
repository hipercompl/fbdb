import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IConfigEntry extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late Pointer<Utf8> Function(FbInterface self) _getName;
  late Pointer<Utf8> Function(FbInterface self) _getValue;
  late int Function(FbInterface self) _getIntValue;
  late int Function(FbInterface self) _getBoolValue;
  late FbInterface Function(FbInterface self, FbInterface status) _getSubConfig;

  IConfigEntry(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 5;
    var idx = startIndex;
    _getName =
        Pointer<
              NativeFunction<Pointer<Utf8> Function(FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getValue =
        Pointer<
              NativeFunction<Pointer<Utf8> Function(FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getIntValue =
        Pointer<NativeFunction<Int64 Function(FbInterface)>>.fromAddress(
          vtable[idx++],
        ).asFunction();
    _getBoolValue =
        Pointer<NativeFunction<FbBoolean Function(FbInterface)>>.fromAddress(
          vtable[idx++],
        ).asFunction();
    _getSubConfig =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  String getName() {
    return _getName(self).toDartString();
  }

  String getValue() {
    return _getValue(self).toDartString();
  }

  int getIntValue() {
    return _getIntValue(self);
  }

  bool getBoolValue() {
    return _getBoolValue(self) != 0;
  }

  IConfig getSubConfig(IStatus status) {
    final res = _getSubConfig(self, status.self);
    status.checkStatus();
    return IConfig(res);
  }
}
