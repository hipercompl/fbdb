import "dart:ffi";
import "package:fbdb/fbclient.dart";

/// Base exception class of the fbdb package.
class FbClientException implements Exception {
  /// Error message
  String message;

  /// Constructs an exception with the given error message.
  FbClientException(this.message);

  /// Returns the error message associated with this exception.
  @override
  String toString() {
    return message;
  }
}

/// Encapsulates the Firebird status vector and error message.
class FbServerException implements Exception {
  /// The status vector converted to a standard Dart list.
  List<int> errors;

  /// An optional error message.
  String message;

  /// The default constructor.
  FbServerException(this.errors, this.message);

  /// Constructs a FbServerException object from the given IStatus.
  ///
  /// If an instance of IUtil is also provided, it is used
  /// to get an error message corresponding to the error code
  /// in the status vector.
  /// If util is not provided, the error message will be empty
  /// and only numeric error codes will be present in the exception.
  FbServerException.fromStatus(IStatus status, {IUtil? util})
      : errors = status.errors,
        message = util?.formattedStatus(status) ?? "";

  /// Returns the error message from the exception.
  @override
  String toString() {
    return message;
  }

  /// Informs whether the error list contains a specific error code.
  bool hasError(int errorCode) {
    return errors.contains(errorCode);
  }

  /// Informs whether rhe error list contains any error code
  /// from the provided list.
  bool hasAnyError(Set<int> errorCodes) {
    return errorCodes.any((code) => hasError(code));
  }
}

/// An exception with status vector inside.
///
/// This exception contains a reference to an IStatus instance,
/// which in turn includes native bindings.
/// Therefore, it cannot be passed between isolates and can be
/// used only in the isolate it gets thrown in.
/// If an exception with a status vector needs to be passed
/// between isolates, it's better to use [FbServerException].
class FbStatusException implements Exception {
  /// A handle to the [IStatus] interface (native).
  IStatus status;

  /// The default constructor.
  FbStatusException(this.status);
}

/// FB_BOOLEAN is just an unsigned char (with 1/0 for true/false).
typedef FbBoolean = UnsignedChar;

/// A mapping for the native IscDate type from the Firebird client library.
typedef IscDate = Int32;

/// A mapping for the native IscTime type from the Firebird client library.
typedef IscTime = Uint32;

/// This structure is byte-compatible with the native IscQuad structure.
///
/// It is a direct mapping of a native struct, so it can't be passed
/// between isolates. If passing between isolates is required, construct
/// a [FbQuad] object, initialized with an IscQuad structure.
final class IscQuad extends Struct {
  /// The high word of the quad.
  @Long()
  external int iscQuadHigh;

  /// The low word of the quad.
  @UnsignedLong()
  external int iscQuadLow;

  /// Allocates (in native memory) and initializes a new IscQuad structure.
  static Pointer<IscQuad> allocate(int iscQuadHigh, int iscQuadLow) {
    Pointer<IscQuad> ptr = mem.allocate<IscQuad>(sizeOf<IscQuad>());
    ptr.ref
      ..iscQuadHigh = iscQuadHigh
      ..iscQuadLow = iscQuadLow;
    return ptr;
  }

  /// Frees up memory occupied by an IscQuad structure.
  static void free(Pointer<IscQuad> ptr) {
    mem.free(ptr);
  }
}

/// A Dart representation of an IscQuad native structure.
///
/// Objects of this class can be safely passed between isolates.
class FbQuad {
  /// The high word of the quad.
  int quadHigh;

  /// The low word of the quad.
  int quadLow;

  /// The default constructor.
  FbQuad(this.quadHigh, this.quadLow);

  /// Constructs an FbQuad with data from a native IscQuad structure.
  FbQuad.fromIscQuad(Pointer<IscQuad> quad)
      : this(quad.ref.iscQuadHigh, quad.ref.iscQuadLow);
}

/// A Dart mapping for the native IscTimeTz structure.
final class IscTimeTz extends Struct {
  /// The time value.
  @IscTime()
  external int utcTime;

  /// Time zone.
  @Uint16()
  external int timeZone;

  /// Allocates (in native memory) and initializes a new IscTimeTz structure.
  static Pointer<IscTimeTz> allocate(int utcTime, int timeZone) {
    Pointer<IscTimeTz> ptr = mem.allocate<IscTimeTz>(sizeOf<IscTimeTz>());
    ptr.ref
      ..utcTime = utcTime
      ..timeZone = timeZone;
    return ptr;
  }

  /// Frees up memory occupied by the structure.
  static void free(Pointer<IscTimeTz> ptr) {
    mem.free(ptr);
  }
}

/// A Dart mapping for the native IscTimeTzEx structure.
final class IscTimeTzEx extends Struct {
  /// The time value.
  @IscTime()
  external int utcTime;

  /// Time zone.
  @Uint16()
  external int timeZone;

  /// Extende time zone offset information.
  @Int16()
  external int extOffset;

  /// Allocates (in native memory) and initializes a new IscTimeTzEx structure.
  static Pointer<IscTimeTzEx> allocate(
      int utcTime, int timeZone, int extOffset) {
    Pointer<IscTimeTzEx> ptr = mem.allocate<IscTimeTzEx>(sizeOf<IscTimeTzEx>());
    ptr.ref
      ..utcTime = utcTime
      ..timeZone = timeZone
      ..extOffset = extOffset;
    return ptr;
  }

  /// Frees up memory occupied by the structure.
  static void free(Pointer<IscTimeTzEx> ptr) {
    mem.free(ptr);
  }
}

/// A Dart mapping for the native IscTimestamp structure.
final class IscTimestamp extends Struct {
  /// The date part of the timestamp.
  @IscDate()
  external int date;

  /// The time part of the timestamp.
  @IscTime()
  external int time;

  /// Allocates (in native memory) and initializes a new IscTimestamp structure.
  static Pointer<IscTimestamp> allocate(int date, int time) {
    Pointer<IscTimestamp> ptr =
        mem.allocate<IscTimestamp>(sizeOf<IscTimestamp>());
    ptr.ref
      ..date = date
      ..time = time;
    return ptr;
  }

  /// Frees up memory occupied by the structure.
  static void free(Pointer<IscTimestamp> ptr) {
    mem.free(ptr);
  }
}

/// A Dart mapping for the native IscTimestampTz structure.
final class IscTimestampTz extends Struct {
  /// The date part of the timestamp.
  @IscDate()
  external int date;

  /// The time part of the timestamp.
  @IscTime()
  external int time;

  /// Time zone information.
  @Uint16()
  external int timeZone;

  /// Allocates (in native memory) and initializes a new
  /// IscTimestampTz structure.
  static Pointer<IscTimestampTz> allocate(int date, int time, int timeZone) {
    Pointer<IscTimestampTz> ptr =
        mem.allocate<IscTimestampTz>(sizeOf<IscTimestampTz>());
    ptr.ref
      ..date = date
      ..time = time
      ..timeZone = timeZone;
    return ptr;
  }

  /// Frees up memory occupied by the structure.
  static void free(Pointer<IscTimestampTz> ptr) {
    mem.free(ptr);
  }
}

/// A Dart mapping for the native IscTimestampTzEx structure.
final class IscTimestampTzEx extends Struct {
  /// The date part of the timestamp.
  @IscDate()
  external int date;

  /// The time part of the timestamp.
  @IscTime()
  external int time;

  /// Time zone information.
  @Uint16()
  external int timeZone;

  /// Extended time zone offset.
  @Int16()
  external int extOffset;

  /// Allocates (in native memory) and initializes a new
  /// IscTimestampTzEx structure.
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

  /// Frees up memory occupied by the structure.
  static void free(Pointer<IscTimestampTzEx> ptr) {
    mem.free(ptr);
  }
}

/// A Dart mapping for the FbDec16 native type.
final class FbDec16 extends Struct {
  /// The bytes of the dec16 number.
  @Array(1)
  external Array<Uint64> fbData;
}

/// A Dart mapping for the FbDec34 native type.
final class FbDec34 extends Struct {
  @Array(2)
  external Array<Uint64> fbData;
}

final class FbI128 extends Struct {
  /// The bytes of the dec34 number.
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
  /// The hash used to identify a blob in the map of active blobs
  /// of a connection object. Relevant only in the high-level API.
  int _idHash = 0;

  /// Initializes a new BLOB ID object.
  FbBlobId(super.idHigh, super.idLow) {
    _idHash = hashCode;
  }

  /// Constructs a BLOB ID from the given FbQuad value.
  ///
  /// Internally, BLOB IDs are represented in Firebird client code
  /// as structures of type IscQuad. The [IscQuad] structure has its
  /// Dart mappings in fbdb, but since it resides in native memory,
  /// it cannot be passed between isolates.
  /// If such need arises, an [IscQuad] structure should be converted
  /// to a [FbQuad] object (via [FbQuad.fromIscQuad]), and the resulting
  /// [FbQuad] is a normal Dart object and can be passed between isolates.
  /// The FbBlobId class is a specialized subclass of [FbQuad].
  FbBlobId.fromQuad(FbQuad quad) : this(quad.quadHigh, quad.quadLow);

  /// Constructs a BLOB ID from the given IscQuad native struct.
  ///
  /// Internally, BLOB IDs are represented in Firebird client code
  /// as structures of type IscQuad. The [IscQuad] structure has its
  /// Dart mappings in fbdb. Passing such structure to this specialized
  /// constructor converts the native [IscQuad] into a BLOB ID, which
  /// is an extension of [FbQuad].
  FbBlobId.fromIscQuad(super.quad) : super.fromIscQuad() {
    _idHash = hashCode;
  }

  /// Returns the key, under which this BLOB ID is registered in the
  /// map of active BLOBs kept by the active connection.
  ///
  /// Relevant only in the high-level API.
  int get idHash {
    return _idHash;
  }

  /// Fills up the given [IscQuad] native structure with data from
  /// this BLOB ID.
  void storeInQuad(Pointer<IscQuad> quad) {
    quad.ref.iscQuadHigh = quadHigh;
    quad.ref.iscQuadLow = quadLow;
  }

  /// Useful mostly in debugging, otherwise the text representation
  /// of a BLOB ID doesn't say much.
  @override
  String toString() {
    return "FbBlobId($quadHigh:$quadLow)";
  }
}
