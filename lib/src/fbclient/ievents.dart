import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IEvents extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late void Function(FbInterface self, FbInterface status) _deprecatedCancel;
  late void Function(FbInterface self, FbInterface status) _cancel;

  IEvents(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _deprecatedCancel = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _cancel = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void deprecatedCancel(IStatus status) {
    _deprecatedCancel(self, status.self);
    status.checkStatus();
  }

  void cancel(IStatus status) {
    _cancel(self, status.self);
    status.checkStatus();
  }
}
