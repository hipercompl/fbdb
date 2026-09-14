import "dart:math";
import "dart:convert";
import "dart:typed_data";
import "dart:ffi";

import "package:ffi/ffi.dart";
import "package:fbdb/fbclient.dart";
import "package:fbdb/fbdb.dart";

import "fbdbworker.dart";

/// Truncates the trailing spaces of a string
/// so that the resulting string has up to ceil(length / 4)
/// characters.
String truncTrailingSpaces(String txt, int byteLength, int encoding) {
  // encodings: 0 = NONE, 1 = ASCII, 2 = OCTETS
  // see RDB$CHARACTER_SETS system table
  if (encoding > 2) {
    const maxBytesPerCodePoint = 4;
    final sl = byteLength ~/ maxBytesPerCodePoint;
    return String.fromCharCodes(txt.runes.take(sl)).padRight(sl);
    //return txt.substring(0, sl).padRight(sl);
  } else {
    return txt;
  }
}

/// Determines the value myltiplier for the given number of scale digits.
double _scaleMultiplier(int scaleDigits) {
  const scaleMultipliers = [
    1.0,
    10.0,
    100.0,
    1000.0,
    10000.0,
    100000.0,
    1000000.0,
    10000000.0,
    100000000.0,
  ];
  final scaleIndex = scaleDigits.abs();
  final scaleMul = scaleIndex < scaleMultipliers.length
      ? scaleMultipliers[scaleIndex]
      : pow(10.0, scaleIndex).toDouble();
  return scaleDigits >= 0 ? scaleMul : 1.0 / scaleMul;
}

/// Converts a floating point value to a scaled integer.
///
/// Takes [value] and produces an integer by mutiplying [value]
/// by 10 to the power of -[scaleDigits].
/// Note, that negative [scaleDigits] scale up, positive scale down.
///
/// Example:
/// ```dart
/// assert(_scaled(1.0, -3) == 1000.0);
/// assert(_scaled(500.0, 2) == 5.0);
/// ```
int scaled(double value, int scaleDigits) {
  if (scaleDigits == 0) {
    return value.toInt();
  }
  return (value * _scaleMultiplier(-scaleDigits)).round().toInt();
}

/// Converts a scaled integer to unscaled floating point.
///
/// Takes [value] and produces a double by dividing [value]
/// by 10^-[scaleDigits].
///
/// Example:
/// ```dart
/// assert(_unscaled(1000, -3) == 1.0);
/// assert(_unscaled(5.0, 2) == 500.0);
/// ```
double unscaled(int value, int scaleDigits) {
  if (scaleDigits == 0) {
    return value.toDouble();
  }
  return (value / _scaleMultiplier(-scaleDigits));
}

/// Converts a dynamic object into a byte buffer.
///
/// Handles the following data classes:
/// - String: returns bytes of the UTF-8 encoded text
/// - TypedData: returns the underlying buffer
/// - ByteBuffer: returns the buffer as is
///
/// For all other types a conversion error will be thrown.
ByteBuffer asByteBuffer(dynamic data) {
  if (data is String) {
    return utf8.encode(data).buffer;
  } else if (data is TypedData) {
    return data.buffer;
  } else {
    return data as ByteBuffer;
  }
}

/// Decodes a date from the provided value.
///
/// Uses IUtil to do the actual decoding.
DateTime decodeDate(int date, IUtil util, Pointer<Uint8> buffer) {
  Pointer<UnsignedInt> parts = buffer.cast();
  final s = sizeOf<UnsignedInt>();
  util.decodeDate(
    date,
    parts,
    Pointer<UnsignedInt>.fromAddress(parts.address + s),
    Pointer<UnsignedInt>.fromAddress(parts.address + 2 * s),
  );
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Decodes time from the provided value.
///
/// Uses IUtil to do the actual decoding.
DateTime decodeTime(int time, IUtil util, Pointer<Uint8> buffer) {
  Pointer<UnsignedInt> parts = buffer.cast();
  final s = sizeOf<UnsignedInt>();
  util.decodeTime(
    time,
    parts,
    Pointer<UnsignedInt>.fromAddress(parts.address + s),
    Pointer<UnsignedInt>.fromAddress(parts.address + 2 * s),
    Pointer<UnsignedInt>.fromAddress(parts.address + 3 * s),
  );
  return DateTime(
    1,
    1,
    1,
    parts[0],
    parts[1],
    parts[2],
    parts[3] ~/ 10,
    (parts[3] % 10) * 100,
  );
}

/// Decodes date and time, based on the provided native structure.
DateTime _decodeTimestamp(
  Pointer<IscTimestamp> ts,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  final d = decodeDate(ts.ref.date, util, buffer);
  final t = decodeTime(ts.ref.time, util, buffer);
  return DateTime(
    d.year,
    d.month,
    d.day,
    t.hour,
    t.minute,
    t.second,
    t.millisecond,
    t.microsecond,
  );
}

/// Retrieves a timestamp value from the message.
DateTime getTimestamp(
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  return _decodeTimestamp((msg + offset).cast(), util, buffer);
}

/// Gets the timestamp from the message.
///
/// Since Dart currently doesn't support arbitrary time zones,
/// for now it silently ignores the time zone, returning just
/// the timestamp.
DateTime getTimestampTZ(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  Pointer<UnsignedInt> ts = buffer.cast();
  util.decodeTimeStampTz(
    status,
    (msg + offset).cast(),
    ts, // year
    (ts + sizeOf<UnsignedInt>()).cast(), // month
    (ts + 2 * sizeOf<UnsignedInt>()).cast(), // day
    (ts + 3 * sizeOf<UnsignedInt>()).cast(), // hours
    (ts + 4 * sizeOf<UnsignedInt>()).cast(), // minutes
    (ts + 5 * sizeOf<UnsignedInt>()).cast(), // seconds
    (ts + 6 * sizeOf<UnsignedInt>()).cast(), // fractions
    0, // timeZoneBufferLength
    nullptr, // timeZoneBuffer
  );

  return DateTime(
    ts[0], // year
    ts[1], // month
    ts[2], // day
    ts[3], // hour
    ts[4], // minute
    ts[5], // second
    ts[6] ~/ 10, // millisecond
    (ts[6] % 10) * 100, // microsecond
  );
}

/// Gets the timestamp from the message.
///
/// Since Dart currently doesn't support arbitrary time zones,
/// for now it silently ignores the time zone, returning just
/// the timestamp.
DateTime getTimestampTZEx(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
  int bufferSize,
) {
  Pointer<UnsignedInt> ts = buffer.cast();
  final soui = sizeOf<UnsignedInt>();
  util.decodeTimeStampTzEx(
    status,
    (msg + offset).cast(),
    ts, // year
    (ts + soui).cast(), // month
    (ts + 2 * soui).cast(), // day
    (ts + 3 * soui).cast(), // hours
    (ts + 4 * soui).cast(), // minutes
    (ts + 5 * soui).cast(), // seconds
    (ts + 6 * soui).cast(), // fractions
    bufferSize - 7 * soui, // timeZoneBufferLength
    (ts + 7 * soui).cast(), // timeZoneBuffer
  );

  final Pointer<IscTimestampTzEx> ttzBuf = (msg + offset).cast();

  return FbDateTimeTZ(
    year: ts[0],
    month: ts[1],
    day: ts[2],
    hour: ts[3],
    minute: ts[4],
    second: ts[5],
    millisecond: ts[6] ~/ 10,
    tenthMillisecond: ts[6] % 10,
    timeZoneName: (ts + 7 * soui).cast<Utf8>().toDartString(),
    timeZoneOffset: Duration(minutes: ttzBuf.ref.extOffset),
  );
}

/// Gets time with time zone from the message.
///
/// Currently, the actual time zone is ignored, as Dart's DateTime
/// doesn't support arbitrary time zones.
DateTime getTimeTZ(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  Pointer<UnsignedInt> ts = buffer.cast();
  util.decodeTimeTz(
    status,
    (msg + offset).cast(),
    ts, // hours
    (ts + sizeOf<UnsignedInt>()).cast(), // minutes
    (ts + 2 * sizeOf<UnsignedInt>()).cast(), // seconds
    (ts + 3 * sizeOf<UnsignedInt>()).cast(), // fractions
    0,
    nullptr,
  );
  return DateTime(
    1, // year
    1, // month
    1, // day
    ts[0], // hour
    ts[1], // minute
    ts[2], // second
    ts[3] ~/ 10, // millisecond
    (ts[3] % 10) * 100, // microsecond
  );
}

/// Gets time with time zone from the message.
///
/// Currently, the actual time zone is ignored, as Dart's DateTime
/// doesn't support arbitrary time zones.
DateTime getTimeTZEx(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
  int bufferSize,
) {
  Pointer<UnsignedInt> ts = buffer.cast();
  final soui = sizeOf<UnsignedInt>();

  util.decodeTimeTzEx(
    status,
    (msg + offset).cast(),
    ts, // hours
    (ts + soui).cast(), // minutes
    (ts + 2 * soui).cast(), // seconds
    (ts + 3 * soui).cast(), // fractions
    bufferSize - 4 * soui,
    (ts + 4 * soui).cast(),
  );

  final Pointer<IscTimeTzEx> ttzBuf = (msg + offset).cast();

  return FbDateTimeTZ(
    hour: ts[0],
    minute: ts[1],
    second: ts[2],
    millisecond: ts[3] ~/ 10,
    tenthMillisecond: ts[3] % 10,
    timeZoneName: (ts + 4 * soui).cast<Utf8>().toDartString(),
    timeZoneOffset: Duration(minutes: ttzBuf.ref.extOffset),
  );
}

/// Retrieves a quad (IscQuad / FbQuad) value from the message.
FbQuad getQuad(
  Pointer<Uint8> msg,
  int offset,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  Pointer<IscQuad> q = buffer.cast();
  msg.toNativeMem(q, sizeOf<IscQuad>(), offset);
  return FbQuad(q.ref.iscQuadHigh, q.ref.iscQuadLow);
}

/// Retrieves a value of type DECIMAL (DEC16) from the message.
///
/// The implementation is currently inefficient, as it uses
/// intermediate string representation to tranlate a DEC16
/// into a double.
double getDec16(IStatus status, Pointer<Uint8> msg, int offset, IUtil util) {
  final iDec = util.getDecFloat16(status);
  final s = iDec.toStr(status, (msg + offset).cast());
  return double.parse(s);
}

/// Retrieves a value of type DECIMAL (DEC34) from the message.
///
/// The implementation is currently inefficient, as it uses
/// intermediate string representation to tranlate an DEC34
/// into a double.
double getDec34(IStatus status, Pointer<Uint8> msg, int offset, IUtil util) {
  final iDec = util.getDecFloat34(status);
  final s = iDec.toStr(status, (msg + offset).cast());
  return double.parse(s);
}

/// Retrieves an INT128 value from the message.
///
/// The implementation is currently inefficient, as it uses
/// intermediate string representation to tranlate an INT128
/// into a double.
double getInt128(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  int scale,
  IUtil util,
  Pointer<Uint8> buffer,
) {
  final i128 = util.getInt128(status);
  Pointer<FbI128> ii = buffer.cast();
  msg.toNativeMem(ii, sizeOf<FbI128>(), offset);
  return double.parse(i128.toStr(status, ii));
}

/// Retrieves just a blob ID from the message (not the blob data).
FbBlobId getBlobId(Pointer<Uint8> msg, int offset) {
  return FbBlobId.fromIscQuad((msg + offset).cast());
}

/// Retrieves blob data for the blob ID read from the message.
ByteBuffer getBlob(
  Pointer<Uint8> msg,
  int offset,
  FbDbWorker db,
  ITransaction? transaction,
  Pointer<Uint8> buffer,
  int bufferSize,
) {
  if (transaction == null) {
    throw FbClientException(
      "Cannot retrieve blobs outside transaction context",
    );
  }
  Pointer<IscQuad> blobId = (msg + offset).cast();
  IBlob? blob = db.attachment?.openBlob(db.status, transaction, blobId);
  if (blob == null) {
    throw FbClientException("Cannot open blob data for reading");
  }
  final List<Uint8List> segments = [];
  var totalLength = 0;
  try {
    // The internal buffer will be used both for read bytes count
    // and the actual data
    // The first sizeOf<UnsignedInt> bytes are used by segmentLength,
    // the rest of the internal buffer constitute blobBuf.
    Pointer<UnsignedInt> segmentLength = buffer.cast();
    Pointer<Uint8> blobBuf = (buffer + sizeOf<UnsignedInt>()).cast();
    int maxCnt = bufferSize - sizeOf<UnsignedInt>();
    for (;;) {
      final rc = blob.getSegment(db.status, maxCnt, blobBuf, segmentLength);
      if ([IStatus.resultOK, IStatus.resultSegment].contains(rc) &&
          segmentLength.value > 0) {
        totalLength += segmentLength.value;
        segments.add(blobBuf.toDartMem(segmentLength.value));
      } else {
        break;
      }
    }
    blob.close(db.status);
    blob = null;
    final result = Uint8List(totalLength);
    var offset = 0;
    for (var segment in segments) {
      result.setAll(offset, segment);
      offset += segment.length;
    }
    return result.buffer;
  } finally {
    blob?.release();
  }
}

/// Retrieves a single value from the message buffer.
///
/// Retrieves the value at index [index] from [msg], calculating
/// offsets using the message metadata in [meta].
/// Returned data type varies, depending on the type of the value
/// in [msg]. If the field at index [index] in [msg] contains the null flag,
/// null is returned.
/// [status] is used for error checking (must be a valid IStatus
/// interface instance).
dynamic getRowValue(
  IStatus status,
  Pointer<Uint8> msg,
  IMessageMetadata meta,
  int index,
  FbDbWorker db,
  ITransaction? transaction,
  IUtil util,
  Pointer<Uint8> buffer,
  int bufferSize,
  bool inlineBlobs,
) {
  int nullOffset = meta.getNullOffset(status, index);
  int isNull = msg.readUint16(nullOffset);
  if (isNull > 0) {
    return null;
  }
  int offset = meta.getOffset(status, index);
  int type = meta.getType(status, index);
  int scale = meta.getScale(status, index);
  int length = meta.getLength(status, index);

  switch (type) {
    case FbConsts.SQL_TEXT:
    case const (FbConsts.SQL_TEXT + 1):
      final s = msg.readString(offset, length);
      final enc = meta.getCharSet(status, index);
      return truncTrailingSpaces(s, length, enc);

    case FbConsts.SQL_VARYING:
    case const (FbConsts.SQL_VARYING + 1):
      return msg.readVarchar(offset);

    case FbConsts.SQL_SHORT:
    case const (FbConsts.SQL_SHORT + 1):
      final v = msg.readInt16(offset);
      return scale != 0 ? unscaled(v, scale) : v;

    case FbConsts.SQL_LONG:
    case const (FbConsts.SQL_LONG + 1):
      final v = msg.readInt32(offset);
      return scale != 0 ? unscaled(v, scale) : v;

    case FbConsts.SQL_FLOAT:
    case const (FbConsts.SQL_FLOAT + 1):
      return msg.readFloat(offset);

    case FbConsts.SQL_DOUBLE:
    case const (FbConsts.SQL_DOUBLE + 1):
      return msg.readDouble(offset);

    case FbConsts.SQL_TIMESTAMP:
    case const (FbConsts.SQL_TIMESTAMP + 1):
      return getTimestamp(msg, offset, util, buffer);

    case FbConsts.SQL_BLOB:
    case const (FbConsts.SQL_BLOB + 1):
      return inlineBlobs
          ? getBlob(msg, offset, db, transaction, buffer, bufferSize)
          : getBlobId(msg, offset);

    case FbConsts.SQL_QUAD:
    case const (FbConsts.SQL_QUAD + 1):
      return getQuad(msg, offset, util, buffer);

    case FbConsts.SQL_TYPE_TIME:
    case const (FbConsts.SQL_TYPE_TIME + 1):
      return decodeTime(msg.readUint32(offset), util, buffer);

    case FbConsts.SQL_TYPE_DATE:
    case const (FbConsts.SQL_TYPE_DATE + 1):
      return decodeDate(msg.readInt32(offset), util, buffer);

    case FbConsts.SQL_INT64:
    case const (FbConsts.SQL_INT64 + 1):
      final v = msg.readInt64(offset);
      return scale != 0 ? unscaled(v, scale) : v;

    case FbConsts.SQL_INT128:
    case const (FbConsts.SQL_INT128 + 1):
      return getInt128(status, msg, offset, scale, util, buffer);

    case FbConsts.SQL_TIMESTAMP_TZ:
    case const (FbConsts.SQL_TIMESTAMP_TZ + 1):
      return getTimestampTZ(status, msg, offset, util, buffer);

    case FbConsts.SQL_TIME_TZ:
    case const (FbConsts.SQL_TIME_TZ + 1):
      return getTimeTZ(status, msg, offset, util, buffer);

    case FbConsts.SQL_TIME_TZ_EX:
    case const (FbConsts.SQL_TIME_TZ_EX + 1):
      return getTimeTZEx(status, msg, offset, util, buffer, bufferSize);

    case FbConsts.SQL_TIMESTAMP_TZ_EX:
    case const (FbConsts.SQL_TIMESTAMP_TZ_EX + 1):
      return getTimestampTZEx(status, msg, offset, util, buffer, bufferSize);

    case FbConsts.SQL_DEC16:
    case const (FbConsts.SQL_DEC16 + 1):
      return getDec16(status, msg, offset, util);

    case FbConsts.SQL_DEC34:
    case const (FbConsts.SQL_DEC34 + 1):
      return getDec34(status, msg, offset, util);

    case FbConsts.SQL_BOOLEAN:
    case const (FbConsts.SQL_BOOLEAN + 1):
      return msg.readUint8(offset) != 0;

    case FbConsts.SQL_NULL:
      return msg.readInt16(nullOffset) == 1 ? null : false;

    default:
      throw FbClientException(
        "Firebird data type (code $type) not implemented",
      );
  }
}

/// Gets all field values from the msg, according to the otputMetadata.
List<dynamic> getRowValues(
  Pointer<Uint8> msg,
  IMessageMetadata? metadata,
  FbDbWorker db,
  ITransaction? transaction,
  IUtil util,
  Pointer<Uint8> buffer,
  int bufferSize,
  bool inlineBlobs,
) {
  if (metadata == null) {
    throw FbClientException(
      "Cannot access row data - no output metadata available",
    );
  }
  final List<dynamic> res = [];
  int colCount = metadata.getCount(db.status);
  for (var i = 0; i < colCount; i++) {
    final val = getRowValue(
      db.status,
      msg,
      metadata,
      i,
      db,
      transaction,
      util,
      buffer,
      bufferSize,
      inlineBlobs,
    );
    res.add(val);
  }
  return res;
}

/// Puts a constant-length string into the message [msg] at offset [offset].
///
/// Right-pads the string after converting it to UTF-8
/// to fill the required length.
/// For character set OCTETS the string is padded with 0x00, for all other
/// character sets it's padded with 0x20 (spaces).
/// See https://groups.google.com/g/firebird-support/c/06aNT1ZieOk
void putChar(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  String value,
  int length,
  IMessageMetadata meta,
  int index,
) {
  var encoded = utf8.encode(value);
  Uint8List toWrite;
  if (encoded.length < length) {
    // right-pad the UTF-8 string to the required length
    // char set == 1 (OCTETS) => pad with 0, otherwise pad with space
    final padCode = meta.getCharSet(status, index) == 1 ? 0x00 : 0x20;
    List<int> pad = List<int>.filled(length - encoded.length, padCode);
    toWrite = Uint8List.fromList(encoded + pad);
  } else if (encoded.length > length) {
    toWrite = encoded.sublist(0, length);
  } else {
    toWrite = encoded;
  }
  msg.fromDartMem(toWrite, length, 0, offset);
}

/// Puts date part from [dt] into the message [msg] at offset [offset].
void putDate(Pointer<Uint8> msg, int offset, DateTime dt, IUtil util) {
  int encoded;
  if (dt is FbDateTimeTZ) {
    encoded = util.encodeDate(dt.db.year, dt.db.month, dt.db.day);
  } else {
    encoded = util.encodeDate(dt.year, dt.month, dt.day);
  }
  msg.writeInt32(offset, encoded);
}

/// Puts time part from [dt] into the message [msg] at offset [offset].
void putTime(Pointer<Uint8> msg, int offset, DateTime dt, IUtil util) {
  int encoded;
  if (dt is FbDateTimeTZ) {
    encoded = util.encodeTime(
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
    );
  } else {
    encoded = util.encodeTime(
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
    );
  }
  msg.writeUint32(offset, encoded);
}

/// Puts time part from [dt] into the message [msg] at offset [offset].
///
/// Appends time zone info.
void putTimeTZ(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  DateTime dt,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final Pointer<IscTimeTz> t = buffer.cast();
  if (dt is FbDateTimeTZ) {
    util.encodeTimeTz(
      status,
      t,
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
      dt.db.timeZone,
    );
  } else {
    util.encodeTimeTz(
      status,
      t,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
      dt.timeZoneName,
    );
  }
  msg.fromNativeMem(t, sizeOf<IscTimeTz>(), 0, offset);
}

/// Puts time part from [dt] into the message [msg] at offset [offset].
///
/// Appends time zone info. Uses the extended ISC timestamp structure,
/// setting the time zone offset in its extOffset field.
void putTimeTZEx(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  DateTime dt,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final Pointer<IscTimeTzEx> t = buffer.cast();
  if (dt is FbDateTimeTZ) {
    util.encodeTimeTz(
      status,
      t.cast(),
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
      dt.db.timeZone,
    );
    t.ref.extOffset = dt.db.timeZoneOffset.inMinutes;
  } else {
    util.encodeTimeTz(
      status,
      t.cast(),
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
      // Cannot use dt.timeZoneName here.
      // DateTime.timeZoneName returns localized time zones,
      // translated to the host system language, unacceptable
      // by Firebird.
      // Instead, we have to use +/-HH:MM as the time zone name.
      DBDateTimeTZ.timeZoneToString(dt.timeZoneOffset),
    );
    t.ref.extOffset = dt.timeZoneOffset.inMinutes;
  }
  msg.fromNativeMem(t, sizeOf<IscTimeTz>(), 0, offset);
}

/// Puts date and time from [dt] into the message [msg] at offset [offset].
void putTimestamp(
  Pointer<Uint8> msg,
  int offset,
  DateTime dt,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final Pointer<IscTimestamp> ts = buffer.cast();
  if (dt is FbDateTimeTZ) {
    ts.ref.date = util.encodeDate(dt.db.year, dt.db.month, dt.db.day);
    ts.ref.time = util.encodeTime(
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
    );
  } else {
    ts.ref.date = util.encodeDate(dt.year, dt.month, dt.day);
    ts.ref.time = util.encodeTime(
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
    );
  }
  msg.fromNativeMem(ts, sizeOf<IscTimestamp>(), 0, offset);
}

/// Puts date and time from [dt] into the message [msg] at offset [offset].
///
/// Appends time zone info.
void putTimestampTZ(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  DateTime dt,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final Pointer<IscTimestampTz> ts = buffer.cast();
  if (dt is FbDateTimeTZ) {
    util.encodeTimeStampTz(
      status,
      ts,
      dt.db.year,
      dt.db.month,
      dt.db.day,
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
      dt.db.timeZone,
    );
  } else {
    util.encodeTimeStampTz(
      status,
      ts,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
      dt.timeZoneName,
    );
  }
  msg.fromNativeMem(ts, sizeOf<IscTimestampTz>(), 0, offset);
}

/// Puts date and time from [dt] into the message [msg] at offset [offset].
///
/// Appends time zone info. Uses the extended ISC timestamp structure,
/// setting the time zone offset in its extOffset field.
void putTimestampTZEx(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  DateTime dt,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final Pointer<IscTimestampTzEx> ts = buffer.cast();
  if (dt is FbDateTimeTZ) {
    util.encodeTimeStampTz(
      status,
      ts.cast(),
      dt.db.year,
      dt.db.month,
      dt.db.day,
      dt.db.hour,
      dt.db.minute,
      dt.db.second,
      dt.db.millisecond * 10 + dt.db.tenthMillisecond,
      dt.db.timeZone,
    );
    ts.ref.extOffset = dt.db.timeZoneOffset.inMinutes;
  } else {
    util.encodeTimeStampTz(
      status,
      ts.cast(),
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond * 10 + dt.microsecond ~/ 100,
      // Cannot use dt.timeZoneName here.
      // DateTime.timeZoneName returns localized time zones,
      // translated to the host system language, unacceptable
      // by Firebird.
      // Instead, we have to use +/-HH:MM as the time zone name.
      DBDateTimeTZ.timeZoneToString(dt.timeZoneOffset),
    );
    ts.ref.extOffset = dt.timeZoneOffset.inMinutes;
  }
  msg.fromNativeMem(ts, sizeOf<IscTimestampTz>(), 0, offset);
}

/// Puts a floating point value into the message as a scaled integer.
///
/// Scales [value] by 10^[scale] and stores it in [msg] as 128-bit integer
/// at offset [offset].
/// Note: currently uses intermediate string representation, which is far
/// from optimal in terms of efficiency. Will be re-implemented in future
/// versions.
void putInt128(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  double value,
  int scale,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  // Current implementation converts the double value to string
  // and then uses Int128 interface to convert the string to
  // the int128-backed scaled value.
  // This is probably inefficient and requires further optimization.
  final i128 = util.getInt128(status);
  final s = value.toString();
  Pointer<FbI128> ii = buffer.cast();
  i128.fromStr(status, scale, s, ii);
  msg.fromNativeMem(ii, sizeOf<FbI128>(), 0, offset);
}

/// Stores a floating point value as dec16 decimal value.
///
/// Note: currently uses intermediate string representation, which is far
/// from optimal in terms of efficiency. Will be re-implemented in future
/// versions.
void putDec16(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  double value,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final iDec = util.getDecFloat16(status);
  final s = value.toString();
  Pointer<FbDec16> d = buffer.cast();
  iDec.fromStr(status, s, d);
  msg.fromNativeMem(d, sizeOf<FbDec16>(), 0, offset);
}

/// Stores a floating point value as dec34 decimal value.
///
/// Note: currently uses intermediate string representation, which is far
/// from optimal in terms of efficiency. Will be re-implemented in future
/// versions.
void putDec34(
  IStatus status,
  Pointer<Uint8> msg,
  int offset,
  double value,
  Pointer<Uint8> buffer,
  IUtil util,
) {
  final iDec = util.getDecFloat34(status);
  final s = value.toString();
  Pointer<FbDec34> d = buffer.cast();
  iDec.fromStr(status, s, d);
  msg.fromNativeMem(d, sizeOf<FbDec34>(), 0, offset);
}

/// Stores an isc_quad value in the message buffer.
void putQuad(
  Pointer<Uint8> msg,
  int offset,
  FbQuad value,
  Pointer<Uint8> buffer,
) {
  Pointer<IscQuad> q = buffer.cast();
  q.ref.iscQuadHigh = value.quadHigh;
  q.ref.iscQuadLow = value.quadLow;
  msg.fromNativeMem(q, sizeOf<IscQuad>(), 0, offset);
}

/// Creates a blob and stores its id in the message buffer.
void putBlob(
  Pointer<Uint8> msg,
  int offset,
  dynamic data,
  FbDbWorker db,
  ITransaction? transaction,
  Pointer<Uint8> buffer,
  int bufferSize,
  FbDbBatchWorker? batch,
) {
  if (transaction == null) {
    throw FbClientException("Cannot store blobs outside transaction context");
  }

  db.status.init();
  if (data is FbBlobId) {
    if (batch != null) {
      // register the blob in batch operation
      if (batch.batch == null) {
        throw FbClientException("Batch interface not present in batch object");
      }
      data.storeInQuad(buffer.cast());
      batch.batch?.registerBlob(
        db.status,
        buffer.cast(),
        // the new blob ID is stored directly in the message
        (msg + offset).cast(),
      );
    } else {
      // the blob has been already saved in the database
      // so we just store the provided ID in the message data
      data.storeInQuad((msg + offset).cast());
    }
  } else if (batch != null) {
    // add an inline blob via the batch API
    if (batch.batch == null) {
      throw FbClientException("Batch interface not present in batch object");
    }
    // we assume data is the actual blob buffer
    ByteBuffer binData = asByteBuffer(data);

    int stored = 0;
    int toStore = binData.lengthInBytes;

    // add the blob data in chunks, using the provided native buffer
    // (avoid additional native allocations)
    while (stored < toStore) {
      final chunkSize = min(toStore - stored, bufferSize);
      buffer.fromDartMem(binData.asUint8List(stored, chunkSize), chunkSize);
      if (stored == 0) {
        // the first part of the blob
        batch.batch?.addBlob(
          db.status,
          chunkSize,
          buffer,
          (msg + offset).cast(),
          0,
          nullptr,
        );
      } else {
        // a subsequent part of a blob
        batch.batch?.appendBlobData(db.status, chunkSize, buffer);
      }
      stored += chunkSize;
    }
  } else {
    // add the blob via the standard attachment API

    // we assume data is the actual blob buffer
    ByteBuffer binData = asByteBuffer(data);

    // we need to store the blob in the database
    // before passing its ID to the query
    IBlob? blob = db.attachment?.createBlob(
      db.status,
      transaction,
      (msg + offset).cast(),
    );
    if (blob == null) {
      throw FbClientException("Blob creation failed");
    }
    try {
      int stored = 0;
      int toStore = binData.lengthInBytes;
      while (stored < toStore) {
        final chunkSize = min(toStore - stored, bufferSize);
        buffer.fromDartMem(binData.asUint8List(stored, chunkSize), chunkSize);
        blob.putSegment(db.status, chunkSize, buffer);
        stored += chunkSize;
      }
      blob.close(db.status);
      blob = null;
    } finally {
      blob?.release();
    }
  }
}

/// Puts the value into the message buffer, respecting the message metadata.
///
/// The [value] has to comply with the type of the parameter at index [index].
/// It will be put into [msg] at the memory offset defined by [meta],
/// unless the [value] is null, in which case the null flag will be set
/// in the buffer.
/// [status] is used for error checking (must be a valid IStatus
/// interface instance).
void putParam(
  IStatus status,
  Pointer<Uint8> msg,
  IMessageMetadata meta,
  int index,
  dynamic value,
  FbDbWorker db,
  ITransaction? transaction,
  Pointer<Uint8> buffer,
  int bufferSize, {
  FbDbBatchWorker? batch,
}) {
  int nullOffset = meta.getNullOffset(status, index);
  if (value == null) {
    if (!meta.isNullable(status, index)) {
      throw FbClientException(
        "Parameter at index $index is not nullable (null requested)",
      );
    }
    msg.writeUint16(nullOffset, 1); // null value
    return;
  }
  msg.writeUint16(nullOffset, 0); // non-null value
  int type = meta.getType(status, index);
  int offset = meta.getOffset(status, index);
  int scale = meta.getScale(status, index);
  int length = meta.getLength(status, index);

  switch (type) {
    case FbConsts.SQL_TEXT:
    case const (FbConsts.SQL_TEXT + 1):
      putChar(status, msg, offset, value, length, meta, index);

    case FbConsts.SQL_VARYING:
    case const (FbConsts.SQL_VARYING + 1):
      // length + 2 because length reported by metadata
      // means the length of the field / parameter,
      // excluding the 2-byte unsigned short holding
      // the actual length of the text
      msg.writeVarchar(offset, value, length + 2);

    case FbConsts.SQL_SHORT:
    case const (FbConsts.SQL_SHORT + 1):
      msg.writeInt16(
        offset,
        scale != 0 ? scaled(value, scale) : (value as num).toInt(),
      );

    case FbConsts.SQL_LONG:
    case const (FbConsts.SQL_LONG + 1):
      msg.writeInt32(
        offset,
        scale != 0 ? scaled(value, scale) : (value as num).toInt(),
      );

    case FbConsts.SQL_FLOAT:
    case const (FbConsts.SQL_FLOAT + 1):
      msg.writeFloat(offset, (value as num).toDouble());

    case FbConsts.SQL_DOUBLE:
    case const (FbConsts.SQL_DOUBLE + 1):
      msg.writeDouble(offset, (value as num).toDouble());

    case FbConsts.SQL_TIMESTAMP:
    case const (FbConsts.SQL_TIMESTAMP + 1):
      putTimestamp(msg, offset, value, buffer, db.util);

    case FbConsts.SQL_BLOB:
    case const (FbConsts.SQL_BLOB + 1):
      putBlob(msg, offset, value, db, transaction, buffer, bufferSize, batch);

    case FbConsts.SQL_QUAD:
    case const (FbConsts.SQL_QUAD + 1):
      putQuad(msg, offset, value, buffer);

    case FbConsts.SQL_TYPE_TIME:
    case const (FbConsts.SQL_TYPE_TIME + 1):
      putTime(msg, offset, value, db.util);

    case FbConsts.SQL_TYPE_DATE:
    case const (FbConsts.SQL_TYPE_DATE + 1):
      putDate(msg, offset, value, db.util);

    case FbConsts.SQL_INT64:
    case const (FbConsts.SQL_INT64 + 1):
      msg.writeInt64(
        offset,
        scale != 0 ? scaled(value, scale) : (value as num).toInt(),
      );

    case FbConsts.SQL_INT128:
    case const (FbConsts.SQL_INT128 + 1):
      putInt128(status, msg, offset, value, scale, buffer, db.util);

    case FbConsts.SQL_TIMESTAMP_TZ:
    case const (FbConsts.SQL_TIMESTAMP_TZ + 1):
      putTimestampTZ(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_TIMESTAMP_TZ_EX:
    case const (FbConsts.SQL_TIMESTAMP_TZ_EX + 1):
      putTimestampTZEx(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_TIME_TZ:
    case const (FbConsts.SQL_TIME_TZ + 1):
      putTimeTZ(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_TIME_TZ_EX:
    case const (FbConsts.SQL_TIME_TZ_EX + 1):
      putTimeTZEx(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_DEC16:
    case const (FbConsts.SQL_DEC16 + 1):
      putDec16(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_DEC34:
    case const (FbConsts.SQL_DEC34 + 1):
      putDec34(status, msg, offset, value, buffer, db.util);

    case FbConsts.SQL_BOOLEAN:
    case const (FbConsts.SQL_BOOLEAN + 1):
      msg.writeUint8(offset, value ? 1 : 0);

    case FbConsts.SQL_NULL:
      msg.writeInt16(nullOffset, value == null ? 1 : 0);

    default:
      throw FbClientException(
        "Firebird data type (code $type) not implemented",
      );
  }
}

/// Puts all params inside msg, according to the inputMetadata
void putParams(
  Pointer<Uint8> msg,
  IMessageMetadata? metadata,
  List<dynamic> params,
  IStatus status,
  FbDbWorker db,
  ITransaction? transaction,
  Pointer<Uint8> buffer,
  int bufferSize, {
  FbDbBatchWorker? batch,
}) {
  if (metadata == null) {
    throw FbClientException(
      "Cannot parametrize query - no input metadata available",
    );
  }
  final totalLen = metadata.getMessageLength(status);
  msg.setAllBytes(totalLen, 0);
  for (var i = 0; i < params.length; i++) {
    putParam(
      db.status,
      msg,
      metadata,
      i,
      params[i],
      db,
      transaction,
      buffer,
      bufferSize,
      batch: batch,
    );
  }
}
