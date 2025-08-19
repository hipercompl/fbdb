import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IDtc extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    FbInterface transactionOne,
    FbInterface transactionTwo,
  )
  _join;
  late FbInterface Function(FbInterface self, FbInterface status) _startBuilder;

  IDtc(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _join =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _startBuilder =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  ITransaction join(IStatus status, ITransaction one, ITransaction two) {
    final res = _join(self, status.self, one.self, two.self);
    status.checkStatus();
    return ITransaction(res);
  }

  IDtcStart startBuilder(IStatus status) {
    final res = _startBuilder(self, status.self);
    status.checkStatus();
    return IDtcStart(res);
  }
}
