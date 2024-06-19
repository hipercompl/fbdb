import "dart:ffi";
import "package:fbdb/fbclient.dart";

class ITimer extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self) _handler;

  ITimer(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _handler = Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
            vtable[startIndex])
        .asFunction();
  }

  void handler() {
    _handler(self);
  }
}
