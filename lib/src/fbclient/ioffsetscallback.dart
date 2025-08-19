import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IOffsetsCallback extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(
    FbInterface self,
    FbInterface status,
    int index,
    int offset,
    int nullOffset,
  )
  _setOffset;

  IOffsetsCallback(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _setOffset =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  UnsignedInt,
                  UnsignedInt,
                )
              >
            >.fromAddress(vtable[startIndex])
            .asFunction();
  }

  void setOffset(IStatus status, int index, int offset, int nullOffset) {
    _setOffset(self, status.self, index, offset, nullOffset);
    status.checkStatus();
  }
}
