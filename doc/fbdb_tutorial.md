# FbDb Tutorial
Welcome to the FbDb tutorial!

Throughout this exercise, you are going to learn how to use FbDb in your Dart / Flutter applications by implementing a CLI tool to download and store images in a Firebird database.

It is best to complete the tasks in order, in which they are described in the tutorial. The complete source code of the final application is available in the source tree of the *fbdb* library, in the directory [`example/tutorial`](https://github.com/hipercompl/fbdb/tree/main/example/tutorial). However, the source alone is not enough to build the fully functional application, please refer to the [Starting the project](#Startingtheproject) section for detailed information on how to prepare your Dart project.

---
This tutorial is copyritht © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is copyright © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is licensed under open source BSD license (see the [LICENSE](https://github.com/hipercompl/fbdb/blob/main/LICENSE) file).

---

**TABLE OF CONTENTS**

<!-- vscode-markdown-toc -->
* 1. [The problem](#Theproblem)
	* 1.1. [Use cases](#Usecases)
	* 1.2. [Dependencies](#Dependencies)
* 2. [Prerequisites](#Prerequisites)
* 3. [Starting the project](#Startingtheproject)
	* 3.1. [Adding the dependencies](#Addingthedependencies)
	* 3.2. [Installing the Firebird client libraries](#InstallingtheFirebirdclientlibraries)
* 4. [Command line parsing](#Commandlineparsing)
* 5. [Downloading images](#Downloadingimages)
* 6. [Creating the database and the IMAGES table](#CreatingthedatabaseandtheIMAGEStable)
* 7. [Storing images in the database](#Storingimagesinthedatabase)
* 8. [Listing images](#Listingimages)
* 9. [Retrieving an image](#Retrievinganimage)
* 10. [Putting it all together](#Puttingitalltogether)
* 11. [Running the application](#Runningtheapplication)
* 12. [The complete source](#Thecompletesource)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='Theproblem'></a>The problem
In this tutorial we are going to implement a **CLI** (command line / terminal) application, which will store PNG images in a Firebird database. More experienced Dart / Flutter developers can of course implement the equivalent functionality as a Flutter GUI application. However, GUI related code tends to grow in volume very quickly, so in this tutorial we will stick to the CLI, to focus on the use of FbDb and on communication with the Firebird database, rather than on nuances of GUI programming. All principles and techniques presented in this tutorial also apply to a GUI application (FbDb is fully asynchronous, database requests don't block the main event loop, therefore it is very well suited to be used in a Flutter application).

The images will be downloaded from the site *jsonplaceholder.typicode.com*, which hosts thousands of placeholder images (for testing and educational purposes), available via a convenient REST API (i.e. a web service that can be accessed by sending standard HTTP requests).

If you open the following URL in your browser:
```
https://jsonplaceholder.typicode.com/photos
```
you will be presented with a list of 5 thousand JSON objects, each of which contains (among others) an ID of a PNG image and an individual URL (link), which allows to download the actual image binary data:
```json
[
  {
    "albumId": 1,
    "id": 1,
    "title": "accusamus beatae ad facilis cum similique qui sunt",
    "url": "https://via.placeholder.com/600/92c952",
    "thumbnailUrl": "https://via.placeholder.com/150/92c952"
  },
  {
    "albumId": 1,
    "id": 2,
    "title": "reprehenderit est deserunt velit ipsam",
    "url": "https://via.placeholder.com/600/771796",
    "thumbnailUrl": "https://via.placeholder.com/150/771796"
  },
  /* ... 4998 more similar JSON entries ... */
]
```

We'd like our application to download the first 50 of those images and store them (together with their IDs and sizes) in a table in a Firebird database.

Later on, the database can be queried to get a list of stored images. Each image can be retrieved from the database and saved as a local PNG file. 

###  1.1. <a name='Usecases'></a>Use cases
The application should support the following use cases:
- specify the user name, password and location of the database for all available functions:
    ```
    imstor -u user -p pass -d database
    ```
- create a new, empty database:
    ```
    imstor -u user -p pass -d database -c
    ```
- download and store 50 images:
    ```
    imstor -u user -p pass -d database -s
    ```
- list images from the database (their IDs and image sizes):
    ```
    imstor -u user -p pass -d database -l
    ```
- retrieve an image from the database and save it in a local file:
    ```
    imstor -u user -p pass -d database -r image_id -o file_name
    ```
- the flags can be combined, for example to create a new database, download and store the images and immediately list them, the user can execute:
    ```
    imstor -u user -p pass -d database -c -s -l
    ```
- the `database` parameter value should be a valid Firebird database location; it can either be a local file path (in which case the embedded mode will be used) or a network location (for example `host:/path`).

###  1.2. <a name='Dependencies'></a>Dependencies
The project will have just three external dependencies:
- [args](https://pub.dev/packages/args) package to parse command line arguments,
- [http](https://pub.dev/packages/http) package to send HTTP requests,
- FbDb to access the database.

In addition to the above, our project will depend on the native Firebird client libraries (more on this subject in the [Installing the Firebird client libraries](#InstallingtheFirebirdclientlibraries) section).

##  2. <a name='Prerequisites'></a>Prerequisites
This is not a general Dart tutorial, therefore it is assumed you know how to program in Dart and you've got the current version of Dart installed. It is also assumed you know how to compile and run Dart programs, and have a code editor installed.

Moreover, the knowledge about Dart isolates, futures, asynchronous programming with `async` / `await` and streams will be helpful. The [Dart documentation](https://dart.dev/guides) has all these topics covered.

Internet connection is also required in order to install additional packages / dependencies and to acutally run the complete project (the final application downloads data via Internet as part of its normal operation).

##  3. <a name='Startingtheproject'></a>Starting the project
In the console, `cd` to a directory of your choice and create a new Dart CLI application named `imstor`:
```bash
dart create -t cli imstor
```
This command will create a new directory `imstor` in your current directory. Get into the new directory:
```bash
cd imstor
```
From now on we assume `imstor` is the current working directory.

Now is probably a good moment to launch your editor / IDE of choice and start looking at the project files. The console will still be of use, so it's best to keep it open.

There are just two files we will change in the course of this tutorial:
- `pubspec.yaml` - that's where our project dependencies are specified,
- `bin/imstor.dart` - that's the main source code module of our project.

Please proceed to the next section to add the dependencies to our project.

###  3.1. <a name='Addingthedependencies'></a>Adding the dependencies
Right now our `pubspec.yaml` file has a single entry in its `dependencies` section:
```yaml
dependencies:
  args: ^2.4.2
```
(of course the actual version number in your case can be different).
We need two additional dependencies, which we are going to add using the `dart pub` command:
```bash
dart pub add http
dart pub add fbdb
```
Now our dependencies in `pubspec.yaml` should look similar to these:
```yaml
dependencies:
  args: ^2.4.2
  http: ^1.2.1
  fbdb: ^1.0.0
```
(again: the actual version numbers may be different in your case, which is perfectly normal - all packages we're using are being actively developed and their version numbers increase with time).

###  3.2. <a name='InstallingtheFirebirdclientlibraries'></a>Installing the Firebird client libraries
The detailed Firebird installation instruction is out of scope of this tutorial. It is assumed you do know how to install Firebird server and client libraries. If not, please refer to the [Firebird 5 Quick Start Guide](https://firebirdsql.org/file/documentation/html/en/firebirddocs/qsg5/firebird-5-quickstartguide.html) (or the equivalent documentation for your Firebird version) and follow the installation instructions for your operating system.

In short: 
- On Windows, put `fbclient.dll` and its dependencies (e.g. `vcruntime140.dll` and `msvcp140.dll`) either in the same directory as your final application executable file, or in a subdirectory named `fb`, or in any directory listed in your `PATH` environment variable.
- On Linux, you can either put `libfbclient.so` in the same directory as your final application executable file, or in a subdirectory named `fb`, or in one of the locations known to the `ld` dynamic loader.
- On Mac, generally follow the Linux instructions.
- On Android with Flutter, follow these steps:
    - download the official Android build of the Firebird server **for all supported architectures**, that is for ARM32, ARM64, x86 and x86_64 (you need to download 4 distribution archives),
    - start your flutter project normally, e.g. with
        ```bash
        flutter create --platforms=android myproject
        ```
    - look inside your project directory, and locate the subdirectory `android/app/src/main`,
    - create a subdirectory named `jniLibs` inside `android/app/src/main`,
    - create 4 subdirectories inside this directory:
        - `arm64-v8a`
        - `armeabi-v7a`
        - `x86`
        - `x86_64`
    - in each of these subdirectories, place the libraries `libfbclient.so` and `libChaCha.so` (the latter probably only if you intend to enable wire encryption), extracted **from the matching Firebird archive**, that is, the libraries from the ARM64 Firebird archive go into `arm64-v8a`, the libraries from the ARM32 archive go into `armeabi-v7a`, and so on,
    - when you build (with `flutter build appbundle` / `flutter build apk`) or run in debug mode (with `flutter run -d <device_id>`) your application, the Firebird shared libraries will be automatically included in the application bundle. Moreover, on a real device, the library matching the actual architecture of the device will be used.
    - Don't specify Firebird client library location while initializing the database connection (let the standard OS resolving mechanism do its job).
- For iOS Flutter apps, the procedure is yet to be determined (not tested yet).

The current directory is scanned first in search of the client library, then the `fb` subdirectory (if present), and eventually the OS-specific library resolution mechanism is used.

>Please make sure you use the 64-bit Firebird client libraries on Windows and Linux. Dart compiler on those platfors produces 64-bit binaries, and 64-bit applications cannot load and use 32-bit dynamic libraries.

To be able to run the project with the command
```bash
dart run bin/imstor.dart
```
the Firebird client libraries need to be placed relatively to the project root directory (not the `bin` subdirectory).

On the other hand, if you plan to deploy the actual binary file (i.e. the compiled executable), the Firebird client libraries should be placed in the same directory as the final executable (or it's `fb` subdirectory).

##  4. <a name='Commandlineparsing'></a>Command line parsing
Let's configure the `ArgParser` to have it recognize various options and flags our application supports.

Open the `bin/imstor.dart` source file and edit the `buildParser` function so that it reads:
```dart
ArgParser buildParser() {
  return ArgParser()
    ..addOption(
      "database",
      abbr: "d",
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
      'store',
      abbr: 's',
      negatable: false,
      help: 'Download and store images.',
    )
    ..addFlag(
      'list',
      abbr: 'l',
      negatable: false,
      help: 'List stored images.',
    )
    ..addOption(
      'retrieve',
      abbr: "r",
      help: "Retrieve an image with the given ID from the database.",
    )
    ..addOption(
      "output",
      abbr: "o",
      help: "The file to save the retrieved image to.",
    );
}
```
We specify all flags and options that can be passed to our application to an `ArgParser` instance and return the configured parser to the calling function. Please refer to the manual of the [args](https://pub.dev/packages/args) package for more information (we won't focus on argument parsing, since that's not what this tutorial is about).

Next, edit the `main` function to look like this:
```dart
Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    if (!results.wasParsed("database")) {
      throw FormatException("Not enough arguments.");
    }
  } on FormatException catch (e) {
    print(e.message);
    print("");
    printUsage(argParser);
  } on Exception catch (e) {
    print("Error occured: $e");
  }
}
```

For now, all our `main` function does is parse the command line arguments and display an error message / app usage information if something goes wrong.

Also, we assume that the `--database` (or `-d`) argument has to be provided in all scenarios, so we check if it is present (by calling `results.wasParsed("database")`), and if not, we simply end the application by throwing an exception (the exception gets caught and the usage information is displayed before the program terminates).

The last thing worth noting is that our `main` function is `async`. That's on purpose - most of our database-related code, as well as code dealing with network requests, will be *asynchronous*, so declaring `main` as `async` is a necessity.

##  5. <a name='Downloadingimages'></a>Downloading images
We will use the `http` package to contact the REST API and the `json` object (from `dart:convert`) to parse the response, so first of all let's add appropriate imports at the top of `bin/imstor.dart`:
```dart
import "dart:convert";
import "package:http/http.dart" as http;
```

Next, let's define an `Image` class, which will store the information about a single image (together with the actual bytes of the image PNG representation). To do so, add the following code **at the end** of `bin/imstor.dart`:
```dart
class Image {
  final int id;
  final String title;
  final Uint8List pngBytes;

  Image(this.id, this.title, this.pngBytes);
}
```

>If a Dart module contains both class definitions and top level code (functions or variables outside classes), the classes have to be defined **below** the functions. Therefore, all functions implemented in the next sections have to be added **above** the `Image` class in the source file.

Let's add two new functions (**above** the new `Image` class). The first one will be reponsible for downloading binary image data from a given URL:
```dart
Future<List<int>> downloadImageData(String url) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode >= 200 && resp.statusCode <= 299) {
    return resp.bodyBytes;
  } else {
    throw Exception("Fetching data from $url failed");
  }
}
```

The second function downloads the image list, parses the JSON array, takes the metadata of the first 50 images, downloads contents (PNG data) of each image and returns a list of ready to use `Image` objects. The contents of all images are downloaded simultaneously:
```dart
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
```

We won't dig into the image downloading code - this tutorial is about talking to a database, not about downloading data via HTTP. Let us just mention, that the interesting part of the function above is the use of `Future.wait`, which awaits for all futures to resolve (the futures being awaited are those returned by multiple calls to `downloadImageData` performed iside the `map` method). `Future.wait` then gathers the actual results of each future and returns them all in a list. Therefore, `images` has type `List<Uint8List>` (the data from already resolved futures), and not `List<Future<Uint8List>>`.

At the end of this step, the source file `bin/imstor.dart` should read:
```dart
import "dart:convert";
import "dart:typed_data";
import "package:http/http.dart" as http;
import "package:args/args.dart";

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
  try {
    final ArgResults results = argParser.parse(arguments);
    if (!results.wasParsed("database")) {
      throw FormatException("Not enough arguments.");
    }
    print((await downloadImages())
        .map((e) => {"id": e.id, "title": e.title, "size": e.pngBytes.length}));
  } on FormatException catch (e) {
    print(e.message);
    print("");
    printUsage(argParser);
  } on Exception catch (e) {
    print("Error occured: $e");
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

class Image {
  final int id;
  final String title;
  final Uint8List pngBytes;

  Image(this.id, this.title, this.pngBytes);
}
```

##  6. <a name='CreatingthedatabaseandtheIMAGEStable'></a>Creating the database and the IMAGES table
Let's implement a function, which will create a new Firebird database and an empty `IMAGES` table.

First, let's import the FbDb package. Add the `import` statement next to the other imports, at the top of the `bin/imstor.dart` file:
```dart
import "package:fbdb/fbdb.dart";
```

Our function will accept the parsed command line arguments as its input. Let's write the function somewhere **above** the definition of the `Image` class.

```dart
Future<FbDb> createDatabase(ArgResults results) async {
  return FbDb.createDatabase(
    database: results.option("database") ?? "images.fdb",
    user: results.option("user"),
    password: results.option("password"),
  );
}
```

While at it, let's also create a function, which will connect to an existing database (place the function next to `createDatabase`):
```dart
Future<FbDb> attach(ArgResults results) async {
  return FbDb.attach(
    database: results.option("database") ?? "images.fdb",
    user: results.option("user"),
    password: results.option("password"),
  );
}
```

Both functions return an instance of the `FbDb` class (well, to be precise, they return a `Future` of such instance, but since we'll `await` them at the call site, the actual obtained value will be an `FbDb` object). An `FbDb` object represents an active connection.

When you call `FbDb.attach` or `FbDb.createDatabase`, the FbDb library spawns a second *isolate* (a kind of a thread or a background process), which will wait in the background for messages from the main isolate. The second worker isolate is the secret sauce of FbDb, one that makes database communication *asynchronous*, that is: *non blocking*.

However, this double-isolate setup also has a downside. You have to remember to **close** the connection (call and await the `FbDb.detach` method), otherwise your application will not end properly (the background worker will keep waiting for commands from the main isolate).

We'll take care of closing the connection in our `main` function. Modify `main` in the following way:
```dart
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
```

If the user passed the `--create` (or `-c`) argument while executing `imstor`, our connection (`FbDb` object) is created by calling `createDatabase` function. Otherwise, the user wishes to connect to an existing database, and our `db` object is created by a call to `attach`.

In both cases we need to **detach** from the database after we're done processing images. To make sure `detach` will be called regardless of the way the connection was initiated, we add a `finally` clause at the end of the `main` function, which will ensure `detach` will be called no matter the circumstances.

>We call `await db?.detach()` to account for the possibility that `db` was not in fact assigned (e.g. due to invalid command line parameters passed by the user). In that case, `db` will be `null` and the `?.` operator ensures that the call has no effect, but doesn't result in an exception.

An empty database won't be of much use to us. Let's implement a function (place it next to `createDatabase`), which will create a *table* in the database, capable of storing image information and actual PNG bytes.
```dart
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
```

There are two interesting things going on in the above function. First, we obtain a **query** object (an object of class `FbQuery`) from an attached database. The `FbQuery` object is a workhorse of `FbDb` and is used both to issue SQL statements to the database and to access the results of the statements.

In case of `createTable`, we call the `FbQuery.execute` method, providing the SQL statement in the `sql` parameter. Another option (which we'll use when we'll be implementing image listing and retrieval) would be to call `FbQuery.openCursor`, but in case of `create table` statement there is no data to be fetched as the query result. Therefore we call the `execute` method, which does not allocate a database cursor (to iterate over returned set of rows).

Let's now call our new `createTable` function inside `createDatabase`, to add the `IMAGES` table to every newly created database:
```dart
Future<FbDb> createDatabase(ArgResults results) async {
  final db = await FbDb.createDatabase(
    database: results.option("database") ?? "images.fdb",
    user: results.option("user"),
    password: results.option("password"),
  );
  await createTable(db);
  return db;
}
```

Please note, that now we `await` the call to `FbDb.createDatabase`, because we need the actual attachment to pass it to `createTable`. A `Future<FbDb>` object is not sufficient in this case: it has to be awaited to obtain the actual `FbDb` reference.

##  7. <a name='Storingimagesinthedatabase'></a>Storing images in the database
The next step of the tutorial covers storing the images in the database.

To do so, let's implement a function, which will take a database connection and a list of images as parameters, and store the images in the `IMAGES` table. It will also remove the existing images (if any) from the `IMAGES` table.

Place the function anywhere in your source code, as long as it's **above** the definition of the `Image` class.
```dart
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
```

Let's analyze the code, because it contains two new concepts that have not surfaced before: explicit transactions and parametrized queries.

The main idea of `storeImages` is to execute a `DELETE` query, removing all images from the `IMAGES` table, and then execute an `INSERT` statement for every image (from the `images` list passed to the function) one by one. All that is done using the provided `FbDb` object (an active database connection).

The first snippet of code worth noting is
```dart
await db.startTransaction();
```
This call starts a new database transaction. Every SQL statement executed via the attachment that the transaction was started within, will be executed in the context (scope) of this transaction. To end a transaction, you either **commit** it (approve) or **roll** it **back** (cancel). What's important about transactions is that **all** the statements (and their effects in the database) executed within a transaction are committed or rolled back, so it is an *all or nothing* scenario.

In our case, we call: 
```dart
await db.commit();
```
when all statements have been executed, unless we detect an error, in which case the `catch` clause gets executed:
```dart
catch (_) {
  await db.rollback();
  rethrow;
}
```

Upon an error, we roll back the transaction and rethrow the exception to be handled further up the call stack.

As for the actual queries, the `DELETE` query is not particularly interesting, it's similar to the `CREATE TABLE` query we've already analyzed in the previous section.

It's the `INSERT` query that contains a new feature. Let's take a closer look:
```dart
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
```
You have probably already noticed the question mark (`?`) placeholders in the `values` clause. This query is **parametrized**, which means the actual data (to be put in place of the `?` placeholders) is provided separately, and not as a part of the SQL statement.

This is **not** the same as a simple Dart string interpolation (which by the way can also be used in FbDb queries - there's nothing preventing you from placing actual stringified values inside your SQL, apart from the **good sense not to do so**, as it is the most common cause of SQL injection attacks).

The parameters passed to a parametrized query are type-checked and converted to the proper representation by the Firebird client routines (a valid *message* buffer is built and the values provided in the `parameters` list are validated against the message *metadata* provided by the Firebird server).

Since our `INSERT` statement contains four parameters (four `?` placeholders, one for each column of the `IMAGES` table), the additional `parameters` argument has to be a list of exactly four items. The types of the items have to be compatible with (i.e. convertible to) the required SQL types of the table columns we put the data into.

Therefore, we pass an `int` (`img.id`), a `String` (`img.title`) another `int` (the length of the PNG data buffer: `img.pngBytes.length`) and a byte buffer (`img.pngBytes`) as the contents of the `parameters` list.

>In our function, we pass the binary data (BLOB) as a byte buffer via the `parameters` list. This approach is very simple and works well for relatively small amount of data. For large BLOBs you can use FbDb's blobs API to send data in chunks; please refer to [FbDb Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/FbDb_guide.md) for more information.

##  8. <a name='Listingimages'></a>Listing images
To show how to execute an SQL statement which opens a database *cursor* and retrieves the rows of data, we will implement a function to list the images from the database. To do so, we will create another function (please remember to put it **above** the definition of the `Image` class):
```dart
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
```

This time the query is not parametrized (we don't need to pass any external values to the SQL statement), but since it returns a set of **rows** of data, we call `FbQuery.openCursor` instead of `FbQuery.execute`. The difference between `openCursor` and `execute` is that the first one allocates a database *cursor*, while the second one does not.

The internal working of the cursor is abstracted away by FbDb. Instead, to iterate over the returned rows of data, you use the `await for` loop, and the data is provided by the Dart stream you obtain by calling `FbQuery.rows`. Each row returned by the stream is a Dart map, whose keys correspond to the names of the columns in the `SELECT` statement, and values are the actual column values in a particular row (the `rows` method's return type is `Stream<Map<String, dynamic>>`).

Therefore, to access the value of a column named `ID` in the row of data represented by the loop variable `row`, you can use a convenient map subscript notation: `row["ID"]`.

>The stream returned by `FbQuery.rows` is a standard *single-subscription* stream (see the [Dart Stream class reference](https://api.dart.dev/stable/dart-async/Stream-class.html) for more details). Among others, it means it's *unidirectional*. Should you need to walk through the rows of data back and forth, you have to cache the rows in the application code.

##  9. <a name='Retrievinganimage'></a>Retrieving an image
To retrieve image data and store it in a file, we'll use an alternative blob handling API in FbDb. Instead of getting the blob bytes directly in the row data returned by a query, we'll fetch just the **blob ID**, and then use the ID to stream the blob binary data directly to a file.

Since we will be using the `File` class from `dart:io`, we need to add the appropriate import at the top of the source file:
```dart
import "dart:io";
```

Next, add the following function above the `Image` class in your source file:
```dart
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
```

This function is rather lenghty, so let's analyze it piece by piece.

```dart
int id = int.parse(results.option("retrieve") ?? "0");
String outFile = results.option("output") ?? "";
if (id <= 0 || outFile == "") {
  throw Exception("Image ID and output file required to retrieve an image");
}
```
First, we get the image ID and the output file name from the command line arguments. If any of them is missing, we leave the function with an exception (there's no point in going further in that case).

```dart
  final q = db.query();
  try {
    await db.startTransaction();
    // ...
  } finally {
    await q.close();
    await db.commit();
  }
```
Next, we obtain an `FbQuery` object from the provided `FbDb` attachment (like we did in all previous database-related functions). The rest of the code is placed inside a `try` ... `finally` block, to make sure the query is properly closed, regardless of the results of the next steps.

We also start an **explicit transaction** (by calling `db.startTransaction`) and make sure it's ended (`db.commit` in the `finally` clause). This step is **required** if you intend to use the alternative blob API. Both sending blobs to the database and retrieving them from the database in this fashion requires an explicit transaction to be active (unlike passing blob data directly in rows / parameters as buffers - it works both with and without an active explicit transaction).

```dart
await q.openCursor(
  sql: "select PNG_DATA from IMAGES where ID=?",
  parameters: [id],
  inlineBlobs: false,
);
```

Our `SELECT` query is an ordinary parametrized query executed with `openCursor` (since we expect to get a row of data back), with **one exception**: we set an additional parameter `inlineBlobs` to `false`. By default, `inlineBlobs` is `true`, which means the blob data is to be returned as byte buffers embedded in the returned rows. That is an easy and practical solution, provided the blobs are relatively small. For really large blobs, you should set `inlineBlobs` to `false` and use the blob API of `FbDb` to retrieve blob data in segments (chunks).

```dart
final row = await q.fetchOneAsMap();
if (row == null) {
  throw Exception("Image with ID $id not found in the database");
}
```
Since our `SELECT` query can result in either a single row of data or no rows at all, instead of using `await for` loop, we make a single call to `FbQuery.fetchOneAsMap`. This method retrieves and returns a single (next in line) row from the result set, unless there are no more rows (or no rows at all), in which case it returns `null`.

We check the returned row against `null`. A null row means there is no image with the specified ID (in which case we just throw an exception and leave the function).

```dart
final blobId = row["PNG_DATA"];
await db.blobToFile(id: blobId, file: File(outFile));
```
Assuming a row was retrieved from the database by our `SELECT` query, its `PNG_DATA` field will contain a `FbBlobId` object (and **not** the contents of the PNG image!). This blob ID can then be used to fetch the actual blob data from the database chunk by chunk. You can call `FbDb.openBlob` to obtain a stream of byte buffers and process the blob data segment by segment, but in our example we use a utility method `FbDb.blobToFile`, which retrieves the blob data (in 4 kB chunks by default, but it's configurable) and stores it in the specified file. 

##  10. <a name='Puttingitalltogether'></a>Putting it all together
The last step left is to put all our functions together. To do so, let's modify the `main` function:
```dart
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
```

We repeatedly use the `wasParsed` method to check which command line arguments the user provided, and we call appropriate functions to handle each scenario. Please note, that the order in which we check the options is **important**. If the user specified, for example, `-c -s -l` at the same time, we want to create the database first, store the images next, and list them last, not the other way around.

##  11. <a name='Runningtheapplication'></a>Running the application
With the source code complete and the Firebird client libraries in place, you may test the application.

For example, try to create the database and store the images in a single run using the *embedded* database access mode:
```bash
dart run bin/imstor.dart -d images.fdb -u SYSDBA -c -s
```

then list the stored images:
```bash
dart run bin/imstor.dart -d images.fdb -u SYSDBA -l
```

and retrievie the image with ID 5, storing it in a PNG file:
```bash
dart run bin/imstor.dart -d images.fdb -u SYSDBA  -r 5 -o image_5.png
```

(check out the created `image_5.png` file - it's an actual image!).

To use an actual Firebird server, make sure you choose the database path the server process can write to, e.g.:
```bash
dart run bin/imstor.dart -d localhost:/tmp/images.fdb -u SYSDBA -p masterkey -c -s
```

>Put your actual Firebird credentials in place of "SYSDBA" and "masterkey" in the above example.

##  12. <a name='Thecompletesource'></a>The complete source
```dart
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
```

The tutorial is complete, thank you for your time!