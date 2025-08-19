import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IBatch extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late void Function(
    FbInterface self,
    FbInterface status,
    int count,
    Pointer<Uint8> inBuffer,
  )
  _add;
  late void Function(
    FbInterface self,
    FbInterface status,
    int length,
    Pointer<Uint8> inBuffer,
    Pointer<IscQuad> blobId,
    int parLength,
    Pointer<Uint8> par,
  )
  _addBlob;
  late void Function(
    FbInterface self,
    FbInterface status,
    int length,
    Pointer<Uint8> inBuffer,
  )
  _appendBlobData;
  late void Function(
    FbInterface self,
    FbInterface status,
    int length,
    Pointer<Uint8> inBuffer,
  )
  _addBlobStream;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscQuad> existingBlob,
    Pointer<IscQuad> blobId,
  )
  _registerBlob;
  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    FbInterface transaction,
  )
  _execute;
  late void Function(FbInterface self, FbInterface status) _cancel;
  late int Function(FbInterface self, FbInterface status) _getBlobAlignment;
  late FbInterface Function(FbInterface self, FbInterface status) _getMetadata;
  late void Function(
    FbInterface self,
    FbInterface status,
    int parLength,
    Pointer<Uint8> par,
  )
  _setDefaultBpb;
  late void Function(FbInterface self, FbInterface status) _deprecatedClose;
  late void Function(FbInterface self, FbInterface status) _close;
  late void Function(
    FbInterface self,
    FbInterface status,
    int itemsLength,
    Pointer<Uint8> items,
    int bufferLength,
    Pointer<Uint8> buffer,
  )
  _getInfo;

  IBatch(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 13;
    var idx = startIndex;
    _add =
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
    _addBlob =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  Pointer<IscQuad>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _appendBlobData =
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
    _addBlobStream =
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
    _registerBlob =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  Pointer<IscQuad>,
                  Pointer<IscQuad>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _execute =
        Pointer<
              NativeFunction<
                FbInterface Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _cancel =
        Pointer<
              NativeFunction<Void Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getBlobAlignment =
        Pointer<
              NativeFunction<UnsignedInt Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getMetadata =
        Pointer<
              NativeFunction<FbInterface Function(FbInterface, FbInterface)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    _setDefaultBpb =
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
    _getInfo =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  void add(IStatus status, int count, Pointer<Uint8> inBuffer) {
    _add(self, status.self, count, inBuffer);
    status.checkStatus();
  }

  void addBlob(
    IStatus status,
    int length,
    Pointer<Uint8> inBuffer,
    Pointer<IscQuad> blobId,
    int parLength,
    Pointer<Uint8> par,
  ) {
    _addBlob(self, status.self, length, inBuffer, blobId, parLength, par);
    status.checkStatus();
  }

  void appendBlobData(IStatus status, int length, Pointer<Uint8> inBuffer) {
    _appendBlobData(self, status.self, length, inBuffer);
    status.checkStatus();
  }

  void addBlobStream(IStatus status, int length, Pointer<Uint8> inBuffer) {
    _addBlobStream(self, status.self, length, inBuffer);
    status.checkStatus();
  }

  void registerBlob(
    IStatus status,
    Pointer<IscQuad> existingBlob,
    Pointer<IscQuad> blobId,
  ) {
    _registerBlob(self, status.self, existingBlob, blobId);
    status.checkStatus();
  }

  IBatchCompletionState execute(IStatus status, ITransaction transaction) {
    final res = _execute(self, status.self, transaction.self);
    status.checkStatus();
    return IBatchCompletionState(res);
  }

  void cancel(IStatus status) {
    _cancel(self, status.self);
    status.checkStatus();
  }

  int getBlobAlignment(IStatus status) {
    final res = _getBlobAlignment(self, status.self);
    status.checkStatus();
    return res;
  }

  IMessageMetadata getMetadata(IStatus status) {
    final res = _getMetadata(self, status.self);
    status.checkStatus();
    return IMessageMetadata(res);
  }

  void setDefaultBpb(IStatus status, int parLength, Pointer<Uint8> par) {
    _setDefaultBpb(self, status.self, parLength, par);
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

  void getInfo(
    IStatus status,
    int itemsLength,
    Pointer<Uint8> items,
    int bufferLength,
    Pointer<Uint8> buffer,
  ) {
    _getInfo(self, status.self, itemsLength, items, bufferLength, buffer);
    status.checkStatus();
  }
}
