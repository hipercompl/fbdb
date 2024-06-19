import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IRequest extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late void Function(FbInterface self, FbInterface status, int level,
      int msgType, int length, Pointer<Uint8> message) _receive;
  late void Function(FbInterface self, FbInterface status, int level,
      int msgType, int length, Pointer<Uint8> message) _send;
  late void Function(
      FbInterface self,
      FbInterface status,
      int level,
      int itemsLength,
      Pointer<Uint8> items,
      int bufferLength,
      Pointer<Uint8> buffer) _getInfo;
  late void Function(FbInterface self, FbInterface status,
      FbInterface transaction, int level) _start;
  late void Function(
      FbInterface self,
      FbInterface status,
      FbInterface transaction,
      int level,
      int msgType,
      int length,
      Pointer<Uint8> message) _startAndSend;
  late void Function(FbInterface self, FbInterface status, int level) _unwind;
  late void Function(FbInterface self, FbInterface status) _deprecatedFree;
  late void Function(FbInterface self, FbInterface status) _free;

  IRequest(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 8;
    var idx = startIndex;
    _receive = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Int, UnsignedInt,
                    UnsignedInt, Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _send = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, Int, UnsignedInt,
                    UnsignedInt, Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getInfo = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    Int,
                    UnsignedInt,
                    Pointer<Uint8>,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _start = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface, FbInterface,
                    Int)>>.fromAddress(vtable[idx++])
        .asFunction();
    _startAndSend = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface,
                    FbInterface,
                    FbInterface,
                    Int,
                    UnsignedInt,
                    UnsignedInt,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _unwind = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface, Int)>>.fromAddress(vtable[idx++])
        .asFunction();
    _deprecatedFree = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _free = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  void receive(IStatus status, int level, int msgType, int length,
      Pointer<Uint8> message) {
    _receive(self, status.self, level, msgType, length, message);
    status.checkStatus();
  }

  void send(IStatus status, int level, int msgType, int length,
      Pointer<Uint8> message) {
    _send(self, status.self, level, msgType, length, message);
    status.checkStatus();
  }

  void getInfo(IStatus status, int level, int itemsLength, Pointer<Uint8> items,
      int bufferLength, Pointer<Uint8> buffer) {
    _getInfo(
        self, status.self, level, itemsLength, items, bufferLength, buffer);
    status.checkStatus();
  }

  void start(IStatus status, ITransaction transaction, int level) {
    _start(self, status.self, transaction.self, level);
    status.checkStatus();
  }

  void startAndSend(IStatus status, ITransaction transaction, int level,
      int msgType, int length, Pointer<Uint8> message) {
    _startAndSend(
        self, status.self, transaction.self, level, msgType, length, message);
    status.checkStatus();
  }

  void unwind(IStatus status, int level) {
    _unwind(self, status.self, level);
    status.checkStatus();
  }

  void deprecatedFree(IStatus status) {
    _deprecatedFree(self, status.self);
    status.checkStatus();
  }

  void free(IStatus status) {
    _free(self, status.self);
    status.checkStatus();
  }
}
