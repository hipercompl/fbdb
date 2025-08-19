import "dart:ffi";
import "package:fbdb/fbclient.dart";

class ICryptKeyCallback extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late int Function(
    FbInterface self,
    int dataLength,
    Pointer<Uint8> data,
    int bufferLength,
    Pointer<Uint8> buffer,
  )
  _callback;

  ICryptKeyCallback(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _callback =
        Pointer<
              NativeFunction<
                UnsignedInt Function(
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[startIndex])
            .asFunction();
  }

  int callback(
    int dataLength,
    Pointer<Uint8> data,
    int bufferLength,
    Pointer<Uint8> buffer,
  ) {
    return _callback(self, dataLength, data, bufferLength, buffer);
  }
}
