import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IBatchCompletionState extends IDisposable {
  @override
  int minSupportedVersion() => 3;

  late int Function(FbInterface self, FbInterface status) _getSize;
  late int Function(FbInterface self, FbInterface status, int pos) _getState;
  late int Function(FbInterface self, FbInterface status, int pos) _findError;
  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface to,
    int pos,
  )
  _getStatus;

  IBatchCompletionState(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 4;
    var idx = startIndex;
    _getSize =
        Pointer<
              NativeFunction<UnsignedInt Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getState =
        Pointer<
              NativeFunction<
                Int Function(FbInterface, FbInterface, UnsignedInt)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _findError =
        Pointer<
              NativeFunction<
                UnsignedInt Function(FbInterface, FbInterface, UnsignedInt)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getStatus =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  int getSize(IStatus status) {
    final res = _getSize(self, status.self);
    status.checkStatus();
    return res;
  }

  int getState(IStatus status, int pos) {
    final res = _getState(self, status.self, pos);
    status.checkStatus();
    return res;
  }

  int findError(IStatus status, int pos) {
    final res = _findError(self, status.self, pos);
    status.checkStatus();
    return res;
  }

  void getStatus(IStatus status, IStatus to, int pos) {
    _getStatus(self, status.self, to.self, pos);
    status.checkStatus();
  }
}
