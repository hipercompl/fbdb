import "dart:ffi";
import "package:fbdb/fbclient.dart";

class ITimerControl extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(FbInterface self, FbInterface status, FbInterface timer,
      int microSeconds) _start;
  late void Function(FbInterface self, FbInterface status, FbInterface timer)
      _stop;

  ITimerControl(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _start = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, FbInterface,
                    Uint64)>>.fromAddress(vtable[idx++])
        .asFunction();
    _stop = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void start(IStatus status, ITimer timer, int microSeconds) {
    _start(self, status.self, timer.self, microSeconds);
    status.checkStatus();
  }

  void stop(IStatus status, ITimer timer) {
    _stop(self, status.self, timer.self);
    status.checkStatus();
  }
}
