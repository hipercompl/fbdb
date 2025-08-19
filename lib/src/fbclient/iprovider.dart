import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IProvider extends IPluginBase {
  @override
  int minSupportedVersion() => 4;

  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    Pointer<Utf8> fileName,
    int dpbLength,
    Pointer<Uint8> dpb,
  )
  _attachDatabase;

  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    Pointer<Utf8> fileName,
    int dpbLength,
    Pointer<Uint8> dpb,
  )
  _createDatabase;

  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    Pointer<Utf8> service,
    int spbLength,
    Pointer<Uint8> spb,
  )
  _attachServiceManager;

  late void Function(
    FbInterface self,
    FbInterface status,
    int timeout,
    int reason,
  )
  _shutdown;

  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface crytpCallback,
  )
  _setDbCryptCallback;

  IProvider(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 5;
    var idx = startIndex;
    _attachDatabase =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _createDatabase =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _attachServiceManager =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  UnsignedInt,
                  Pointer<Uint8>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _shutdown =
        Pointer<
              NativeFunction<
                Void Function(FbInterface, FbInterface, UnsignedInt, Int)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _setDbCryptCallback =
        Pointer<
              NativeFunction<
                Void Function(FbInterface, FbInterface, FbInterface)
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
  }

  /// Attach to an existing database.
  /// Provide an earlier obtained IStatus interface as a status indicator,
  /// database file/alias name, and optional database parameter buffer.
  /// Use an instance of IXpbBuilder to allocate and populate the buffer
  /// with all required connection parameters (like user name and password).
  IAttachment attachDatabase(
    IStatus status,
    String fileName, [
    int dpbLength = 0,
    Pointer<Uint8>? dpb,
  ]) {
    final fileNameUtf = fileName.toNativeUtf8(allocator: mem);
    try {
      dpb ??= nullptr;
      final res = _attachDatabase(
        self,
        status.self,
        fileNameUtf,
        dpbLength,
        dpb,
      );
      status.checkStatus();
      return IAttachment(res);
    } finally {
      mem.free(fileNameUtf);
    }
  }

  /// Create a new database.
  /// Provide an earlier obtained IStatus interface as a status indicator,
  /// database file name / location, and optional database parameter buffer.
  /// Use an instance of IXpbBuilder to allocate and populate the buffer
  /// with all required parameters (like user name and password, page size,
  /// etc.).
  IAttachment createDatabase(
    IStatus status,
    String fileName, [
    int dpbLength = 0,
    Pointer<Uint8>? dpb,
  ]) {
    final fileNameUtf = fileName.toNativeUtf8(allocator: mem);
    try {
      dpb ??= nullptr;
      final res = _createDatabase(
        self,
        status.self,
        fileNameUtf,
        dpbLength,
        dpb,
      );
      status.checkStatus();
      return IAttachment(res);
    } finally {
      mem.free(fileNameUtf);
    }
  }

  /// Attach to a service manager.
  /// Provide an earlier obtained IStatus interface as a status indicator,
  /// service name, and optional service parameter buffer.
  /// Use an instance of IXpbBuilder to allocate and populate the buffer
  /// with all required parameters (like user name and password, page size,
  /// etc.).
  IService attachServiceManager(
    IStatus status,
    String service, [
    int spbLength = 0,
    Pointer<Uint8>? spb,
  ]) {
    final serviceUtf = service.toNativeUtf8(allocator: mem);
    try {
      spb ??= nullptr;
      final res = _attachServiceManager(
        self,
        status.self,
        serviceUtf,
        spbLength,
        spb,
      );
      status.checkStatus();
      return IService(res);
    } finally {
      mem.free(serviceUtf);
    }
  }

  void shutdown(IStatus status, int timeout, int reason) {
    _shutdown(self, status.self, timeout, reason);
    status.checkStatus();
  }

  void setDbCryptCallback(IStatus status, ICryptKeyCallback callback) {
    _setDbCryptCallback(self, status.self, callback.self);
    status.checkStatus();
  }
}
