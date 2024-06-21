import "dart:ffi";
import "dart:math";
import "dart:typed_data";
import "dart:convert";
import "package:ffi/ffi.dart";

/// Base exception class for all memory related exceptions.
class MemException implements Exception {
  /// Error message
  String message;

  /// Construct an exception with the given error message.
  MemException(this.message);

  @override
  String toString() {
    return message;
  }
}

/// The default allocator used by all parts of fbclient,
/// whenever a native memory needs to be allocated.
///
/// The allocator can be overriden by simply assigning a new value
/// to this global. See the `example/fbdb/ex_11_mem_benchmark.dart` for some
/// insights on how to use the tracing allocator to look for memory leaks.
/// In normal circumstances there's no need to change the allocator,
/// which by default is the built-in Dart FFI's `calloc`.
Allocator mem = calloc;

/// Allows to convert an int value to a byte buffer.
extension IntBytes on int {
  /// Converts an integer to a list of bytes of the given size.
  ///
  /// [byteCnt] has to be 1, 2, 4 or 8 (otherwise a [MemException]
  /// gets thrown).
  /// The value is treated as signed.
  ///
  /// Example:
  /// ```dart
  ///   final bytes = -1357.toBytesAsSigned(2); // 2-byte short
  /// ```
  Uint8List toBytesAsSigned(int byteCnt) {
    final res = Uint8List(byteCnt);
    switch (byteCnt) {
      case 1:
        res.buffer.asInt8List(0, 1)[0] = this;
      case 2:
        res.buffer.asInt16List(0, 1)[0] = this;
      case 4:
        res.buffer.asInt32List(0, 1)[0] = this;
      case 8:
        res.buffer.asInt64List(0, 1)[0] = this;
      default:
        throw MemException("Invalid target integer byte length: $byteCnt");
    }
    return res;
  }

  /// Converts an integer to a list of bytes of the given size.
  ///
  /// [byteCnt] has to be 1, 2, 4 or 8 (otherwise a [MemException]
  /// gets thrown).
  /// The value is treated as unsigned.
  ///
  /// Example:
  /// ```dart
  ///   final bytes = 1357.toBytesAsUnsigned(2); // 2-byte unsigned short
  /// ```
  Uint8List toBytesAsUnsigned(int byteCnt) {
    final res = Uint8List(byteCnt);
    switch (byteCnt) {
      case 1:
        res.buffer.asUint8List()[0] = this;
      case 2:
        res.buffer.asUint16List()[0] = this;
      case 4:
        res.buffer.asUint32List()[0] = this;
      case 8:
        res.buffer.asUint64List()[0] = this;
      default:
        throw MemException("Invalid target integer byte length: $byteCnt");
    }
    return res;
  }
}

/// Extension to simplify writing / reading integers to / from native memory.
extension IntMem on int {
  /// Puts an integer value into the [buffer], starting at [offset].
  ///
  /// The value occupies [byteCnt] consecutive bytes in the buffer.
  /// [byteCnt] has to be 1, 2, 4 or 8 (otherwise a [MemException]
  /// gets thrown).
  /// If the index is aligned, that is if ([offset] mod [byteCnt]) = 0,
  /// the method is more efficient. On unaligned data, byte by byte
  /// copying occurs.
  /// The source int value is treated as signed.
  ///
  /// Example:
  /// ```dart
  ///   -1357.putSigned(buf, 16, 4);
  /// ```
  void writeToBuffer(Pointer<Uint8> buffer, int offset, int byteCnt) {
    if (offset % byteCnt == 0) {
      // the target buffer is aligned
      switch (byteCnt) {
        case 1:
          Pointer<Int8>.fromAddress(buffer.address + offset).asTypedList(1)[0] =
              this;
        case 2:
          Pointer<Int16>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 4:
          Pointer<Int32>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 8:
          Pointer<Int64>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        default:
          throw MemException("Invalid target integer byte length: $byteCnt");
      }
    } else {
      // the offset is not aligned - copying byte by byte
      Uint8List bytes = toBytesAsSigned(byteCnt);
      for (int i = 0; i < byteCnt; i++) {
        buffer[offset + i] = bytes[i];
      }
    }
  }

  /// Puts an integer value into the [buffer], starting at [offset].
  ///
  /// The value occupies [byteCnt] consecutive bytes in the buffer.
  /// [byteCnt] has to be 1, 2, 4 or 8 (otherwise a [MemException]
  /// gets thrown).
  /// If the index is aligned, that is if ([offset] mod [byteCnt]) = 0,
  /// the method is more efficient. On unaligned data, byte by byte
  /// copying occurs.
  /// The source int value is treated as unsigned.
  ///
  /// ```dart
  ///   -1357.putSigned(buf, 16, 4);
  /// ```
  void writeToBufferUnsigned(Pointer<Uint8> buffer, int offset, int byteCnt) {
    if (offset % byteCnt == 0) {
      // the target buffer is aligned
      switch (byteCnt) {
        case 1:
          Pointer<Uint8>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 2:
          Pointer<Uint16>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 4:
          Pointer<Uint32>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 8:
          Pointer<Uint64>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        default:
          throw MemException("Invalid target integer byte length: $byteCnt");
      }
    } else {
      // the offset is not aligned - copying byte by byte
      Uint8List bytes = toBytesAsUnsigned(byteCnt);
      for (int i = 0; i < byteCnt; i++) {
        buffer[offset + i] = bytes[i];
      }
    }
  }
}

/// Convert a list of bytes to an int value.
///
/// The value is treated as signed.
/// The length of [bytes] has to be 1, 2, 4 or 8 (any other value
/// will cause a [MemException]).
///
/// Example:
/// ```dart
///   Uint8List buf = [1, 1];
///   int x = fromBytesAsSigned(buf); // x = 257
/// ```
int fromBytesAsSigned(Uint8List bytes) {
  int byteCnt = bytes.length;
  switch (byteCnt) {
    case 1:
      return bytes.buffer.asInt8List(0, 1)[0];
    case 2:
      return bytes.buffer.asInt16List(0, 1)[0];
    case 4:
      return bytes.buffer.asInt32List(0, 1)[0];
    case 8:
      return bytes.buffer.asInt64List(0, 1)[0];
    default:
      throw MemException("Invalid byte list length: $byteCnt");
  }
}

/// Convert a list of bytes to an int value.
///
/// The value is treated as unsigned.
/// The length of [bytes] has to be 1, 2, 4 or 8 (any other value
/// will cause a [MemException]).
///
/// Example:
/// ```dart
///   Uint8List buf = [1, 1];
///   int x = fromBytesAsUnsigned(buf); // x = 257
/// ```
int fromBytesAsUnsigned(Uint8List bytes) {
  int byteCnt = bytes.length;
  switch (byteCnt) {
    case 1:
      return bytes[0];
    case 2:
      return bytes.buffer.asUint16List(0, 1)[0];
    case 4:
      return bytes.buffer.asUint32List(0, 1)[0];
    case 8:
      return bytes.buffer.asUint64List(0, 1)[0];
    default:
      throw MemException("Invalid byte list length: $byteCnt");
  }
}

/// An extension to simplify writing / reading doubles to / from native memory.
extension DoubleBytes on double {
  /// Converts double value to a list of bytes of the given size.
  ///
  /// [byteCnt] has to be 4 (float32) or 8 (float64), otherwise
  /// a [MemException] gets thrown.
  ///
  /// Example:
  /// ```dart
  /// final bytes = 1234.567.toBytes(8); // 8-byte float64
  /// ```
  Uint8List toBytes([int byteCnt = 8]) {
    final res = Uint8List(byteCnt);
    switch (byteCnt) {
      case 4:
        res.buffer.asFloat32List(0, 1)[0] = this;
      case 8:
        res.buffer.asFloat64List(0, 1)[0] = this;
      default:
        throw MemException("Invalid target float byte length: $byteCnt");
    }
    return res;
  }
}

/// Read a specified piece of the buffer and convert it to an integer
/// number (signed).
///
/// If [offset] is aligned, tat is if ([offset] mod [byteCnt]) = 0,
/// the function is more efficient.
/// On unaligned data, byte-by-byte copying takes place.
/// The only valid values for [byteCnt] 1, 2, 4 and 8 (any other will
/// cause a [MemException]).
int readFromBufferAsSigned(Pointer<Uint8> buffer, int offset, int byteCnt) {
  if (offset % byteCnt == 0) {
    // the offset is aligned
    switch (byteCnt) {
      case 1:
        return Pointer<Int8>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 2:
        return Pointer<Int16>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 4:
        return Pointer<Int32>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 8:
        return Pointer<Int64>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      default:
        throw MemException(
            "Invalid byte count for reading int from buffer: $byteCnt");
    }
  } else {
    // the offset not aligned - copying byte by byte
    final bytes = Uint8List(byteCnt);
    for (var i = 0; i < byteCnt; i++) {
      bytes[i] = buffer[offset + i];
    }
    return fromBytesAsSigned(bytes);
  }
}

/// Read a specified piece of the buffer and convert it to an integer
/// number (unsigned).
///
/// If [offset] is aligned, tat is if ([offset] mod [byteCnt]) = 0,
/// the function chooses more efficient implementation.
/// On unaligned data, byte-by-byte copying takes place.
/// The only valid values for [byteCnt] are 1, 2, 4 and 8 (any other
/// will cause a [MemException]).
int readFromBufferAsUnsigned(Pointer<Uint8> buffer, int offset, int byteCnt) {
  if (offset % byteCnt == 0) {
    // the offset is aligned
    switch (byteCnt) {
      case 1:
        return buffer[offset];
      case 2:
        return Pointer<Uint16>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 4:
        return Pointer<Uint32>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 8:
        return Pointer<Uint64>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      default:
        throw MemException(
            "Invalid byte count for reading int from buffer: $byteCnt");
    }
  } else {
    // the offset not aligned - copying byte by byte
    final bytes = Uint8List(byteCnt);
    for (var i = 0; i < byteCnt; i++) {
      bytes[i] = buffer[offset + i];
    }
    return fromBytesAsUnsigned(bytes);
  }
}

/// Simplifies writing / reading doubles to / from native memory.
extension DoubleMem on double {
  /// Puts a double value into the [buffer], starting at [offset].
  ///
  /// The value occupies [byteCnt] consecutive bytes in the buffer.
  /// [byteCnt] has to be 4 (Float32) or 8 (Float64), otherwise
  /// a [MemException] gets thrown.
  /// If the index is aligned, that is if ([offset] mod [byteCnt]) = 0,
  /// the method is more efficient. On unaligned data, byte by byte
  /// copying occurs.
  ///
  /// Example:
  /// ```dart
  ///   (-232.77).put(buf, 16, 8);
  /// ```
  void writeToBuffer(Pointer<Uint8> buffer, int offset, [int byteCnt = 8]) {
    if (offset % byteCnt == 0) {
      // the index is aligned
      switch (byteCnt) {
        case 4:
          Pointer<Float>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        case 8:
          Pointer<Double>.fromAddress(buffer.address + offset)
              .asTypedList(1)[0] = this;
        default:
          throw MemException("Invalid target float byte length: $byteCnt");
      }
    } else {
      // the index is not aligned - copying byte by byte
      Uint8List bytes = toBytes(byteCnt);
      for (int i = 0; i < byteCnt; i++) {
        buffer[offset + i] = bytes[i];
      }
    }
  }
}

/// Convert a list of bytes to floating point value.
///
/// The length of [bytes] has to be 4 or 8, otherwise a [MemException]
/// gets thrown.
/// If [bytes] is 4 bytes long it's treated as Float32,
/// otherwise it's Float64.
double fromBytesAsFloat(Uint8List bytes) {
  int byteCnt = bytes.length;
  switch (byteCnt) {
    case 4:
      return bytes.buffer.asFloat32List(1)[0];
    case 8:
      return bytes.buffer.asFloat64List(1)[0];
    default:
      throw MemException("Invalid byte list length: $byteCnt");
  }
}

/// Read a specified piece of the buffer and convert it to a floating point
/// number.
///
/// If [offset] is aligned, tat is if ([offset] mod [byteCnt]) = 0,
/// the function chooses more efficient implementation.
/// On unaligned data, byte-by-byte copying takes place.
/// The only valid values for [byteCnt] are 4 (Float) and 8 (Double).
/// Any other will cause a [MemException].
double readFromBufferAsFloat(Pointer<Uint8> buffer, int offset, int byteCnt) {
  if (offset % byteCnt == 0) {
    // offset is aligned
    switch (byteCnt) {
      case 4:
        return Pointer<Float>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      case 8:
        return Pointer<Double>.fromAddress(buffer.address + offset)
            .asTypedList(1)[0];
      default:
        throw MemException("Invalid byte count value: $byteCnt");
    }
  } else {
    // offset is not aligned - copying byte by byte
    final bytes = Uint8List(byteCnt);
    for (var i = 0; i < byteCnt; i++) {
      bytes[i] = buffer[offset + i];
    }
    return fromBytesAsFloat(bytes);
  }
}

/// Simplifies writing / reading strings to / from native memory.
///
/// Strings that are to be placed in native memory buffers are always
/// converted to UTF-8 representation, and then stored byte by byte.
/// The other way around, bytes from a native buffer are treated
/// as UTF-8 code points and converted back to a Unicode string.
extension StringMem on String {
  /// Puts a string into the [buffer], starting at [offset].
  ///
  /// The string is first converted to UTF-8, then byte-copied
  /// into the buffer (including the null terminator or not,
  /// depending on [includeNullTerm]).
  /// The buffer has to be large enough to accomodate the converted
  /// string or [maxLength] has to be provided to set the upper
  /// bound on the amount of data being written.
  ///
  /// Example:
  /// ```dart
  ///   "Hello!".put(buf, 6);
  /// ```
  void writeToBuffer(Pointer<Uint8> buffer, int offset,
      {bool includeNullTerm = true, int? maxLength}) {
    final bytes = utf8.encode(this + (includeNullTerm ? "\x00" : ""));
    maxLength ??= bytes.length;
    maxLength = min(maxLength, bytes.length);
    for (var i = 0; i < maxLength; i++) {
      buffer[offset + i] = bytes[i];
    }
    if (includeNullTerm && maxLength < bytes.length) {
      // the string was truncated but a terminator is required,
      // so terminate the string on the last allowed byte
      buffer[offset + maxLength - 1] = 0;
    }
  }
}

/// Read a specified piece of the buffer and convert it to a string,
/// interpreting the bytes as UTF-8.
///
/// If [byteCnt] is not specified, it gets auto-calculated
/// by looking for the null terminator at position [offset]
/// or later in the [buffer].
/// [allowMalformed] is passed directly to `utf8.decode`,
/// allowing or not an invalid UTF-8 sequence to occur in the buffer.
String readFromBufferAsString(Pointer<Uint8> buffer, int offset,
    [int? byteCnt, bool allowMalformed = true]) {
  if (byteCnt == null) {
    // auto-detect the end of string
    int c = 0;
    while (buffer[offset + c++] != 0) {}
    byteCnt = c;
  }
  List<int> codeUnits = Pointer<Uint8>.fromAddress(buffer.address + offset)
      .asTypedList(byteCnt)
      .takeWhile((value) => value != 0)
      .toList();
  return utf8.decode(codeUnits, allowMalformed: allowMalformed);
}

/// Extension on byte buffers, allowing to read and write
/// pieces of the buffers as specific data types (numbers, strings, etc.).
///
/// Please note, that all offsets in reading and writing methods do not have
/// to be aligned, i.e. for an N-byte numeric type, the offset doesn't need
/// to be a multiplu of N. However, if it is, the methods are more efficient,
/// as they can take advantage of typed_data routines (otherwise a byte-wise
/// copying between native and Dart memory takes place).
///
/// Example:
/// ```dart
/// final Pointer<Uint8> buf = malloc<Uint8>(50);
/// buf.setAllBytes(50, 0); // zeroes the buffer
/// buf.writeInt16(0, 100);
/// buf.writeInt16(2, 100);
/// buf.writeString(4, "Hello!");
///
/// final s = buf.readString(4);
/// final i16 = buf.readInt16(2);
/// // this is also possible, but will result in garbage:
/// final i32 = buf.readInt32(0);
/// ```
extension ReadWriteData on Pointer<Uint8> {
  /// Reads a part of the buffer starting at [offset] as an Int8 value.
  int readInt8(int offset) {
    return readFromBufferAsSigned(this, offset, 1);
  }

  /// Reads a part of the buffer starting at [offset] as an Int16 value.
  int readInt16(int offset) {
    return readFromBufferAsSigned(this, offset, 2);
  }

  /// Reads a part of the buffer starting at [offset] as an Int32 value.
  int readInt32(int offset) {
    return readFromBufferAsSigned(this, offset, 4);
  }

  /// Reads a part of the buffer starting at [offset] as an Int64 value.
  int readInt64(int offset) {
    return readFromBufferAsSigned(this, offset, 8);
  }

  /// Reads a part of the buffer starting at [offset] as an Uint8 value.
  int readUint8(int offset) {
    return readFromBufferAsUnsigned(this, offset, 1);
  }

  /// Reads a part of the buffer starting at [offset] as an Uint16 value.
  int readUint16(int offset) {
    return readFromBufferAsUnsigned(this, offset, 2);
  }

  /// Reads a part of the buffer starting at [offset] as an Uint32 value.
  int readUint32(int offset) {
    return readFromBufferAsUnsigned(this, offset, 4);
  }

  /// Reads a part of the buffer starting at [offset] as an Uint64 value.
  int readUint64(int offset) {
    return readFromBufferAsUnsigned(this, offset, 8);
  }

  /// Reads a part of the buffer starting at [offset] as Float (32-bit) value.
  double readFloat(int offset) {
    return readFromBufferAsFloat(this, offset, 4);
  }

  /// Reads a part of the buffer starting at [offset] as Double (64-bit) value.
  double readDouble(int offset) {
    return readFromBufferAsFloat(this, offset, 8);
  }

  /// Reads a part of the buffer starting at [offset] as an UTF-8
  /// encoded string.
  ///
  /// If [byteCnt] is omitted, it is assumed the UTF-8 encoded string
  /// in the buffer is zero terminated.
  /// [allowMalformed] is passed to `utf8.decode` to allow or disallow
  /// invalid UTF-8 sequences in the buffer.
  String readString(int offset, [int? byteCnt, bool allowMalformed = true]) {
    return readFromBufferAsString(this, offset, byteCnt, allowMalformed);
  }

  /// Reads a part of the buffer as a VARCHAR value (structure).
  ///
  /// First reads a 16-bit unsigned short value N from the
  /// memory starting at [offset], which is the actual length
  /// of the string, and then it reads N consecutive bytes,
  /// starting at [offset]+2, treating them as an UTF-8 encoded string.
  /// The flag [allowMalformed] is passed down to `utf8.decode`.
  String readVarchar(int offset, [bool allowMalformed = true]) {
    int length = readUint16(offset);
    return readString(offset + sizeOf<Uint16>(), length, allowMalformed);
  }

  /// Reads a part of the buffer encoded as VAX integer.
  ///
  /// Interprets the bytes as a 16-bit signed integer value.
  /// The VAX representation is always little endian,
  /// regardless of the native platform representation.
  /// If the host is little endian, the method is more efficient
  /// (no conversion is necessary). Otherwise, a memory copying
  /// is necessary.
  /// This method in principle returns the same value as
  /// isc_vax_integer from libfbclient, but is implemented
  /// entirely in Dart.
  /// See also [FbClient.iscVaxInteger].
  int readVaxInt16(int offset) {
    if (Endian.host == Endian.little) {
      return readInt16(offset);
    } else {
      final bytes = Uint8List(2);
      bytes[0] = this[offset + 1];
      bytes[1] = this[offset];
      return fromBytesAsSigned(bytes);
    }
  }

  /// Reads a part of the buffer encoded as VAX integer.
  ///
  /// Interprets the bytes as a 32-bit signed integer value.
  /// The VAX representation is always little endian,
  /// regardless of the native platform representation.
  /// If the host is little endian, the method is more efficient
  /// (no conversion is necessary). Otherwise, a memory copying
  /// is necessary.
  /// This method in principle returns the same value as
  /// isc_vax_integer from libfbclient, but is implemented
  /// entirely in Dart.
  /// See also [FbClient.iscVaxInteger].
  int readVaxInt32(int offset) {
    if (Endian.host == Endian.little) {
      return readInt32(offset);
    } else {
      const byteCnt = 4;
      final bytes = Uint8List(byteCnt);
      for (var i = 0; i < byteCnt; i++) {
        bytes[i] = this[offset + byteCnt - 1 - i];
      }
      return fromBytesAsSigned(bytes);
    }
  }

  /// Reads a part of the buffer encoded as VAX integer.
  ///
  /// Interprets the bytes as a 64-bit signed integer value.
  /// The VAX representation is always little endian,
  /// regardless of the native platform representation.
  /// If the host is little endian, the method is more efficient
  /// (no conversion is necessary). Otherwise, a memory copying
  /// is necessary.
  /// This method in principle returns the same value as
  /// isc_vax_integer from libfbclient, but is implemented
  /// entirely in Dart.
  /// See also [FbClient.iscVaxInteger].
  int readVaxInt64(int offset) {
    if (Endian.host == Endian.little) {
      return readInt32(offset);
    } else {
      const byteCnt = 8;
      final bytes = Uint8List(byteCnt);
      for (var i = 0; i < byteCnt; i++) {
        bytes[i] = this[offset + byteCnt - 1 - i];
      }
      return fromBytesAsSigned(bytes);
    }
  }

  /// Writes an Int8 value to the buffer at offset [offset] (writes 1 byte).
  void writeInt8(int offset, int value) {
    value.writeToBuffer(this, offset, 1);
  }

  /// Writes an Int16 value to the buffer at offset [offset] (writes 2 bytes).
  void writeInt16(int offset, int value) {
    value.writeToBuffer(this, offset, 2);
  }

  /// Writes an Int32 value to the buffer at offset [offset] (writes 4 bytes).
  void writeInt32(int offset, int value) {
    value.writeToBuffer(this, offset, 4);
  }

  /// Writes an Int64 value to the buffer at offset [offset] (writes 8 bytes).
  void writeInt64(int offset, int value) {
    value.writeToBuffer(this, offset, 8);
  }

  /// Writes an Uint8 value to the buffer at offset [offset] (writes 1 byte).
  void writeUint8(int offset, int value) {
    value.writeToBufferUnsigned(this, offset, 1);
  }

  /// Writes an Uint16 value to the buffer at offset [offset] (writes 2 bytes).
  void writeUint16(int offset, int value) {
    value.writeToBufferUnsigned(this, offset, 2);
  }

  /// Writes an Uint32 value to the buffer at offset [offset] (writes 4 bytes).
  void writeUint32(int offset, int value) {
    value.writeToBufferUnsigned(this, offset, 4);
  }

  /// Writes an Uint64 value to the buffer at offset [offset] (writes 8 bytes).
  void writeUint64(int offset, int value) {
    value.writeToBufferUnsigned(this, offset, 8);
  }

  /// Writes a Float (32-bit) value to the buffer at offset [offset]
  /// (writes 4 bytes).
  void writeFloat(int offset, double value) {
    value.writeToBuffer(this, offset, 4);
  }

  /// Writes a Double (64-bit) value to the buffer at offset [offset]
  /// (writes 8 bytes).
  void writeDouble(int offset, double value) {
    value.writeToBuffer(this, offset, 8);
  }

  /// Writes a UTF-8 converted string to the buffer at offset [offset].
  ///
  /// If [includeNullTerm] = true, a zero terminator is written at the
  /// end of the string (occupying an extra byte in the buffer).
  /// The buffer needs to be long enough to accomodate the srting
  /// [value] converted to UTF-8 or [maxLength] must be provided
  /// to set the upper bound on the amount of data being copied.
  void writeString(int offset, String value,
      [bool includeNullTerm = true, int? maxLength]) {
    value.writeToBuffer(this, offset,
        includeNullTerm: includeNullTerm, maxLength: maxLength);
  }

  /// Writes a UTF-8 converted string to the buffer as VARCHAR.
  ///
  /// First it stores a 16-bit string length, at [offset],
  /// and then the consecutive UTF-8 code points, starting
  /// from [offset]+2.
  void writeVarchar(int offset, String value, [int? maxLength]) {
    final lenLength = sizeOf<Uint16>();
    final strUtf = utf8.encode(value);
    maxLength ??= strUtf.length + lenLength;
    int byteCnt = min(strUtf.length, maxLength - lenLength);
    writeUint16(offset, byteCnt);
    fromDartMem(strUtf, byteCnt, 0, offset + lenLength);
  }
}

/// A general extension, allowing to copy arbitrary blocks of native
/// memory to / from Dart memory, as well as between native buffers.
extension MemCopy on Pointer<NativeType> {
  /// Copies a piece of memory to a specified location in the native
  /// memory space.
  ///
  /// The source memory block starts at the address of [this] pointer,
  /// with the offset [srcByteOffset] bytes (bytes, not the pointer
  /// target type!) and its length is [byteCnt] (also in bytes, regardless
  /// of the actual type the pointer is pointing to).
  /// The target memory starts at [dst] shifted by [dstByteOffset] bytes.
  /// The number of bytes to copy is determined by [byteCnt].
  void toNativeMem(Pointer<NativeType> dst, int byteCnt,
      [int srcByteOffset = 0, int dstByteOffset = 0]) {
    final src = Pointer<Uint8>.fromAddress(address + srcByteOffset);
    final tgt = Pointer<Uint8>.fromAddress(dst.address + dstByteOffset);
    for (var i = 0; i < byteCnt; i++) {
      tgt[i] = src[i];
    }
  }

  /// Copies a sequence of bytes from native memory to Dart memory.
  ///
  /// This method allocates a new Uint8List (in Dart memory space),
  /// and then copies [byteCnt] bytes from location `[this + srcByteOffset]`
  /// to the resulting list.
  Uint8List toDartMem(int byteCnt, [int srcByteOffset = 0]) {
    final res = Uint8List(byteCnt);
    final src = Pointer<Uint8>.fromAddress(address + srcByteOffset);
    for (var i = 0; i < byteCnt; i++) {
      res[i] = src[i];
    }
    return res;
  }

  /// Copies a sequence of bytes from Dart memory to native memory.
  ///
  /// This method does not allocate any native memory, the pointer
  /// this method is invoked on should point to a previously allocated buffer
  /// (with the size at least [dstOffset] + [byteCnt]).
  /// The method copies [byteCnt] bytes (by default the whole [src] list),
  /// starting at offset [srcOffset] to the location [this] + [dstOffset]
  /// ([dstOffset] is given in bytes, regardless of the actual type
  /// this pointer is pointing to).
  void fromDartMem(Uint8List src,
      [int? byteCnt, int srcOffset = 0, int dstOffset = 0]) {
    final dst = Pointer<Uint8>.fromAddress(address + dstOffset);
    byteCnt ??= src.length;
    for (var i = 0; i < byteCnt; i++) {
      dst[i] = src[i + srcOffset];
    }
  }

  /// Copies a sequence of bytes from a native buffer to this buffer.
  ///
  /// This method copies [byteCnt] subsequent bytes from [src],
  /// starting at index [srcOffset], to this buffer at index
  /// [dstOffset].
  void fromNativeMem(Pointer<NativeType> src, int byteCnt,
      [int srcOffset = 0, int dstOffset = 0]) {
    final sbuf = Pointer<Uint8>.fromAddress(src.address + srcOffset);
    final dbuf = Pointer<Uint8>.fromAddress(address + dstOffset);
    for (var i = 0; i < byteCnt; i++) {
      dbuf[i] = sbuf[i];
    }
  }

  /// Sets the value in a series of bytes in the buffer.
  ///
  /// All [byteCnt] consecutive bytes, starting at the byte offset
  /// [offset] (the offset is measured in bytes, regardless of the
  /// actual type this pointer is pointing to), are set to [value].
  ///
  /// Example:
  /// ```dart
  /// // allocate and zero a buffer
  /// Pointer<Uint8> buf = mem.allocate(1024);
  /// buf.setAllBytes(1024, 0);
  /// ```
  void setAllBytes(int byteCnt, int value, [int offset = 0]) {
    final dst = Pointer<Uint8>.fromAddress(address + offset);
    for (var i = 0; i < byteCnt; i++) {
      dst[i] = value;
    }
  }
}

/// An extension implementing pointer arithmetic on native pointers.
///
/// This extension allows to obtain a new native pointer by shifting
/// an existing pointer by a specified byte offset.
///
/// Example:
/// ```dart
/// Pointer<Uint8> buf = mem.alloc(128);
/// // data points to the part of buf starting at offset 16
/// // the calculated pointer is cast to the valid type
/// // so that it can be assigned to data, which is a pointer
/// // of a different type
/// Pointer<Int64> data = (buf+16).cast();
/// ```
extension PointerArithmetic on Pointer<NativeType> {
  /// Returns a pointer shifted right (increased) by a specified offset.
  Pointer<NativeType> operator +(int byteOffset) {
    return Pointer<NativeType>.fromAddress(address + byteOffset);
  }

  /// Returns a pointer shifted left (decreased) by a specified offset.
  Pointer<NativeType> operator -(int byteOffset) {
    return Pointer<NativeType>.fromAddress(address - byteOffset);
  }
}

/// Determine the minimum number of bytes required to represent
/// [value] as a native signed int.
/// Returns 1, 2, 4 or 8.
int byteCountForInt(int value) {
  return switch (value) {
    >= -0x80 && < 0x80 => 1,
    >= -0x8000 && < 0x8000 => 2,
    >= -0x80000000 && < 0x80000000 => 4,
    _ => 8,
  };
}

/// Determine the minimum number of bytes required to represent
/// [value] as a native unsigned int.
/// Returns 1, 2, 4 or 8.
int byteCountForUint(int value) {
  return switch (value) {
    <= 0xFF => 1,
    <= 0xFFFF => 2,
    <= 0xFFFFFFFF => 4,
    _ => 8,
  };
}

/// A debugging (tracing) native memory allocator.
///
/// Keeps track of each allocation and release of native memory.
/// Can be queried for statistics.
/// Obviously it's less efficient than a naked calloc, so it's supposed
/// to be used only for debugging / profiling.
/// Example code using this allocator can be found in
/// `example/fbdb/ex_11_mem_benchmark.dart`.
class TracingAllocator implements Allocator {
  /// The actual allocator
  Allocator alloc = calloc;

  /// All currently allocated native memory blocks.
  ///
  /// Keys are memory addresses, values are block sizes in bytes.
  Map<int, int> allocatedBlocks = {};

  /// Total currently allocated memory.
  int allocated = 0;

  /// The sum of all allocated memory.
  int allocatedSum = 0;

  /// Total freed memory.
  int freedSum = 0;

  /// The maximum allocated memory up to date.
  int maxAllocated = 0;

  /// The number of allocations (calls to allocate).
  int allocationCount = 0;

  /// The number of releases (calls to free).
  int freeCount = 0;

  /// Allocates a native memory block of the given size,
  /// updating the statistics.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final block = alloc.allocate<T>(byteCount, alignment: alignment);
    allocatedBlocks[block.address] = byteCount;
    allocationCount++;
    allocated += byteCount;
    allocatedSum += byteCount;
    if (allocated > maxAllocated) {
      maxAllocated = allocated;
    }
    return block;
  }

  /// Frees up a native memory block, updating the statistics.
  @override
  void free(Pointer<NativeType> pointer) {
    freeCount++;
    if (!allocatedBlocks.containsKey(pointer.address)) {
      throw MemException(
        "TracingAllocator.free: memory @ ${pointer.address} "
        "has not been previously allocated",
      );
    }
    final blockSize = allocatedBlocks[pointer.address] ?? 0;
    allocatedBlocks.remove(pointer.address);
    freedSum += blockSize;
    allocated -= blockSize;
    alloc.free(pointer);
  }

  /// Returns the textual representation of the current memory
  /// statistics.
  @override
  String toString() {
    return """
Allocation count:         ${allocationCount.toString().padLeft(10)}
Release count:            ${freeCount.toString().padLeft(10)}
Total allocated memory:   ${allocatedSum.toString().padLeft(10)} B
Total released memory:    ${freedSum.toString().padLeft(10)} B
Peak allocated memory:    ${maxAllocated.toString().padLeft(10)} B
Memory allocated now:     ${allocated.toString().padLeft(10)} B
""";
  }

  /// Returns a structured representation of the current memory statistics.
  ///
  /// The keys in the map are:
  /// - allocationCount - the number of times [TracingAllocator.allocate]
  ///   has been called
  /// - freeCount - the number of times [TracingAllocator.free] has been called
  /// - allocatedSum - the cumulative sum of all allocated memory blocks
  /// - freedSum - the cumulative sum of all released memory blocks
  /// - maxAllocated - the maximum amount of native memory allocated so far
  /// - allocated - the amount of currently allocated native memory
  ///
  /// If there are no memory leaks, at the end of the application life
  /// the allocationCount and freeCount should be equal, as should be
  /// allocatedSum and freedSum, and the value of allocated should be 0.
  Map<String, int> toMap() {
    return {
      "allocationCount": allocationCount,
      "freeCount": freeCount,
      "allocatedSum": allocatedSum,
      "freedSum": freedSum,
      "maxAllocated": maxAllocated,
      "allocated": allocated,
    };
  }
}
