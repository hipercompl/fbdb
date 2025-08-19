import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IDtcStart extends IDisposable {
  @override
  int minSupportedVersion() => 3;

  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface attachment,
  )
  _addAttachment;
  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface attachment,
    int length,
    Pointer<Uint8> tpb,
  )
  _addWithTpb;
  late FbInterface Function(FbInterface self, FbInterface status) _start;

  IDtcStart(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 3;
    var idx = startIndex;
    _addAttachment =
        Pointer<
              NativeFunction<
                Void Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _addWithTpb =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _start =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  void addAttachment(IStatus status, IAttachment attachment) {
    _addAttachment(self, status.self, attachment.self);
    status.checkStatus();
  }

  void addWithTpb(
    IStatus status,
    IAttachment attachment,
    int length,
    Pointer<Uint8> tpb,
  ) {
    _addWithTpb(self, status.self, attachment.self, length, tpb);
    status.checkStatus();
  }

  void start(IStatus status) {
    _start(self, status.self);
    status.checkStatus();
  }
}
