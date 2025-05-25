@TestOn("vm")
library;

import 'package:test/test.dart';
import 'package:fbdb/fbdb.dart';

import 'test_utils.dart';

void main() {
  group("DBDateTimeTZ tests", () {
    test("DBDateTimeTZ construction and .toString", () {
      expect(() {
        DBDateTimeTZ();
      }, returnsNormally);
      expect(() {
        DBDateTimeTZ(
          year: 2025,
          month: 5,
          day: 19,
          hour: 23,
          minute: 59,
          second: 59,
          millisecond: 999,
          tenthMillisecond: 9,
        );
      }, returnsNormally);
      final d1 = DBDateTimeTZ(
        hour: 12,
        minute: 5,
        second: 10,
        millisecond: 20,
        tenthMillisecond: 3,
      );
      expect(d1.toString(), equals("2020-01-01 12:05:10.0203 +00:00"));
      expect(d1.timeZone, equals("+00:00"));
      final d2 = DBDateTimeTZ(
        hour: 12,
        minute: 5,
        second: 10,
        millisecond: 20,
        tenthMillisecond: 3,
        timeZoneOffset: Duration(hours: -2, minutes: -20),
      );
      expect(d2.toString(), equals("2020-01-01 12:05:10.0203 -02:20"));
      expect(d2.timeZone, equals("-02:20"));
      final d3 = DBDateTimeTZ(
        year: 2025,
        month: 5,
        day: 18,
        hour: 23,
        minute: 59,
        second: 59,
        millisecond: 999,
        tenthMillisecond: 9,
        timeZoneOffset: Duration(hours: 2, minutes: 0),
      );
      expect(d3.toString(), equals("2025-05-18 23:59:59.9999 +02:00"));
      expect(d3.timeZone, equals("+02:00"));
      final d4 = DBDateTimeTZ(
        hour: 12,
        timeZoneName: "Europe/Warsaw",
        timeZoneOffset: Duration(hours: 1),
      );
      expect(d4.toString(), equals("2020-01-01 12:00:00.0000 Europe/Warsaw"));
      expect(d4.toDartString(), equals("2020-01-01 12:00:00.0000 +01:00"));
      expect(d4.timeZoneOffset.inMinutes, equals(60));
      expect(d4.timeZone, equals("Europe/Warsaw"));
    }); // test "DBDateTime.toString"
    test("Invalid DBDateTimeTZ construction", () {
      expect(() {
        DBDateTimeTZ(minute: -1);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(minute: 60);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(month: 0);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(month: 13);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(tenthMillisecond: 10);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(millisecond: -1);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(millisecond: 1000);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(day: 0);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(day: 32);
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(timeZoneOffset: Duration(hours: 24));
      }, throwsArgumentError);
      expect(() {
        DBDateTimeTZ(timeZoneOffset: Duration(hours: -24));
      }, throwsArgumentError);
    }); // test "Invalid DBDateTimeTZ construction"

    test("DBDateTimeTZ with mismatched zones", () {
      final d = DBDateTimeTZ(
        year: 2025,
        month: 5,
        day: 21,
        hour: 12,
        minute: 0,
        second: 0,
        timeZoneName: "Europe/London",
        timeZoneOffset: Duration(hours: -5, minutes: -15),
      );
      expect(d.toString(), equals("2025-05-21 12:00:00.0000 Europe/London"));
      expect(d.toDartString(), equals("2025-05-21 12:00:00.0000 -05:15"));
    }); // test DBDateTimeTZ with mismatched zones
  }); // group "DBDateTime tests"

  group("FBDateTimeTZ tests", () {
    test("FBDateTimeTZ construction", () {
      final dbd1 = DBDateTimeTZ(
        year: 2025,
        month: 5,
        day: 21,
        hour: 12,
        millisecond: 222,
        tenthMillisecond: 3,
        timeZoneName: "Europe/Warsaw",
        timeZoneOffset: Duration.zero,
      );
      final fbd1 = FbDateTimeTZ.withDB(dbd1);
      expect(fbd1.toUtc().toString(), equals("2025-05-21 12:00:00.222300Z"));
      expect(
        fbd1.db.toString(),
        equals("2025-05-21 12:00:00.2223 Europe/Warsaw"),
      );
      expect(fbd1.db.toDartString(), equals("2025-05-21 12:00:00.2223 +00:00"));

      final fbd2 = FbDateTimeTZ(
        year: 2025,
        month: 5,
        day: 21,
        hour: 12,
        millisecond: 222,
        tenthMillisecond: 3,
        timeZoneName: "Europe/Warsaw",
        timeZoneOffset: Duration.zero,
      );
      expect(fbd2.toUtc().toString(), equals("2025-05-21 12:00:00.222300Z"));
      expect(
        fbd2.db.toString(),
        equals("2025-05-21 12:00:00.2223 Europe/Warsaw"),
      );
      expect(fbd2.db.toDartString(), equals("2025-05-21 12:00:00.2223 +00:00"));
    }); // test "FBDateTimeTZ construction"
  }); // group "FBDateTimeTZ tests"

  group("Database tests", () {
    test("Named time zones", () async {
      await withNewDb3((db) async {
        final rec = await db.selectOne(sql: "select * from T where PK_INT=1");
        expect(rec, isNotNull);
        if (rec != null) {
          expect(rec["T"] is FbDateTimeTZ, isTrue);
          final ttz = rec["T"] as FbDateTimeTZ;
          expect(
            ttz.db.toString(),
            equals("2020-01-01 12:01:02.0304 Europe/London"),
          );
          expect(
            ttz.db.toDartString(),
            equals("2020-01-01 12:01:02.0304 +00:00"),
          );
          expect(ttz.toUtc().toString(), equals("2020-01-01 12:01:02.030400Z"));

          expect(rec["TS"] is FbDateTimeTZ, isTrue);
          final tstz = rec["TS"] as FbDateTimeTZ;
          expect(
            tstz.db.toString(),
            equals("2025-05-22 12:01:02.0304 Europe/Warsaw"),
          );
          expect(
            tstz.db.toDartString(),
            equals("2025-05-22 12:01:02.0304 +02:00"),
          );
          expect(
            tstz.toUtc().toString(),
            equals("2025-05-22 10:01:02.030400Z"),
          );
        }
      });
    }); // test "Named time zones"
    test("Offset time zones", () async {
      await withNewDb3((db) async {
        final rec = await db.selectOne(sql: "select * from T where PK_INT=2");
        expect(rec, isNotNull);
        if (rec != null) {
          expect(rec["T"] is FbDateTimeTZ, isTrue);
          final ttz = rec["T"] as FbDateTimeTZ;
          expect(ttz.db.toString(), equals("2020-01-01 12:01:02.0304 +00:00"));
          expect(
            ttz.db.toDartString(),
            equals("2020-01-01 12:01:02.0304 +00:00"),
          );
          expect(ttz.toUtc().toString(), equals("2020-01-01 12:01:02.030400Z"));

          expect(rec["TS"] is FbDateTimeTZ, isTrue);
          final tstz = rec["TS"] as FbDateTimeTZ;
          expect(tstz.db.toString(), equals("2025-05-22 12:01:02.0304 +02:00"));
          expect(
            tstz.db.toDartString(),
            equals("2025-05-22 12:01:02.0304 +02:00"),
          );
          expect(
            tstz.toUtc().toString(),
            equals("2025-05-22 10:01:02.030400Z"),
          );
        }
      });
    }); // test "Offset time zones"
    test("Inserting with named time zones", () async {
      await withNewDb3((db) async {
        await db.execute(sql: "delete from T");
        final t = FbDateTimeTZ(
          hour: 12,
          minute: 1,
          second: 2,
          millisecond: 3,
          tenthMillisecond: 4,
          timeZoneName: "Europe/Warsaw",
          timeZoneOffset: Duration(hours: 1),
        );
        final ts = FbDateTimeTZ(
          year: 2025,
          month: 5,
          day: 22,
          hour: 12,
          minute: 1,
          second: 2,
          millisecond: 3,
          tenthMillisecond: 4,
          timeZoneName: "Europe/Warsaw",
          timeZoneOffset: Duration(hours: 2),
        );
        await db.execute(
          sql:
              "insert into T(PK_INT, T, TS) "
              "values (?, ?, ?)",
          parameters: [1, t, ts],
        );
        final r = await db.selectOne(sql: "select * from T where PK_INT=1");
        expect(r, isNotNull);
        if (r != null) {
          expect(r['T'] is FbDateTimeTZ, isTrue);
          expect(r['TS'] is FbDateTimeTZ, isTrue);
          final tr = r['T'] as FbDateTimeTZ;
          final tsr = r['TS'] as FbDateTimeTZ;
          expect(
            tr.db.toString(),
            equals("2020-01-01 12:01:02.0034 Europe/Warsaw"),
          );
          expect(
            tr.db.toDartString(),
            equals("2020-01-01 12:01:02.0034 +01:00"),
          );
          expect(tr.toUtc().toString(), equals("2020-01-01 11:01:02.003400Z"));
          expect(
            tsr.db.toString(),
            equals("2025-05-22 12:01:02.0034 Europe/Warsaw"),
          );
          expect(
            tsr.db.toDartString(),
            equals("2025-05-22 12:01:02.0034 +02:00"),
          );
          expect(tsr.toUtc().toString(), equals("2025-05-22 10:01:02.003400Z"));
        }
      }); // withNewDb3
    }); // test "Inserting with named time zones"
    test("Inserting with offset time zones", () async {
      await withNewDb3((db) async {
        await db.execute(sql: "delete from T");
        final t = FbDateTimeTZ(
          hour: 12,
          minute: 1,
          second: 2,
          millisecond: 3,
          tenthMillisecond: 4,
          timeZoneName: "",
          timeZoneOffset: Duration(hours: 1),
        );
        final ts = FbDateTimeTZ(
          year: 2025,
          month: 5,
          day: 22,
          hour: 12,
          minute: 1,
          second: 2,
          millisecond: 3,
          tenthMillisecond: 4,
          timeZoneName: "",
          timeZoneOffset: Duration(hours: 2),
        );
        await db.execute(
          sql:
              "insert into T(PK_INT, T, TS) "
              "values (?, ?, ?)",
          parameters: [1, t, ts],
        );
        final r = await db.selectOne(sql: "select * from T where PK_INT=1");
        expect(r, isNotNull);
        if (r != null) {
          expect(r['T'] is FbDateTimeTZ, isTrue);
          expect(r['TS'] is FbDateTimeTZ, isTrue);
          final tr = r['T'] as FbDateTimeTZ;
          final tsr = r['TS'] as FbDateTimeTZ;
          expect(tr.db.toString(), equals("2020-01-01 12:01:02.0034 +01:00"));
          expect(
            tr.db.toDartString(),
            equals("2020-01-01 12:01:02.0034 +01:00"),
          );
          expect(tr.toUtc().toString(), equals("2020-01-01 11:01:02.003400Z"));
          expect(tsr.db.toString(), equals("2025-05-22 12:01:02.0034 +02:00"));
          expect(
            tsr.db.toDartString(),
            equals("2025-05-22 12:01:02.0034 +02:00"),
          );
          expect(tsr.toUtc().toString(), equals("2025-05-22 10:01:02.003400Z"));
        }
      }); // withNewDb3
    }); // test "Inserting with offset time zones"
  });
}
