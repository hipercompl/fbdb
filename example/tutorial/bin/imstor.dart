import "dart:io";
import "dart:convert";
import "dart:typed_data";
import "package:http/http.dart" as http;
import "package:args/args.dart";
import "package:fbdb/fbdb.dart";

ArgParser buildParser() {
  return ArgParser()
    ..addOption(
      "database",
      abbr: "d",
      mandatory: true,
      help: "The location of the database.",
    )
    ..addOption(
      "user",
      abbr: "u",
      help: "Firebird user name.",
    )
    ..addOption(
      "password",
      abbr: "p",
      help: "Firebird user password.",
    )
    ..addFlag(
      "create",
      abbr: "c",
      negatable: false,
      help: "Create a new database.",
    )
    ..addFlag(
      "store",
      abbr: "s",
      negatable: false,
      help: "Download and store images.",
    )
    ..addFlag(
      "list",
      abbr: "l",
      negatable: false,
      help: "List stored images.",
    )
    ..addOption(
      "retrieve",
      abbr: "r",
      help: "Retrieve an image with the given ID from the database.",
    )
    ..addOption(
      "output",
      abbr: "o",
      help: "The file to save the retrieved image to.",
    );
}

void printUsage(ArgParser argParser) {
  print("Usage: dart imstor.dart <flags> [arguments]");
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  FbDb? db;
  try {
    final ArgResults results = argParser.parse(arguments);
    if (!results.wasParsed("database")) {
      throw FormatException("Not enough arguments.");
    }
    if (results.wasParsed("create")) {
      db = await createDatabase(results);
    } else {
      db = await attach(results);
    }
    if (results.wasParsed("store")) {
      final imgs = await downloadImages();
      await storeImages(db, imgs);
    }
    if (results.wasParsed("list")) {
      await listImages(db);
    }
    if (results.wasParsed("retrieve")) {
      await getImage(db, results);
    }
  } on FormatException catch (e) {
    print(e.message);
    print("");
    printUsage(argParser);
  } on Exception catch (e) {
    print("Error occured: $e");
  } finally {
    await db?.detach();
  }
}

Future<Uint8List> downloadImageData(String url) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode >= 200 && resp.statusCode <= 299) {
    return resp.bodyBytes;
  } else {
    throw Exception("Fetching data from $url failed");
  }
}

Future<List<Image>> downloadImages(
    {String url = "https://jsonplaceholder.typicode.com/photos",
    int count = 50}) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode < 200 || resp.statusCode > 299) {
    throw Exception("Fetching data from $url failed: ${resp.statusCode}");
  }
  final allImages = json.decode(resp.body);
  final toDownload = (allImages as List<dynamic>).sublist(0, 50);
  // download all images in parallel
  final images =
      await Future.wait(toDownload.map((e) => downloadImageData(e["url"])));
  return [
    for (var i = 0; i < toDownload.length; i++)
      Image(toDownload[i]["id"], toDownload[i]["title"], images[i])
  ];
}

Future<FbDb> createDatabase(ArgResults results) async {
  final db = await FbDb.createDatabase(
    database: results.option("database") ?? "images.fdb",
    user: results.option("user"),
    password: results.option("password"),
  );
  await createTable(db);
  return db;
}

Future<void> createTable(FbDb db) async {
  final q = db.query();
  try {
    await q.execute(
      sql: "create table IMAGES ( "
          "ID integer not null primary key, "
          "TITLE varchar(200) not null, "
          "SIZE integer not null, "
          "PNG_DATA blob sub_type binary "
          ") ",
    );
  } finally {
    q.close();
  }
}

Future<FbDb> attach(ArgResults results) async {
  return FbDb.attach(
    database: results.option("database") ?? "images.fdb",
    user: results.option("user"),
    password: results.option("password"),
  );
}

Future<void> storeImages(FbDb db, List<Image> images) async {
  final q = db.query();
  try {
    await db.startTransaction();
    await q.execute(sql: "delete from IMAGES");
    for (var img in images) {
      await q.execute(
        sql: "insert into IMAGES(ID, TITLE, SIZE, PNG_DATA) "
            "values (?, ?, ?, ?)",
        parameters: [
          img.id,
          img.title,
          img.pngBytes.length,
          img.pngBytes,
        ],
      );
    }
    await db.commit();
  } catch (_) {
    await db.rollback();
    rethrow;
  } finally {
    await q.close();
  }
}

Future<void> listImages(FbDb db) async {
  final q = db.query();
  try {
    await q.openCursor(
      sql: "select ID, TITLE, SIZE from IMAGES order by ID",
    );
    await for (var row in q.rows()) {
      print("id: ${row['ID']}, title: ${row['TITLE']}, size: ${row['SIZE']}");
    }
  } finally {
    await q.close();
  }
}

Future<void> getImage(FbDb db, ArgResults results) async {
  int id = int.parse(results.option("retrieve") ?? "0");
  String outFile = results.option("output") ?? "";
  if (id == 0 || outFile == "") {
    throw Exception("Image ID and output file required to retrieve an image");
  }
  final q = db.query();
  try {
    await db.startTransaction();
    await q.openCursor(
      sql: "select PNG_DATA from IMAGES where ID=?",
      parameters: [id],
      inlineBlobs: false,
    );
    final row = await q.fetchOneAsMap();
    if (row == null) {
      throw Exception("Image with ID $id not found in the database");
    }
    final blobId = row["PNG_DATA"];
    await db.blobToFile(id: blobId, file: File(outFile));
  } finally {
    await q.close();
    await db.commit();
  }
}

class Image {
  final int id;
  final String title;
  final Uint8List pngBytes;

  Image(this.id, this.title, this.pngBytes);
}
