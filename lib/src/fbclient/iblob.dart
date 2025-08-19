import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IBlob extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(
    FbInterface self,
    FbInterface status,
    int itemsLength,
    Pointer<Uint8> items,
    int bufferLength,
    Pointer<Uint8> buffer,
  )
  _getInfo;
  late int Function(
    FbInterface self,
    FbInterface status,
    int bufferLength,
    Pointer<Uint8> buffer,
    Pointer<UnsignedInt> segmentLength,
  )
  _getSegment;
  late void Function(
    FbInterface self,
    FbInterface status,
    int length,
    Pointer<Uint8> buffer,
  )
  _putSegment;
  late void Function(FbInterface self, FbInterface status) _deprecatedCancel;
  late void Function(FbInterface self, FbInterface status) _deprecatedClose;
  late int Function(FbInterface self, FbInterface status, int mode, int offset)
  _seek;
  late void Function(FbInterface self, FbInterface status) _cancel;
  late void Function(FbInterface self, FbInterface status) _close;

  IBlob(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 8 : 6);
    var idx = startIndex;
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
    _getSegment =
        Pointer<
              NativeFunction<
                Int Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  Pointer<UnsignedInt>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _putSegment =
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
    if (version >= 4) {
      _deprecatedCancel =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _deprecatedClose =
          Pointer<
                NativeFunction<Void Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
    } else {
      _cancel =
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
    _seek =
        Pointer<
              NativeFunction<Int Function(FbInterface, FbInterface, Int, Int)>
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _cancel =
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

  int getSegment(
    IStatus status,
    int bufferLength,
    Pointer<Uint8> buffer,
    Pointer<UnsignedInt> segmentLength,
  ) {
    final res = _getSegment(
      self,
      status.self,
      bufferLength,
      buffer,
      segmentLength,
    );
    status.checkStatus();
    return res;
  }

  void putSegment(IStatus status, int length, Pointer<Uint8> buffer) {
    _putSegment(self, status.self, length, buffer);
    status.checkStatus();
  }

  void deprecatedCancel(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _deprecatedCancel(self, status.self);
    status.checkStatus();
  }

  void deprecatedClose(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _deprecatedClose(self, status.self);
    status.checkStatus();
  }

  int seek(IStatus status, int mode, int offset) {
    final res = _seek(self, status.self, mode, offset);
    status.checkStatus();
    return res;
  }

  void cancel(IStatus status) {
    _cancel(self, status.self);
    status.checkStatus();
  }

  void close(IStatus status) {
    _close(self, status.self);
    status.checkStatus();
  }
}
