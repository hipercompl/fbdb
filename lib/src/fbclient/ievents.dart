import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IEvents extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self, FbInterface status) _deprecatedCancel;
  late void Function(FbInterface self, FbInterface status) _cancel;

  IEvents(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 2 : 1);
    var idx = startIndex;
    if (version >= 4) {
      _deprecatedCancel = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
    _cancel = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void deprecatedCancel(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    _deprecatedCancel(self, status.self);
    status.checkStatus();
  }

  void cancel(IStatus status) {
    _cancel(self, status.self);
    status.checkStatus();
  }
}
