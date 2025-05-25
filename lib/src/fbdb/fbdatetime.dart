/// A specialized DateTime to represent time/timestamp with time zone
/// retrieved from the database or to be passed as a query parameter
/// in order to store it in the database.
///
/// The [FbDateTimeTZ] treated as the standard [dart:core.DateTime]
/// always represents an instant of time in the **local time zone**
/// of the client machine.
/// However, it contains an additional component [db] of class [DBDateTimeTZ],
/// which keeps the actual date/time **and** the time zone, excatcly
/// as it was received from the database or is to be stored in it.
///
/// [FbDateTimeTZ] objects can be used in all places the standard
/// [dart:core.DateTime] objects are required. Just keep in mind,
/// that in such scenarios you'll always get the date/time
/// in your local time zone, so you need to call [dart:core.DateTime.toUtc]
/// if you need the date/time in UTC.
///
/// If you need to access the database representation, use the [db]
/// property and one of its sub-properties (`value.db.year`,
/// `value.db.timeZoneOffset`, etc.).
///
/// When an object of class [FbDateTimeTZ] is passed as a query parameter
/// (for a column of type TIME WITH TIME ZONE or TIMESTAMP WITH TIME ZONE),
/// the [db] part always takes precendence over the standard date/time
/// components inherited from [dart:core.DateTime].
/// This way, you can pass time or a timestamp in an arbitrary time
/// zone, not just local or UTC.
///
/// The time is kept with accuracy to 1/10 of a millisecond, because this
/// resolution is compatible with Firebird's TIME and TIMESTAMP types.
///
/// Example of creating a time-only value (the date part will be
/// fixed to 2020-01-01):
/// ```dart
/// final d = FbDateTimeTZ(
///   hour: 12,
///   minute: 5,
///   second: 15,
///   millisecond: 37,
///   tenthMillisecond: 4,
///   timeZoneName: "US/Eastern",
///   timeZoneOffset: Duration(hours: -5),
/// );
/// print(d.db.toString()); // "2020-01-01 12:05:15.0374 US/Eastern"
/// print(d.db.toDartString()); // "2020-01-01 12:05:15.0374 -05:00"
/// print(d.toUtc().toString()); // "2020-01-01 17:05:15.037400Z"
/// ```
///
/// Example of creating a timestamp value:
/// ```dart
/// final d = FbDateTimeTZ(
///   year: 2025,
///   month: 5,
///   day: 20,
///   hour: 10,
///   minute: 5,
///   second: 15,
///   millisecond: 37,
///   tenthMillisecond: 4,
///   timeZoneName: "US/Eastern",
///   timeZoneOffset: Duration(hours: -5),
/// );
/// print(d.toString()); // "2025-05-20 10:05:15.0374 US/Eastern"
/// print(d.db.toDartString()); // "2025-05-20 10:05:15.0374 -05:00"
/// print(d.toUtc().toSTring()); // "2025-05-20 15:05:15.037400Z"
/// ```
///
/// **NOTICE**: the time zone name and offset of [FbDateTimeTZ.db]
/// can be mismatched. There is no mechanism controlling the matching
/// of time zone offset with the actual time zone name.
/// That means, you can pass an arbitrary combination of time zone
/// name and offset and it will be accepted by the constructor,
/// resulting in an inconsistent behavior. The [FbDateTimeTZ.toString]
/// method will use the time zone name, while [FbDateTimeTZ.toDartString]
/// will use the zone offset. If those don't match, one method will
/// return a different instant of time than the other.
/// It is up to the client code to make sure the name of the time zone
/// and its actual offset correspond with each other.
class FbDateTimeTZ extends DateTime {
  /// The time or timestamp data, exactly as retrieved from the
  /// database or is to be stored in the database.
  /// In addition to the standard year, month, day, hours, minutes,
  /// seconds and milliseconds, it also contains tenthMilliseconds
  /// (1/10 of a millisecond), timeZoneName and timeZoneOffset.
  /// See also the [DBDateTimeTZ] class documentation.
  final DBDateTimeTZ db;

  /// Constructs a new [FbDateTimeTZ] instance, based on the database
  /// representation.
  ///
  /// The returned object treated as [dart:core.DateTime] will
  /// always be represented in the local time zone of the client,
  /// but the original database representation will be kept
  /// in its additional [db] property.
  factory FbDateTimeTZ.withDB(DBDateTimeTZ db) {
    return FbDateTimeTZ._init(DateTime.parse(db.toDartString()).toLocal(), db);
  }

  /// Constructs a new [FbDateTimeTZ] instance from the provided
  /// date / time components and a time zone.
  ///
  /// The returned object treated as [dart:core.DateTime] will
  /// always be represented in the local time zone of the client,
  /// but the original database representation will be kept
  /// in its additional [db] property.
  ///
  /// If you provide the [timeZoneName], it will have precedence
  /// over the zone offset when a FBDateTimeTZ object is passed
  /// to be stored in the database.
  /// If you construct [FbDateTimeTZ] by hand (and not retrieve it
  /// from the database), you need to make sure [timeZoneName]
  /// (if provided) and [timeZoneOffset] match each other, as no such
  /// checks are performed by the constructor.
  ///
  /// On the other hand, the part inherited from [dart:core.DateTime]
  /// is always initialized with the [timeZoneOffset], as the
  /// [dart:core.DateTime.parse] method does not accept the named
  /// time zones (and this method is used internally to initialize
  /// the year, month, day, hour, minute, second, millisecond,
  /// and microsecond values).
  factory FbDateTimeTZ({
    int year = 2020,
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int tenthMillisecond = 0,
    String timeZoneName = "",
    Duration timeZoneOffset = Duration.zero,
  }) {
    return FbDateTimeTZ.withDB(
      DBDateTimeTZ(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        tenthMillisecond: tenthMillisecond,
        timeZoneName: timeZoneName,
        timeZoneOffset: timeZoneOffset,
      ),
    );
  }

  // Internal constructor for the [dart:core.Datetime] part of the object.
  FbDateTimeTZ._init(DateTime src, this.db)
    : super(
        src.year,
        src.month,
        src.day,
        src.hour,
        src.minute,
        src.second,
        src.millisecond,
        src.microsecond,
      );
}

/// Represents values of the SQL type `TIME WITH TIME ZONE`
/// or `TIMESTAMP WITH TIME ZONE`.
///
/// The components of [DBDateTimeTZ] are related to the fields
/// of Firebird's structures `ISC_TIME_TZ_EX` / `ISC_TIMESTAMP_TZ_EX`.
/// The date and time components are rather self-explanatory.
/// The [timeZoneOffset] field contains the offset (in hours / minutes)
/// of the represented time instant with respect to UTC.
/// The [timeZoneName] field contains the actual time zone (there can be
/// many time zones for the same given zone offset).
///
/// Example of creating a time-only value (the date part will be
/// fixed to 2020-01-01):
/// ```dart
/// final d = DBDateTimeTZ(
///   hour: 17,
///   minute: 5,
///   second: 15,
///   millisecond: 37,
///   tenthMillisecond: 4,
///   timeZoneName: "US/Eastern",
///   timeZoneOffset: Duration(hours: -5),
/// );
/// print(d.toString()); // "2020-01-01 17:05:15.0374 US/Eastern"
/// print(d.toDartString()); // "2020-01-01 17:05:15.0374 -05:00"
/// ```
///
/// Example of creating a timestamp value:
/// ```dart
/// final d = DBDateTimeTZ(
///   year: 2025,
///   month: 5,
///   day: 20,
///   hour: 17,
///   minute: 5,
///   second: 15,
///   millisecond: 37,
///   tenthMillisecond: 4,
///   timeZoneName: "US/Eastern",
///   timeZoneOffset: Duration(hours: -5),
/// );
/// print(d.toString()); // "2025-05-20 17:05:15.0374 US/Eastern"
/// print(d.toDartString()); // "2025-05-20 17:05:15.0374 -05:00"
/// ```
class DBDateTimeTZ {
  /// The year part of the date component. For time-only values
  /// the year is set to 2020.
  final int year;

  /// The month part of the date component. For time-only values
  /// the month is set to 1.
  final int month;

  /// The day part of the date component. For time-only values
  /// the day is set to 1.
  final int day;

  /// The hours part of the time component.
  final int hour;

  /// The minutes part of the time component.
  final int minute;

  /// The seconds part of the time component.
  final int second;

  /// The milliseconds part of the time component.
  final int millisecond;

  /// The tenths of the milliseconds part of the time component.
  ///
  /// Firebird can represent time/timestamps with accuracy to the tenth
  /// of a millisecond.
  final int tenthMillisecond;

  /// The name of the time zone (e.g. 'Europe/London').
  final String timeZoneName;

  /// The offset of the time zone, with respect to UTC (GMT).
  final Duration timeZoneOffset;

  /// Initializes a new [DBDateTimeTZ] instance.
  ///
  /// The default values of date components (2020-01-01) correspond
  /// to the values used by Firebird when processing time with time zone
  /// (when no date is present at all). In such cases, Firebird assumes
  /// the time is calculated with respect to Jan 1. 2020.
  /// The [timeZoneName] parameter has to denote a valid time zone,
  /// as listed in RDB$TIME_ZONES Firebird system table.
  /// The name of the time zone is not mandatory. It can be left empty,
  /// the [timeZoneOffset] is enough to construct a valid time/timestamp
  /// with time zone.
  /// If you provide the [timeZoneName], it will have precedence
  /// over the offset when being stored in the database.
  /// If you construct [DBDateTimeTZ] by hand (and not retrieve it
  /// from the database), you need to make sure [timeZoneName]
  /// (if provided) and [timeZoneOffset] match each other, as no such checks
  /// are performed by the constructor.
  DBDateTimeTZ({
    this.year = 2020,
    this.month = 1,
    this.day = 1,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
    this.millisecond = 0,
    this.tenthMillisecond = 0,
    this.timeZoneName = "",
    this.timeZoneOffset = Duration.zero,
  }) {
    if (tenthMillisecond < 0 || tenthMillisecond > 9) {
      throw ArgumentError("Invalid tenths of milliseconds: $tenthMillisecond");
    }
    if (millisecond < 0 || millisecond > 999) {
      throw ArgumentError("Invalid milliseconds: $millisecond");
    }
    if (second < 0 || second > 59) {
      throw ArgumentError("Invalid seconds: $second");
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError("Invalid minutes: $minute");
    }
    if (hour < 0 || hour > 23) {
      throw ArgumentError("Invalid hours: $hour");
    }
    if (month < 1 || month > 12) {
      throw ArgumentError("Invalid month: $month");
    }
    if (day < 1 || day > 31) {
      throw ArgumentError("Invalid day: $day");
    }
    if (timeZoneOffset.inMinutes.abs() > 24 * 60 - 1) {
      throw ArgumentError("Invalid time zone offset: $timeZoneOffset");
    }
  }

  /// Converts the timestamp to its String representation.
  ///
  /// If time zone name was set during instance initialization,
  /// the name will be present in the resulting String.
  /// If not, a numeric time zone offset (+/-HH:MM) will be used
  /// instead.
  @override
  String toString() {
    return _toString(useTZName: true);
  }

  /// Represents this date/time as a string parseable to Dart.
  ///
  /// This version of conversion to String always uses the time zone offset
  /// instead of name (even if the time zone name was provided during
  /// instance initialization).
  /// Returns a String in one of the forms:
  /// - `YYYY-MM-DD hh:mm:ss.mmmt+TH:TM` (timestamp)
  /// - `YYYY-MM-DD hh:mm:ss.mmmt-TH:TM` (timestamp)
  /// - `hh:mm:ss.mmmt+TH:TM` (time only)
  /// - `hh:mm:ss.mmmt-TH:TM` (time only)
  String toDartString() {
    return _toString(useTZName: false);
  }

  /// Returns a string representation of the time zone.
  ///
  /// It is either [timeZoneName], if non-empty,
  /// or [timeZoneOffset] converted to string (+/-HH:MM).
  String get timeZone {
    return timeZoneToString(timeZoneOffset, timeZoneName);
  }

  /// Converts a time zone to its string representation.
  ///
  /// If [tzName] is non-empty, returns the name of the zone.
  /// Otherwise converts [tzOffset] to the form `+/-HH:MM`.
  /// If [tzName] is present, [tzOffset] is irrelevant
  /// (any valid duration, e.g. `Duration.zero`, can be passed).
  static String timeZoneToString(Duration tzOffset, [String tzName = ""]) {
    if (tzName != "") {
      return tzName;
    } else {
      final tzSign = tzOffset.isNegative ? "-" : "+";
      final offsetMins = tzOffset.inMinutes.abs();
      return "$tzSign"
          "${(offsetMins ~/ 60).toString().padLeft(2, '0')}"
          ":"
          "${(offsetMins % 60).toString().padLeft(2, '0')}";
    }
  }

  /// Converts the timestamp to String, either with time zone name
  /// or offset.
  ///
  /// If [useTZName] is `true`, the time zone name will be used
  /// (if present). If no time zone name was set during initialization
  /// or [useTZName] is `false`, the zone offset will be used instead.
  String _toString({bool useTZName = false}) {
    return "${year.toString().padLeft(4, '0')}"
        "-"
        "${month.toString().padLeft(2, '0')}"
        "-"
        "${day.toString().padLeft(2, '0')}"
        " "
        "${hour.toString().padLeft(2, '0')}"
        ":"
        "${minute.toString().padLeft(2, '0')}"
        ":"
        "${second.toString().padLeft(2, '0')}"
        "."
        "${millisecond.toString().padLeft(3, '0')}"
        "${tenthMillisecond.toString().substring(0, 1)}"
        " ${timeZoneToString(timeZoneOffset, useTZName ? timeZoneName : '')}";
  }
}
