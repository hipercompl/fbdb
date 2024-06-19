import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IPluginModule extends IVersioned {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self) _doClean;
  late void Function(FbInterface self) _threadDetach;

  IPluginModule(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _doClean = Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
            vtable[idx++])
        .asFunction();
    _threadDetach =
        Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
  }

  void doClean() {
    _doClean(self);
  }

  void threadDetach() {
    _threadDetach(self);
  }
}
