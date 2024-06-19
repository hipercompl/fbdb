import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IEventCallback extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self, int length, Pointer<Uint8> events)
      _eventCallbackFunction;

  IEventCallback(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _eventCallbackFunction = Pointer<
            NativeFunction<
                Void Function(FbInterface, UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[startIndex])
        .asFunction();
  }

  void eventCallbackFunction(int length, Pointer<Uint8> events) {
    _eventCallbackFunction(self, length, events);
  }
}
