import "dart:ffi";
import "package:fbdb/fbclient.dart";

/// Base exception class of the fbclient package.
class FbClientException implements Exception {
  /// Error message
  String message;

  /// Constructs an exception with the given error message.
  FbClientException(this.message);

  @override
  String toString() {
    return message;
  }
}

/// Encapsulates the Firebird status vector and error message.
class FbServerException implements Exception {
  List<int> errors;
  String message;

  FbServerException(this.errors, this.message);

  FbServerException.fromStatus(IStatus status, {IUtil? util})
      : errors = status.errors,
        message = util?.formattedStatus(status) ?? "";

  @override
  String toString() {
    return message;
  }

  bool hasError(int errorCode) {
    return errors.contains(errorCode);
  }

  bool hasAnyError(Set<int> errorCodes) {
    return errorCodes.any((code) => hasError(code));
  }
}

/// An exception with status vector inside.
class FbStatusException implements Exception {
  IStatus status;
  FbStatusException(this.status);
}

/// FB_BOOLEAN is just an unsigned char (with 1/0 for true/false)
typedef FbBoolean = UnsignedChar;

typedef IscDate = Int32;
typedef IscTime = Uint32;

final class IscQuad extends Struct {
  @Long()
  external int iscQuadHigh;

  @UnsignedLong()
  external int iscQuadLow;

  static Pointer<IscQuad> allocate(int iscQuadHigh, int iscQuadLow) {
    Pointer<IscQuad> ptr = mem.allocate<IscQuad>(sizeOf<IscQuad>());
    ptr.ref
      ..iscQuadHigh = iscQuadHigh
      ..iscQuadLow = iscQuadLow;
    return ptr;
  }

  static void free(Pointer<IscQuad> ptr) {
    mem.free(ptr);
  }
}

class FbQuad {
  int quadHigh;
  int quadLow;

  FbQuad(this.quadHigh, this.quadLow);

  /// Creates the quad from native memory data.
  FbQuad.fromIscQuad(Pointer<IscQuad> quad)
      : this(quad.ref.iscQuadHigh, quad.ref.iscQuadLow);
}

final class IscTimeTz extends Struct {
  @IscTime()
  external int utcTime;

  @Uint16()
  external int timeZone;

  static Pointer<IscTimeTz> allocate(int utcTime, int timeZone) {
    Pointer<IscTimeTz> ptr = mem.allocate<IscTimeTz>(sizeOf<IscTimeTz>());
    ptr.ref
      ..utcTime = utcTime
      ..timeZone = timeZone;
    return ptr;
  }

  static void free(Pointer<IscTimeTz> ptr) {
    mem.free(ptr);
  }
}

final class IscTimeTzEx extends Struct {
  @IscTime()
  external int utcTime;

  @Uint16()
  external int timeZone;

  @Int16()
  external int extOffset;

  static Pointer<IscTimeTzEx> allocate(
      int utcTime, int timeZone, int extOffset) {
    Pointer<IscTimeTzEx> ptr = mem.allocate<IscTimeTzEx>(sizeOf<IscTimeTzEx>());
    ptr.ref
      ..utcTime = utcTime
      ..timeZone = timeZone
      ..extOffset = extOffset;
    return ptr;
  }

  static void free(Pointer<IscTimeTzEx> ptr) {
    mem.free(ptr);
  }
}

final class IscTimestamp extends Struct {
  @IscDate()
  external int date;

  @IscTime()
  external int time;

  static Pointer<IscTimestamp> allocate(int date, int time) {
    Pointer<IscTimestamp> ptr =
        mem.allocate<IscTimestamp>(sizeOf<IscTimestamp>());
    ptr.ref
      ..date = date
      ..time = time;
    return ptr;
  }

  static void free(Pointer<IscTimestamp> ptr) {
    mem.free(ptr);
  }
}

final class IscTimestampTz extends Struct {
  @IscDate()
  external int date;

  @IscTime()
  external int time;

  @Uint16()
  external int timeZone;

  static Pointer<IscTimestampTz> allocate(int date, int time, int timeZone) {
    Pointer<IscTimestampTz> ptr =
        mem.allocate<IscTimestampTz>(sizeOf<IscTimestampTz>());
    ptr.ref
      ..date = date
      ..time = time
      ..timeZone = timeZone;
    return ptr;
  }

  static void free(Pointer<IscTimestampTz> ptr) {
    mem.free(ptr);
  }
}

final class IscTimestampTzEx extends Struct {
  @IscDate()
  external int date;

  @IscTime()
  external int time;

  @Uint16()
  external int timeZone;

  @Int16()
  external int extOffset;

  static Pointer<IscTimestampTzEx> allocate(
      int date, int time, int timeZone, int extOffset) {
    Pointer<IscTimestampTzEx> ptr =
        mem.allocate<IscTimestampTzEx>(sizeOf<IscTimestampTzEx>());
    ptr.ref
      ..date = date
      ..time = time
      ..timeZone = timeZone
      ..extOffset = extOffset;
    return ptr;
  }

  static void free(Pointer<IscTimestampTzEx> ptr) {
    mem.free(ptr);
  }
}

final class FbDec16 extends Struct {
  @Array(1)
  external Array<Uint64> fbData;
}

final class FbDec34 extends Struct {
  @Array(2)
  external Array<Uint64> fbData;
}

final class FbI128 extends Struct {
  @Array(2)
  external Array<Uint64> fbData;
}

/// The blob identifier.
///
/// Use [FbBlobId] objects in calls to [FbDb.createBlob] and [FbDb.openBlob].
/// You shouldn't create [FbBlobId] objects directly, instead you obtain
/// them by creating a new blob (see [FbDb.createBlob]) or with row data, if
/// the selected columns contain blob IDs.
class FbBlobId extends FbQuad {
  int _idHash = 0;
  FbBlobId(super.idHigh, super.idLow) {
    _idHash = hashCode;
  }
  FbBlobId.fromQuad(FbQuad quad) : this(quad.quadHigh, quad.quadLow);
  FbBlobId.fromIscQuad(super.quad) : super.fromIscQuad() {
    _idHash = hashCode;
  }
  int get idHash {
    return _idHash;
  }

  void storeInQuad(Pointer<IscQuad> quad) {
    quad.ref.iscQuadHigh = quadHigh;
    quad.ref.iscQuadLow = quadLow;
  }

  @override
  String toString() {
    return "FbBlobId($quadHigh:$quadLow)";
  }
}
