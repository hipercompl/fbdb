import "dart:ffi";
import "package:fbdb/fbclient.dart";

class IResultSet extends IReferenceCounted {
  @override
  int minSupportedVersion() => 4;

  late int Function(
      FbInterface self, FbInterface status, Pointer<Uint8> message) _fetchNext;
  late int Function(
      FbInterface self, FbInterface status, Pointer<Uint8> message) _fetchPrior;
  late int Function(
      FbInterface self, FbInterface status, Pointer<Uint8> message) _fetchFirst;
  late int Function(
      FbInterface self, FbInterface status, Pointer<Uint8> message) _fetchLast;
  late int Function(FbInterface self, FbInterface status, int position,
      Pointer<Uint8> message) _fetchAbsolute;
  late int Function(FbInterface self, FbInterface status, int offset,
      Pointer<Uint8> message) _fetchRelative;
  late int Function(FbInterface self, FbInterface status) _isEof;
  late int Function(FbInterface self, FbInterface status) _isBof;
  late FbInterface Function(FbInterface self, FbInterface status) _getMetadata;
  late void Function(FbInterface self, FbInterface status) _deprecatedClose;
  late void Function(FbInterface self, FbInterface status, FbInterface format)
      _setDelayedOutputFormat;
  late void Function(FbInterface self, FbInterface status) _close;

  IResultSet(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 12;
    var idx = startIndex;
    _fetchNext = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fetchPrior = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fetchFirst = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fetchLast = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fetchAbsolute = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface, Int,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _fetchRelative = Pointer<
            NativeFunction<
                Int Function(FbInterface, FbInterface, Int,
                    Pointer<Uint8>)>>.fromAddress(vtable[idx++])
        .asFunction();
    _isEof = Pointer<
            NativeFunction<
                FbBoolean Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _isBof = Pointer<
            NativeFunction<
                FbBoolean Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getMetadata = Pointer<
            NativeFunction<
                FbInterface Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _deprecatedClose = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setDelayedOutputFormat = Pointer<
            NativeFunction<
                Void Function(FbInterface, FbInterface,
                    FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _close = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
  }

  int fetchNext(IStatus status, Pointer<Uint8> message) {
    final res = _fetchNext(self, status.self, message);
    status.checkStatus();
    return res;
  }

  int fetchPrior(IStatus status, Pointer<Uint8> message) {
    final res = _fetchPrior(self, status.self, message);
    status.checkStatus();
    return res;
  }

  int fetchFirst(IStatus status, Pointer<Uint8> message) {
    final res = _fetchFirst(self, status.self, message);
    status.checkStatus();
    return res;
  }

  int fetchLast(IStatus status, Pointer<Uint8> message) {
    final res = _fetchLast(self, status.self, message);
    status.checkStatus();
    return res;
  }

  int fetchAbsolute(IStatus status, int position, Pointer<Uint8> message) {
    final res = _fetchAbsolute(self, status.self, position, message);
    status.checkStatus();
    return res;
  }

  int fetchRelative(IStatus status, int offset, Pointer<Uint8> message) {
    final res = _fetchRelative(self, status.self, offset, message);
    status.checkStatus();
    return res;
  }

  bool isEof(IStatus status) {
    final res = _isEof(self, status.self);
    status.checkStatus();
    return res != 0;
  }

  bool isBof(IStatus status) {
    final res = _isBof(self, status.self);
    status.checkStatus();
    return res != 0;
  }

  IMessageMetadata getMetadata(IStatus status) {
    final res = _getMetadata(self, status.self);
    status.checkStatus();
    return IMessageMetadata(res);
  }

  void deprecatedClose(IStatus status) {
    _deprecatedClose(self, status.self);
    status.checkStatus();
  }

  void setDelayedOutputFormat(IStatus status, IMessageMetadata format) {
    _setDelayedOutputFormat(self, status.self, format.self);
    status.checkStatus();
  }

  void close(IStatus status) {
    _close(self, status.self);
    status.checkStatus();
  }
}
