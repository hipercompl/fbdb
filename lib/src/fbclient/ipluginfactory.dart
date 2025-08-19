import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IPluginFactory extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    FbInterface factoryParameter,
  )
  _createPlugin;

  IPluginFactory(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _createPlugin =
        Pointer<
              NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[startIndex])
            .asFunction();
  }

  IPluginBase createPlugin(IStatus status, IPluginConfig factoryParameter) {
    final res = _createPlugin(self, status.self, factoryParameter.self);
    status.checkStatus();
    return IPluginBase(res);
  }
}
