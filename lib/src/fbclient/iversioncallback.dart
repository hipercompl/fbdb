import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IVersionCallback extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(FbInterface self, FbInterface status, Pointer<Utf8> text)
  _callback;

  IVersionCallback(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _callback =
        Pointer<
              NativeFunction<
                Void Function(FbInterface, FbInterface, Pointer<Utf8>)
              >
            >.fromAddress(vtable[startIndex])
            .asFunction();
  }

  void callback(IStatus status, String text) {
    final textUtf = text.toNativeUtf8(allocator: mem);
    try {
      _callback(self, status.self, textUtf);
      status.checkStatus();
    } finally {
      mem.free(textUtf);
    }
  }
}
