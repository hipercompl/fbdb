import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IService extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self, FbInterface status) _deprecatedDetach;
  late void Function(
      FbInterface self,
      FbInterface status,
      int sendLength,
      Pointer<Uint8> sendItems,
      int receiveLength,
      Pointer<Uint8> receiveItems,
      int bufferLength,
      Pointer<Uint8> buffer) _query;
  late void Function(FbInterface self, FbInterface status, int spbLength,
      Pointer<Uint8> spb) _start;
  late void Function(FbInterface self, FbInterface status) _detach;
  late void Function(FbInterface self, FbInterface status) _cancel;

  IService(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 5 : 3);
    var idx = startIndex;
    if (version >= 4) {
      _deprecatedDetach = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    } else {
      _detach = Pointer<
              NativeFunction<
                  Void Function(
                      FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
          .asFunction();
    }
    _query = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _start = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    if (version >= 4) {
      _detach = Pointer<
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
  }

  void deprecatedDetach(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    _deprecatedDetach(self, status.self);
    status.checkStatus();
  }

  void query(
      IStatus status,
      int sendLength,
      Pointer<Uint8> sendItems,
      int receiveLength,
      Pointer<Uint8> receiveItems,
      int bufferLength,
      Pointer<Uint8> buffer) {
    _query(self, status.self, sendLength, sendItems, receiveLength,
        receiveItems, bufferLength, buffer);
    status.checkStatus();
  }

  void start(IStatus status, int spbLength, Pointer<Uint8> spb) {
    _start(self, status.self, spbLength, spb);
    status.checkStatus();
  }

  void detach(IStatus status) {
    _detach(self, status.self);
    status.checkStatus();
  }

  void cancel(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
          "Firebird client library version 4 or later required.");
    }
    _cancel(self, status.self);
    status.checkStatus();
  }
}
