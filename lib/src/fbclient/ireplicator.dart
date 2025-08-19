import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IReplicator extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late void Function(
    FbInterface self,
    FbInterface status,
    int length,
    Pointer<Uint8> data,
  )
  _process;
  late void Function(FbInterface self, FbInterface status) _deprecatedClose;
  late void Function(FbInterface self, FbInterface status) _close;

  IReplicator(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 3;
    var idx = startIndex;
    _process =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _deprecatedClose =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _close =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  void process(IStatus status, int length, Pointer<Uint8> data) {
    _process(self, status.self, length, data);
    status.checkStatus();
  }

  void deprecatedClose(IStatus status) {
    _deprecatedClose(self, status.self);
    status.checkStatus();
  }

  void close(IStatus status) {
    _close(self, status.self);
    status.checkStatus();
  }
}
