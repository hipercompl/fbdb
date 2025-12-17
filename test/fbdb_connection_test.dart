@TestOn("vm")
library;

import 'package:test/test.dart';
import 'package:fbdb/fbdb.dart';
import "test_config.dart";
import 'test_utils.dart';

/// Tests connecting and disconnecting to/from databases
/// and creating / dropping databases.
void main() async {
  test("Attaching to employee and detaching", () async {
    FbDb? db;

    final dbFut = FbDb.attach(
      database: TestConfig.employeeDB,
      user: TestConfig.dbUser,
      password: TestConfig.dbPassword,
    );
    await expectLater(dbFut, completes);
    db = await dbFut;

    final detFut = db.detach();
    await expectLater(detFut, completes);

    await expectLater(
      (() async {
        await db?.ping();
      })(),
      throwsException,
    );
  });

  test("Attaching with an error", () {
    expect(() async {
      await FbDb.attach(
        database: TestConfig.employeeDB,
        user: "bad_user",
        password: "!!!bad_password",
      );
    }, throwsException);
  });

  test("Creating and dropping database", () async {
    FbDb? db;
    final dbFut = FbDb.createDatabase(
      database: getTmpDbLoc(),
      user: TestConfig.dbUser,
      password: TestConfig.dbPassword,
    );
    await expectLater(dbFut, completes);
    db = await dbFut;

    final dropFut = db.dropDatabase();
    await expectLater(dropFut, completes);

    await expectLater(
      (() async {
        return db?.ping();
      })(),
      throwsException,
    );
  });

  test("Creating database with an error", () {
    expect(() async {
      await FbDb.createDatabase(database: "");
    }, throwsException);
  });

  test("Creating database with collation", () async {
    FbDb? db;
    final dbFut = FbDb.createDatabase(
      database: getTmpDbLoc(),
      user: TestConfig.dbUser,
      password: TestConfig.dbPassword,
      options: FbOptions(dbCharset: "UTF8", dbCollation: "UNICODE_CI_AI"),
    );
    await expectLater(dbFut, completes);
    db = await dbFut;

    final qFut = db.selectOne(
      sql:
          "select RDB\$DEFAULT_COLLATE_NAME "
          "from RDB\$CHARACTER_SETS "
          "where RDB\$CHARACTER_SET_NAME=? ",
      parameters: ["UTF8"],
    );
    await expectLater(dbFut, completes);

    final rec = await qFut;
    expect(rec, isNotNull);

    if (rec != null) {
      expect(
        rec["RDB\$DEFAULT_COLLATE_NAME"].toString().trim(),
        equals("UNICODE_CI_AI"),
      );
    }

    final dropFut = db.dropDatabase();
    await expectLater(dropFut, completes);
  });

  test("Creating database without collation", () async {
    FbDb? db;
    final dbFut = FbDb.createDatabase(
      database: getTmpDbLoc(),
      user: TestConfig.dbUser,
      password: TestConfig.dbPassword,
      options: FbOptions(dbCharset: "UTF8"),
    );
    await expectLater(dbFut, completes);
    db = await dbFut;

    final qFut = db.selectOne(
      sql:
          "select RDB\$DEFAULT_COLLATE_NAME "
          "from RDB\$CHARACTER_SETS "
          "where RDB\$CHARACTER_SET_NAME=? ",
      parameters: ["UTF8"],
    );
    await expectLater(dbFut, completes);

    final rec = await qFut;
    expect(rec, isNotNull);

    if (rec != null) {
      expect(
        rec["RDB\$DEFAULT_COLLATE_NAME"].toString().trim(),
        equals("UTF8"),
      );
    }

    final dropFut = db.dropDatabase();
    await expectLater(dropFut, completes);
  });
}
