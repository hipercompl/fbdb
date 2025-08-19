import "dart:convert";
import "dart:ffi";
import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";

class IUtil extends IVersioned {
  @override
  int minSupportedVersion() => 2;

  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface attachment,
    FbInterface callback,
  )
  _getFbVersion;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscQuad> blobId,
    FbInterface attachment,
    FbInterface transaction,
    Pointer<Utf8> file,
    int txt,
  )
  _loadBlob;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscQuad> blobId,
    FbInterface attachment,
    FbInterface transaction,
    Pointer<Utf8> file,
    int txt,
  )
  _dumbBlob;
  late void Function(
    FbInterface self,
    FbInterface status,
    FbInterface attachment,
    Pointer<Utf8> countersSet,
    Pointer<Int64> counters,
  )
  _getPerfCounters;
  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    int stmtLength,
    Pointer<Utf8> createDBStatement,
    int dialect,
    Pointer<FbBoolean> stmtIsCreateDb,
  )
  _executeCreateDatabase;
  late void Function(
    FbInterface self,
    int date,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
  )
  _decodeDate;
  late void Function(
    FbInterface self,
    int time,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
  )
  _decodeTime;
  late int Function(FbInterface self, int year, int month, int day) _encodeDate;
  late int Function(
    FbInterface self,
    int hours,
    int minutes,
    int seconds,
    int fractions,
  )
  _encodeTime;
  late int Function(
    FbInterface self,
    Pointer<Utf8> buffer,
    int bufferSize,
    FbInterface status,
  )
  _formatStatus;
  late int Function(FbInterface self) _getClientVersion;
  late FbInterface Function(
    FbInterface self,
    FbInterface status,
    int kind,
    Pointer<Uint8> buffer,
    int len,
  )
  _getXpbBuilder;
  late int Function(
    FbInterface self,
    FbInterface status,
    FbInterface metadata,
    FbInterface callback,
  )
  _setOffsets;
  late FbInterface Function(FbInterface self, FbInterface status)
  _getDecFloat16;
  late FbInterface Function(FbInterface self, FbInterface status)
  _getDecFloat34;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimeTz> timeTz,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  )
  _decodeTimeTz;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimestampTz> timeStampTz,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  )
  _decodeTimeStampTz;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimeTz> timeTz,
    int hours,
    int minutes,
    int seconds,
    int fractions,
    Pointer<Utf8> timeZone,
  )
  _encodeTimeTz;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimestampTz> timeTz,
    int year,
    int month,
    int day,
    int hours,
    int minutes,
    int seconds,
    int fractions,
    Pointer<Utf8> timeZone,
  )
  _encodeTimeStampTz;
  late FbInterface Function(FbInterface self, FbInterface status) _getInt128;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimeTzEx> timeTz,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  )
  _decodeTimeTzEx;
  late void Function(
    FbInterface self,
    FbInterface status,
    Pointer<IscTimestampTzEx> timeTz,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  )
  _decodeTimeStampTzEx;
  IUtil(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = (version >= 4 ? 22 : 13);
    var idx = startIndex;
    _getFbVersion =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _loadBlob =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  Pointer<IscQuad>,
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  FbBoolean,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _dumbBlob =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  Pointer<IscQuad>,
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  FbBoolean,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getPerfCounters =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  Pointer<Utf8>,
                  Pointer<Int64>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _executeCreateDatabase =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Utf8>,
                  UnsignedInt,
                  Pointer<FbBoolean>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _decodeDate =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  IscDate,
                  Pointer<UnsignedInt>,
                  Pointer<UnsignedInt>,
                  Pointer<UnsignedInt>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _decodeTime =
        Pointer<
              NativeFunction<
                Void Function(
                  FbInterface,
                  IscTime,
                  Pointer<UnsignedInt>,
                  Pointer<UnsignedInt>,
                  Pointer<UnsignedInt>,
                  Pointer<UnsignedInt>,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _encodeDate =
        Pointer<
              NativeFunction<
                IscDate Function(
                  FbInterface,
                  UnsignedInt,
                  UnsignedInt,
                  UnsignedInt,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _encodeTime =
        Pointer<
              NativeFunction<
                IscTime Function(
                  FbInterface,
                  UnsignedInt,
                  UnsignedInt,
                  UnsignedInt,
                  UnsignedInt,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _formatStatus =
        Pointer<
              NativeFunction<
                UnsignedInt Function(
                  FbInterface,
                  Pointer<Utf8>,
                  UnsignedInt,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _getClientVersion =
        Pointer<NativeFunction<UnsignedInt Function(FbInterface)>>.fromAddress(
          vtable[idx++],
        ).asFunction();
    _getXpbBuilder =
        Pointer<
              NativeFunction<
                FbInterface Function(
                  FbInterface,
                  FbInterface,
                  UnsignedInt,
                  Pointer<Uint8>,
                  UnsignedInt,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    _setOffsets =
        Pointer<
              NativeFunction<
                UnsignedInt Function(
                  FbInterface,
                  FbInterface,
                  FbInterface,
                  FbInterface,
                )
              >
            >.fromAddress(vtable[idx++])
            .asFunction();
    if (version >= 4) {
      _getDecFloat16 =
          Pointer<
                NativeFunction<FbInterface Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _getDecFloat34 =
          Pointer<
                NativeFunction<FbInterface Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _decodeTimeTz =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimeTz>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
      _decodeTimeStampTz =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimestampTz>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
      _encodeTimeTz =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimeTz>,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
      _encodeTimeStampTz =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimestampTz>,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
      _getInt128 =
          Pointer<
                NativeFunction<FbInterface Function(FbInterface, FbInterface)>
              >.fromAddress(vtable[idx++])
              .asFunction();
      _decodeTimeTzEx =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimeTzEx>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
      _decodeTimeStampTzEx =
          Pointer<
                NativeFunction<
                  Void Function(
                    FbInterface,
                    FbInterface,
                    Pointer<IscTimestampTzEx>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    Pointer<UnsignedInt>,
                    UnsignedInt,
                    Pointer<Utf8>,
                  )
                >
              >.fromAddress(vtable[idx++])
              .asFunction();
    }
  }

  void getFbVersion(
    IStatus status,
    IAttachment attachment,
    IVersionCallback callback,
  ) {
    _getFbVersion(self, status.self, attachment.self, callback.self);
    status.checkStatus();
  }

  void loadBlob(
    IStatus status,
    Pointer<IscQuad> blobId,
    IAttachment attachment,
    ITransaction transaction,
    String file,
    bool txt,
  ) {
    final fileUtf = file.toNativeUtf8(allocator: mem);
    try {
      _loadBlob(
        self,
        status.self,
        blobId,
        attachment.self,
        transaction.self,
        fileUtf,
        txt ? 1 : 0,
      );
      status.checkStatus();
    } finally {
      mem.free(fileUtf);
    }
  }

  void dumpBlob(
    IStatus status,
    Pointer<IscQuad> blobId,
    IAttachment attachment,
    ITransaction transaction,
    String file,
    bool txt,
  ) {
    final fileUtf = file.toNativeUtf8(allocator: mem);
    try {
      _dumbBlob(
        self,
        status.self,
        blobId,
        attachment.self,
        transaction.self,
        fileUtf,
        txt ? 1 : 0,
      );
      status.checkStatus();
    } finally {
      mem.free(fileUtf);
    }
  }

  void getPerfCounters(
    IStatus status,
    IAttachment attachment,
    String countersSet,
    Pointer<Int64> counters,
  ) {
    final countersSetUtf = countersSet.toNativeUtf8(allocator: mem);
    try {
      _getPerfCounters(
        self,
        status.self,
        attachment.self,
        countersSetUtf,
        counters,
      );
      status.checkStatus();
    } finally {
      mem.free(countersSetUtf);
    }
  }

  IAttachment executeCreateDatabase(
    IStatus status,
    String createDbStatement,
    int dialect,
    Pointer<FbBoolean> stmtIsCreateDb,
  ) {
    final len = Utf8Encoder().convert(createDbStatement).length;
    final createDbStatementUtf = createDbStatement.toNativeUtf8(allocator: mem);
    try {
      final res = _executeCreateDatabase(
        self,
        status.self,
        len,
        createDbStatementUtf,
        dialect,
        stmtIsCreateDb,
      );
      status.checkStatus();
      return IAttachment(res);
    } finally {
      mem.free(createDbStatementUtf);
    }
  }

  void decodeDate(
    int date,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
  ) {
    _decodeDate(self, date, year, month, day);
  }

  void decodeTime(
    int time,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
  ) {
    _decodeTime(self, time, hours, minutes, seconds, fractions);
  }

  int encodeDate(int year, int month, int day) {
    return _encodeDate(self, year, month, day);
  }

  int encodeTime(int hours, int minutes, int seconds, int fractions) {
    return _encodeTime(self, hours, minutes, seconds, fractions);
  }

  int formatStatus(Pointer<Utf8> buffer, int bufferSize, IStatus status) {
    return _formatStatus(self, buffer, bufferSize, status.self);
  }

  String formattedStatus(IStatus status) {
    try {
      const bufSize = 512;
      Pointer<Utf8> buf = mem.allocate(bufSize);
      try {
        final len = formatStatus(buf, bufSize, status);
        final codePoints = buf.toDartMem(len);
        final str = Utf8Decoder(allowMalformed: true).convert(codePoints);
        return str;
      } finally {
        mem.free(buf);
      }
    } catch (_) {
      // automatic format didn't work, will try to return the status
      // formatted by hand
      final errors = status.errors.where((e) => e != 0);
      return "Could not format error message. Error codes: $errors";
    }
  }

  int getClientVersion() {
    return _getClientVersion(self);
  }

  IXpbBuilder getXpbBuilder(
    IStatus status,
    int kind, [
    Pointer<Uint8>? buffer,
    int len = 0,
  ]) {
    buffer ??= nullptr;
    final res = IXpbBuilder(
      _getXpbBuilder(self, status.self, kind, buffer, len),
    );
    status.checkStatus();
    return res;
  }

  int setOffsets(
    IStatus status,
    IMessageMetadata metadata,
    IOffsetsCallback callback,
  ) {
    final res = _setOffsets(self, status.self, metadata.self, callback.self);
    status.checkStatus();
    return res;
  }

  IDecFloat16 getDecFloat16(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    final res = _getDecFloat16(self, status.self);
    status.checkStatus();
    return IDecFloat16(res);
  }

  IDecFloat34 getDecFloat34(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    final res = _getDecFloat34(self, status.self);
    status.checkStatus();
    return IDecFloat34(res);
  }

  void decodeTimeTz(
    IStatus status,
    Pointer<IscTimeTz> timeTz,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _decodeTimeTz(
      self,
      status.self,
      timeTz,
      hours,
      minutes,
      seconds,
      fractions,
      timeZoneBufferLength,
      timeZoneBuffer,
    );
    status.checkStatus();
  }

  void decodeTimeStampTz(
    IStatus status,
    Pointer<IscTimestampTz> timeStampTz,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _decodeTimeStampTz(
      self,
      status.self,
      timeStampTz,
      year,
      month,
      day,
      hours,
      minutes,
      seconds,
      fractions,
      timeZoneBufferLength,
      timeZoneBuffer,
    );
    status.checkStatus();
  }

  void encodeTimeTz(
    IStatus status,
    Pointer<IscTimeTz> timeTz,
    int hours,
    int minutes,
    int seconds,
    int fractions,
    String timeZone,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    final timeZoneUtf = timeZone.toNativeUtf8(allocator: mem);
    try {
      _encodeTimeTz(
        self,
        status.self,
        timeTz,
        hours,
        minutes,
        seconds,
        fractions,
        timeZoneUtf,
      );
      status.checkStatus();
    } finally {
      mem.free(timeZoneUtf);
    }
  }

  void encodeTimeStampTz(
    IStatus status,
    Pointer<IscTimestampTz> timeStampTz,
    int year,
    int month,
    int day,
    int hours,
    int minutes,
    int seconds,
    int fractions,
    String timeZone,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    final timeZoneUtf = timeZone.toNativeUtf8(allocator: mem);
    try {
      _encodeTimeStampTz(
        self,
        status.self,
        timeStampTz,
        year,
        month,
        day,
        hours,
        minutes,
        seconds,
        fractions,
        timeZoneUtf,
      );
      status.checkStatus();
    } finally {
      mem.free(timeZoneUtf);
    }
  }

  IInt128 getInt128(IStatus status) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    final res = _getInt128(self, status.self);
    status.checkStatus();
    return IInt128(res);
  }

  void decodeTimeTzEx(
    IStatus status,
    Pointer<IscTimeTzEx> timeTz,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _decodeTimeTzEx(
      self,
      status.self,
      timeTz,
      hours,
      minutes,
      seconds,
      fractions,
      timeZoneBufferLength,
      timeZoneBuffer,
    );
    status.checkStatus();
  }

  void decodeTimeStampTzEx(
    IStatus status,
    Pointer<IscTimestampTzEx> timeStampTz,
    Pointer<UnsignedInt> year,
    Pointer<UnsignedInt> month,
    Pointer<UnsignedInt> day,
    Pointer<UnsignedInt> hours,
    Pointer<UnsignedInt> minutes,
    Pointer<UnsignedInt> seconds,
    Pointer<UnsignedInt> fractions,
    int timeZoneBufferLength,
    Pointer<Utf8> timeZoneBuffer,
  ) {
    if (version < 4) {
      throw UnimplementedError(
        "Firebird client library version 4 or later required.",
      );
    }
    _decodeTimeStampTzEx(
      self,
      status.self,
      timeStampTz,
      year,
      month,
      day,
      hours,
      minutes,
      seconds,
      fractions,
      timeZoneBufferLength,
      timeZoneBuffer,
    );
    status.checkStatus();
  }
}
