# FbDb Programmer's Guide
This guide is copyritht © 2025 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is copyright © 2025 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is licensed under open source BSD license (see the [LICENSE](https://github.com/hipercompl/fbdb/blob/main/LICENSE) file).

**TABLE OF CONTENTS**

<!-- vscode-markdown-toc -->
* 1. [Introduction](#Introduction)
	* 1.1. [Importing the module](#Importingthemodule)
	* 1.2. [Mixing the low-level and high-level API](#Mixingthelow-levelandhigh-levelAPI)
* 2. [Working with databases](#Workingwithdatabases)
	* 2.1. [Opening a connection](#Openingaconnection)
	* 2.2. [Firebird client library binaries and other supporting files](#Firebirdclientlibrarybinariesandothersupportingfiles)
		* 2.2.1. [Opening connections - examples](#Openingconnections-examples)
	* 2.3. [Closing the connection](#Closingtheconnection)
		* 2.3.1. [Closing connections - examples](#Closingconnections-examples)
	* 2.4. [Connection configuration](#Connectionconfiguration)
* 3. [Error reporting](#Errorreporting)
	* 3.1. [Error reporting examples](#Errorreportingexamples)
* 4. [Executing SQL statements](#ExecutingSQLstatements)
	* 4.1. [Creating query objects](#Creatingqueryobjects)
	* 4.2. [Executing queries](#Executingqueries)
		* 4.2.1. [Query parameters](#Queryparameters)
		* 4.2.2. [Type mapping](#Typemapping)
		* 4.2.3. [Executing queries - examples](#Executingqueries-examples)
	* 4.3. [Closing the query](#Closingthequery)
	* 4.4. [Accessing data](#Accessingdata)
		* 4.4.1. [Methods of the `FbQuery` objects](#MethodsoftheFbQueryobjects)
		* 4.4.2. [Using row streams](#Usingrowstreams)
		* 4.4.3. [Utility methods: selectOne, selectAll, execute](#Utilitymethods:selectOneselectAllexecute)
	* 4.5. [Queries - examples](#Queries-examples)
	* 4.6. [Prepared SQL statements](#PreparedSQLstatements)
		* 4.6.1. [Prepared statements - an example](#Preparedstatements-anexample)
* 5. [Transaction handling](#Transactionhandling)
	* 5.1. [The model](#Themodel)
	* 5.2. [Implicit transactions](#Implicittransactions)
	* 5.3. [Explicit transactions](#Explicittransactions)
		* 5.3.1. [Utility method: runInTransaction](#Utilitymethod:runInTransaction)
	* 5.4. [Transaction flags](#Transactionflags)
	* 5.5. [Transactions - examples](#Transactions-examples)
* 6. [Working with blobs](#Workingwithblobs)
	* 6.1. [Passing blobs as query parameters](#Passingblobsasqueryparameters)
	* 6.2. [Fetching blobs from selected rows](#Fetchingblobsfromselectedrows)
	* 6.3. [Examples - blobs](#Examples-blobs)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='Introduction'></a>Introduction
This document is a programmer's manual for the high-level part of the *fbdb* library. If you need to access the low-level bindings to the Firebird client interfaces, please refer to the [FbClient Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbclient_guide.md) for more details.

It is also recommended to read the [FbDb Architecture Overview](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_arch.md) in order to get familiar with the basic concepts and the design of the FbDb library.

To get the naming straight, let's agree on the following terminology:
- **fbdb** is the name of the library (package), as published on pub.dev - it should be added to the pubspec.yaml of your project as a dependency,
- **FbDb** is the high-level part of the library, and, at the same time, the name of the main class of the high-level API,
- **FbClient** is the low-level part of the library, and, at the same time, the name of the main class of the low-level API.

###  1.1. <a name='Importingthemodule'></a>Importing the module
To use the high-level part of the fbdb library, add the following import to your code:
```dart
import "package:fbdb/fbdb.dart";
```

###  1.2. <a name='Mixingthelow-levelandhigh-levelAPI'></a>Mixing the low-level and high-level API
As was already mentioned, the fbdb library consists of two different APIs:
- FbDb is the high-level, Dart-idiomatic API, intended to be used by client (your) code, which will be extended in the next releases in terms of available functionality,
- FbClient is the low-level API, consisting mainly of Dart bindings to the C++ Firebird client interfaces.

You can use either of them (by importing the appropriate module from the library) and you can even mix them in a single project.

However, since FbDb is designed with asynchrony in mind, the actual interaction with the database takes place in a background isolate. That's where the native Firebird client code gets called. The native memory (and pointers) cannot be transferred between isolates, therefore your main application isolate doesn't (and cannot) have access to the FbClient objects that are used by the worker (background) isolate.

In summary, you can mix low-level and high-level APIs, but since you cannot access the underlying low-level interfaces of the existing FbDb objects,  the mixing is useful only in some specific scenarios (e.g. you use the FbDb API to interact with the database, but switch to the FbClient API to talk to the service manager).

##  2. <a name='Workingwithdatabases'></a>Working with databases
To begin work with the Firebird database, you need an instance
of the `FbDb` class, which encapsulates a database connection. 

The functionality of a connection
object includes:
- attaching to existing databases,
- creating new databases,
- creating query objects, which allow to send SQL statements to the database and to get the results back,
- starting transactions, committing transactions and rolling them back,
- storing and retrieving BLOB (*B*inary *L*arge *OB*ject) data,
- dropping (deleting) entire databases.

###  2.1. <a name='Openingaconnection'></a>Opening a connection
To have a working connection, you need to instantiate the class `FbDb` in one of the following ways:
- to attach to an existing database, use the static `attach` method:
```dart
final con = await FbDb.attach({...parameters});
```
- to create a new database, use the static `createDatabase` method:
```dart
final con = await FbDb.createDatabase({...parameters});
```
The required connection parameters are described below.

> Please note that virtually all (with very few exceptions) methods of FbDb objects are **asynchronous**, therefore you need to `await` them to get the actual results (otherwise you just get back a `Future` object instead of the actual result). More on this subject can be found in the [FbDb architecture overview](https://github.com/hipercompl/fbdb/blob/main/doc/FbDb_arch.md) document. Simply speaking, asynchronous methods don't block the main event loop of your application, letting it respond to events and update the user interface (otherwise a lengthty database operation would cause the client application to freeze).

`parameters` represent a set of named parameters, in which you need
to provide all required information to perform an *attach*
or *create database* operation.
The supported parameters are:
- `host` (String) - the host name / IP address of the host, on which Firebird is running (e.g. `"localhost"`). This parameter is optional. If not provided, an embedded mode will be used.
- `port` (int) - the port, on which the Firebird process is listening for incoming connections (3050 by default). This parameter is not required.
- `database` (String) - the path or alias name of the database, to which to attach or which to create. In this parameter you can specify either the complete path to the database file, or an alias name, for which a corresponding entry in `databases.conf` exists on the target machine. This parameter is **required**.

- `user` (String) - the user name. This parameter is not required.
- `password` (String) - the user password. This parameter is not required.
- `role` (String) - the role, in which the specified user acts (e.g. `"RDB$ADMIN"`). This parameter is not required.
- `options` - an object of class `FbOptions`, which allows to adjust some internal parameters of the connection (see the section about the [connection configuration](#connection-configuration) below).

> **Note**: it might be a good idea to use raw strings as parameter values. In raw strings you don't need to escape special characters (like `$` or `\`). In other words, either pass `r"RDB$ADMIN"` as a role, or escape the `$` character, passing `"RDB\$ADMIN"`. Similarly, either pass `r"C:\tmp\db.fdb"` or `"C:\\tmp\\db.fdb"` as a database path on Windows.

In case you wonder why there's no `charset` (or similar) parameter (although it is present in the Firebird client), it's because the client character set is always set to UTF-8, to provide robust string translation between Dart code and the database.

> You can use the new format of database specification (of the form `protocol://host:port/db path or alias`). To do so, omit `host` and `port` parameters and pass these values as part of the `database` instead. The older format of the connection string (`host/port:database`) is also supported. Please refer to the Firebird manual for further details.

###  2.2. <a name='Firebirdclientlibrarybinariesandothersupportingfiles'></a>Firebird client library binaries and other supporting files

FbDb requires the actual Firebird client library (for the proper system architecture), together with all its dependencies, to be available for the application in order to connect to a database.

Before you run your Dart program, make sure the FbDb library can access **libfbclient**. How to do that depends on the target operating system:
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
    - Modify the `AdnroidMainfest.xml` file of your Flutter project, located in `android/app/src/main` directory, and add the following permission declaration to the manifest (you can add the line below right after the closing `</application>` tag):
        ```xml
        <uses-permission android:name="android.permission.INTERNET"/>
        ```
        Otherwise the relase build of your Flutter application won't be able to access the network, which in turn will prevent it from attaching to a Firebird server.
- For iOS Flutter apps, the procedure is yet to be determined (not tested yet).


> **Note**: you can place the Firebird client dynamic library in any path you will, provided you specify the exact location in the `options` parameter when opening a connection. The locations mentioned above are just the defaults.

>In all cases, it's best to consult the official [Firebird client installation guide](https://firebirdsql.org/file/documentation/html/en/firebirddocs/qsg5/firebird-5-quickstartguide.html#qsg5-installing-client) first.

If you plan to use the *embedded* connection mode (i.e. no actual Firebird server process and the client library working as a server), you should follow a particular Firebird version's installation guide on how to prepare your application directory to use Firebird embedded mode. Usually, in addition to the Firebird client library, the `firebird.msg` error message file should be available (preferably in the same directory), and the `plugins` and `intl` subdirectories should contain the proper database access engine and localization files. Please refer to [this paper](https://www.ibphoenix.com/files/Embedded_fb3.pdf) by Hellen Borrie and Vlad Khorsun and [this firebird-support list thread](https://groups.google.com/g/firebird-support/c/rxuFqYTY5Nw) for additional information.

> The `firebird.conf` configuration file can also be present in the same directory as the client library, if special client configuration is required (e.g. a non-default authentication method, wire encryption etc.).

For example, a 64-bit Windows application `example.exe`, using a 64-bit Firebird 5.0 client should contain **at least** the following files:
```
application directory
|
+-- example.exe
|
+-- fbclient.dll
|
+-- vcruntime140.dll
|
+-- vcruntime140_1.dll
|
`-- msvcp140.dll
```
(the C runtime DLLs are not required if you've got a compatible Visual C++ runtime installed system-wide).

Should the file / directory layout look for example like this:
```
application directory
|
+-- example.exe
|
`-- lib/
    |
    +-- fbclient.dll
    |
    +-- vcruntime140.dll
    |
    +-- vcruntime140_1.dll
    |
    `-- msvcp140.dll
```
the path (relative or absolute) to `fbclient.dll` can be specified when opening a connection:
```dart
final db = FbDb.attach(
    host: "localhost",
    database: "employee",
    user: "SYSDBA",
    password: "masterkey",
    options: FbOptions(
        libFbClient: r"lib\fbclient.dll"
    ),
);
```

####  2.2.1. <a name='Openingconnections-examples'></a>Opening connections - examples
Attach to the database specified by an alias `employee` on `localhost` (using the client/server mode via a TCP/IP loopback connection):
```dart
final con = await FbDb.attach(
    host: "localhost",
    database: "employee",
    user: "sysdba",
    password: "masterkey",
);
```

The same as above, but using a connection string:
```dart
final con = await FbDb.attach(
    database: "inet://localhost:3050/employee",
    user: "sysdba",
    password: "masterkey",
```

Attach to the database file `employee.fdb` (located in the same directory as the application executable) using embedded connection mode:
```dart
final con = await FbDb.attach(
    database: "employee.fdb",
    user: "sysdba",
);
```

Create a new database, with 4kB pages, located at the path `/tmp/tst.fdb` at the local host:
```dart
final con = await FbDb.createDatabase(
    host: "localhost",
    database: "/tmp/tst.fdb",
    user: "sysdba",
    password: "masterkey",
    options: FbOptoins(
        pageSize: 4 * 1024,
    ),
);
```

###  2.3. <a name='Closingtheconnection'></a>Closing the connection
After a connection has been successfully initialized, it is possible to interact with the database via `FbQuery` objects (described later). When done, you need to close the connection to release resources associated with it both on the server and in the client code.

> FbDb supports multiple attachments to the same database at the same time from a single application. You just need to instantiate `FbDb` multiple times.

To close a connection, wchich is currently attached to a database, you call:
- `detach` - to close the connection, eventually rolling back any uncommitted transactions (see [transaction handling](#Transactionhandling)),
- `dropDatabase` - to physically delete the database from the file system.

> It is **very important** to close the connection when no longer needed. Neglecting to do so may result in your application not being terminated correctly, due to the database communication worker (background isolate) still being active. It is recommended to follow the pattern:

```dart
FbDb? connection;
try {
    connection = FbDb.attach(/*parameters*/);
    // issue queries, etc.    
} finally {
    await connection?.detach();
    // set the connection to null 
    // to prevent accidentally 
    // calling its methods
    connection = null;
}
```

####  2.3.1. <a name='Closingconnections-examples'></a>Closing connections - examples
```dart
FbDb? con;
try {
    con = await FbDb.attach(
        host: "localhost",
        database: "employee",
        user: "sysdba",
        password: "masterkey",
    );
    // interact with the database
} finally {
    await con?.detach();
    con = null;
    // the connection is invalid after detach
}
```

```dart
FbDb? con;
try {
    con = await FbDb.createDatabase(
        host: "localhost",
        database: "/tmp/tst.fdb",
        user: "sysdba",
        password: "masterkey",
        options: FbOptions(
            pageSize: 4096, // 4 kB database pages
        ),
    );
    // interact with the database
} finally {
    await con.dropDatabase();
    con = null;
    // the connection is invalid after this point
    // the database /tmp/tst.fdb is physically removed
}
```

###  2.4. <a name='Connectionconfiguration'></a>Connection configuration
When opening a database connection, you can adjust some of the connection settings. To do that, you need to pass a `FbOptions` object when creating a new `FbDb` connection object.
The `FbOptions` constructor allows you to pass the following parameters (all of them are named and optional, with sane default values):
- `String libFbClient` - specifies the path to a particular Firebird client library to be used by this database connection. Please note, that `libFbClient` parameter allows you to change not only the location of the Firebird client library, but also the name of the library file itself. See also [Firebird client library binaries and other files](#Firebirdclientlibrarybinariesandotherfiles) section.
- `pageSize` (int) - the page size (in bytes) of the database to be created, relevant only when calling `createDatabase`, otherwise ignored. Default: `4096`.
- `dbCharset` (string) - the default character encoding of the database to be created, relevant only when calling `createDatabase`, otherwise ignored. Default: `"UTF8"`. Keep in mind, that `dbCharset` defines the character set of the newly created database, and not the client character set for the connection (which, as was already mentioned, is always UTF-8).
    > Please note, that if you wish to create a database without a default encoding, you have to explicitly pass `dbCharset="NONE"` (otherwise UTF-8 will be set as the database encoding).
- `transactionFlags` (`Set<FbTrPar>`) - a set of flags, defining the transaction isolation level, lock resolution mode, table reservation and access mode, used as defaults for all transactions in this database connection. The flags are defined in the `FbTrPar` enumeration. The following constants are available:
    - access mode options: 
        - `read`, 
        - `write`,
    - isolation level options: 
        - `concurrency`, 
        - `consistency`, 
        - `readCommitted`, 
        - `recVersion`, 
        - `noRecVersion`,
    - lock resolution: 
        - `wait`, 
        - `noWait`,
    - table reservation:
        - `shared`,
        - `protected`,
        - `exclusive`,
        - `lockWrite`,
        - `lockRead`.

    The flags can be combined into a set. You can pass for example `{FbTrPar.write, FbTrPar.noWait, FbTrPar.concurrency}` as `transactionFlags`.
    If not otherwise specified, transactions are started with the flags `{FbTrPar.write, FbTrPar.concurrency, FbTrPar.wait}`, which is the default transaction mode in Firebird.
- `lockTimeout` (int) - if transactions were defined with the `FbTrPar.wait` flag, this parameter allows to define the maximum time a transaction will wait to resolve a lock conflict. If the timeout occurs, an exception gets thrown.

##  3. <a name='Errorreporting'></a>Error reporting
The original Firebird API uses the concept of a **status vector** to indicate possible error conditions. It requires passing the vector (which is actually just a memory buffer) to each API call, and checking the contents of the vector after the API function returns.

It would be cumbersome to use a similar method in Dart, for which a natural way of signaling errors is throwing exceptions, and a natural way of detecting errors is catching exceptions.

That's why status vectors are handled internally by FbDb, and a convenient exception-based mechanism for error reporting is exposed to the application code. However, status vectors are still available (they're embedded inside the exceptions), should a need arise to access it directly.

The exceptions in FbDb are divided into two general cathegories:
- `FbServerException` - encapsulates the aforementioned status vector and generally indicates an error reported back by the native Firebird client library. The error does not necessary originate from the Firebird server process, but nevertheless it's reported by the underlying native code. These exceptions are thrown for example upon a malformed SQL statement, invalid parameter values or database constraint violation.
- `FbClientException` - signals an error originating from the FbDb code. Usually it means an FbDb object has been used improperly, for example a query object was asked for data rows while no SQL statement had been executed via the query.

Both `FbServerException` and `FbClientException` contain an error `message`. The `FbServerException` objects additionally contain the `errors` list (a list of `int`s), which correspond to the actual error flags from the Firebird status vector. The `message` field in `FbServerException` usually contains the actual Firebird server message corresponding to the error code from the status vector.

To make it easier to check for a particular error code in the `FbServerException`, this exception class contains two convenience methods:
- `hasError(code)` - informs whether the server error vector contains the given code,
- `hasAnyError(codes)` - informs whether the server error vector contains any of the given codes (`codes` are a `Set<int>`).

All Firebird error codes are listed in the `FbErrorCodes` class.

###  3.1. <a name='Errorreportingexamples'></a>Error reporting examples

React if a query causes a deadlock (a lock conflict with another transaction).
```dart
try {
    q.execute(
        sql: "update EMPLOYEE "
             "set FIRST_NAME=upper(FIRST_NAME)",
    );
} on FbServerException catch (e) {
    if (e.hasError(FbErrorCodes.isc_deadlock)) {
        print("Lock conflict detected!");
    } else {
        print("Error detected: $e");
    }
}
```

Detect truncation errors (string or blob). Checks for any error code from the given set.
```dart
try {
    q.execute(
        sql: "update EMPLOYEE "
             "set DEPT_NO=DEPT_NO||DEPT_NO",
    );
} on FbServerException catch (e) {
    if (
        e.hasAnyError({
            FbErrorCodes.isc_string_truncation, 
            FbErrorCodes.isc_blob_truncation,
        })) {
        print("Column too short. Data truncated.");
    } else {
        print("Error detected: $e");
    }
}
```

##  4. <a name='ExecutingSQLstatements'></a>Executing SQL statements
To talk to an SQL database, your code needs a way to send SQL statements to the server process and get back the results of the queries.

In FbDb, the SQL statements are executed with the use of `FbQuery` objects. Each `FbQuery` allows you to send any number of successive SQL statements to the database server, and to fetch the results of the statements.

###  4.1. <a name='Creatingqueryobjects'></a>Creating query objects
To create a new query object, it's best to use the `query` method of the `FbDb` object:
```dart
// db is an attached connection
final q = db.query();
```

Please note two details of the above code:
- in order to create a query, you need to use a valid, **attached** connection,
- the `query` method is **not** asynchronous, i.e. you don't need to `await` it.

The last property is implied by the fact, that simply creating a query object doesn't send any data to the database, therefore no time-consuming I/O operations take place and there is no need for asynchrony here.

As an alternative, you can use the `forDb` constructor of `FbQuery`:
```dart
// db is an attached connection
final q = FbQuery.forDb(db);
```

There are no significant advantages of one method over the other.

###  4.2. <a name='Executingqueries'></a>Executing queries

Before we get into details of the `FbQuery` API, we need to introduce a clear distinction between two cathegories of SQL statements:
- statements that return a set of rows - usually those are `SELECT` statements (although in Firebird, `EXECUTE BLOCK` statements can also return a set of rows),
- statements that do not return a set of rows - for example, all DDL (data definition) statements belong to this group, as well as most DML (data manipulation) statements. That is, all `CREATE`, `ALTER`, `DROP`, `UPDATE`, `INSERT`, and `DELETE` statements belong to the group of statements, which don't return row sets (strictly speaking, DML with `RETURNING` clause may return rows, but we will disregard it for now to keep things as simple as possible).

Depending on the kind of SQL statement you intend to send to the database, you need to use a proper method of the `FbQuery` object:
- for statements that **do** return a data set, use the `openCursor` method, for example:
```dart
await q.openCursor(sql: "select * from EMPLOYEE");
```
- for statements that **do not** return a data set, use the `execute` method, for example:
```dart
await q.execute(sql: "delete from COUNTRY");
```

Calling the wrong method may result in an exception (when you use `openCursor` with an SQL statement that doesn't return a data set; the other way around will result in a query that gets executed but you won't have any way to access the data).

> **Note**: similarly to the `FbDb` class, virtually all `FbQuery` methods are **asynchronous**, i.e. they are non-blocking and return a `Future`, so you need to `await` them in order to get the actual results.

The way of getting hold on the actual data returned by a query is described in the section [Accessing data](#Accessingdata) later on. 

####  4.2.1. <a name='Queryparameters'></a>Query parameters
The SQL statements executed via the query objects can be parameterized. It means they can contain **placeholders**, and the actual values being put into them are provided separately from the actual SQL text.
For example, the following SQL statement:
```sql
select NAME from EMPLOYEE where EMP_NO < ?
```
contains **one** parameter placeholder (the placeholders are denoted by question marks - `?` - within the SQL text). Therefore, when you execute this statement via `FbQuery.openCursor`, apart from providing the SQL text, you need to pass a single additional value in the *parameter list*. It may look like this:
```dart
await q.openCursor(
    sql: "select NAME from EMPLOYEE where EMP_NO < ?",
    parameters: [10],
);
```
The value `10` will be passed to the Firebird server in place of `?`, and the resulting `where` condition will be interpreted as `EMP_NO < 10`.

One might ask: why not use Dart's string interpolation and just place the values inside the SQL text? There are several reasons why it is **not** a good idea. The first and most important is security. Building a query by concatenating or interpolating strings may lead to severe security vulnerabilities in the application (the most common of which is the *SQL injection*). Apart from security, there are some cases when the value has to be passed in a certain format (e.g. floats, dates, timestamps) and using the parametrized queries takes care of proper data formatting.  

> There's nothing preventing you from building SQL queries by concatenating or interpolating strings, but every database programming manual will advise against it. So maybe just don't - there's very little to gain and a lot to loose.

When passing values in the parameter list, please keep in mind that the number of values in the list has to match **exactly** the number of placeholders (`?`) in the query - even if some of the values are acually the same.
For example, imagine you need all employees whose either of `NAME` or `SURNAME` contains a certain substring (the substring is contained in the variable `subs`).
Running such query in parametrized manner would look like this:
```dart
var subs = "JOHN";
// assume q is a valid FbQuery object
await q.openCursor(
    sql: "select * from EMPLOYEE "
         "where NAME contains ? or SURNAME contains ?",
    parameters: [subs, subs]
);
```
Please note, that `subs` has to be passed **twice**, because there are two placeholders in the query, which just accidentally, in this particular case, correspond to the same value (the current contents of the `subs` variable).

####  4.2.2. <a name='Typemapping'></a>Type mapping
In order to know, how to pass query parameters correctly and what to expect when fetching query results, one has to know, how the SQL data types in the Firebird database are mapped to their corresponding types in Dart.

The type mappings are as follows:
- SQL textual types (`CHAR` and `VARCHAR`) are mapped to `String` in Dart,
- SQL integer types (`SMALLINT`, `INTEGER`, `BIGINT`) are mapped to `int` (64-bit integer) in Dart,
- SQL integer type `INT128` is mapped to `double` in Dart (there's no 128-bit integer type available),
- SQL real numbers (`DOUBLE PRECISION`, `NUMERIC(N,M)`, `DECIMAL(N,M)`) are mapped to `double` in Dart,
- SQL date and time types (`DATE`, `TIME`, `TIMESTAMP`) are mapped to Dart `DateTime` objects,
- the same applies to SQL types `TIME WITH TIME ZONE` and `TIMESTAMP WITH TIME ZONE` (they are both mapped to `DateTime` in Dart), which is unfortunate, because currently Dart's `DateTime` does not support arbitrary time zones (it only supports UTC and the local time zone of the host); this issue will be addressed in future releases of *fbdb*,
- SQL `BOOLEAN` is mapped to `bool` in Dart,
- parameters of the SQL `BLOB` type can be passed to a query as `ByteBuffer` objects, any `TypedData` objects (from which a byte buffer can be obtained), as `String` objects (in which case they will be encoded as UTF8 and passed byte-by-byte) or as `FbBlobId` objects (for BLOBs stored beforehand); the returned values are always either `ByteBuffer` objects or `FbBlobId` objects (depending on whether BLOB inlining is turned on or off for a particular query). See also the [Working with blobs](#Workingwithblobs) section.

####  4.2.3. <a name='Executingqueries-examples'></a>Executing queries - examples
A query that does not return a data set:
```dart
// con is an attached connection
final q = con.query();
await q.execute(
    sql: "update EMPLOYEE set NAME = upper(NAME) where EMP_NO = ?", 
    parameters: [5]
);
final changed = await q.affectedRows();
print("$changed rows updated");
await q.close();
```

A query that returns a data set:
```dart
// con is an attached connection
final q = await con.query();
await q.openCursor(
    sql: "select * from EMPLOYEE where DEPT_NO = ? and JOB_CODE = ?", 
    parameters: [120, "Eng"]
);
await for (final row in q.rows()) {
    // row is a map: field name => field value
    print("${row['EMP_NO']} :: ${row['NAME']}");
}
await q.close();
```

> When the SQL statement is long, you can break it into separate strings (lines), using the Dart feature of concatenating adjacent strings. Remember to start or end each string with a space, to avoid glueing tokens together:
```dart
    await q.execute(
        sql: "update EMPLOYEE " // <- space an the end
             "set SALARY = SALARY * ? " // <- space at the end
             "where DEPT_NO = ?", // <- this line doesn't need to end with a space
        parameters: [1.1, "E_20"]
    )
```

###  4.3. <a name='Closingthequery'></a>Closing the query
When you're done working with the results of a particular query, you should **close** the query. Closing a query releases resources allocated for processing the SQL statement and its results.

To close a query, call (and **await**) its `close` method:
```dart
final q = con.query();
await q.openCursor(sql: "select * from EMPLOYEE");
// process the results of the statement
await q.close();
```

> Calling `openCursor` or `execute` on a query object, which contains another open (i.e. **not closed**) statement, causes automatic closing of the previous statement (and its result set, if present) before executing the new SQL statement. However, it is a good habit to call `close` as soon as the query is no longer needed, to conserve system resources.

###  4.4. <a name='Accessingdata'></a>Accessing data
After running a query with `openCursor` (which executes the SQL statement and opens a *cursor*, i.e. makes arrangements with the database server to prepare for fetching rows of data from the result set), you can access the resuling data set in two ways:
- using the `FbQuery` methods from the `fetch` family to walk through the data set and fetch individual rows or groups of rows,
- using the `rows` method to obtain a `Stream` of rows and process them all with an `await for` loop.

####  4.4.1. <a name='MethodsoftheFbQueryobjects'></a>Methods of the `FbQuery` objects
After opening a query, you can use the following methods of the query object:
- `fieldDefs()` - returns a list of field definitions (`FbFieldDef` objects). Each field definition has the following attributes:
    - `name` - the field name,
    - `type` - the data type of the field,
    - `length` - the field length / size (where appropriate),
    - `scale` - the field scale for numeric fields,
    - `subType` - the blob sub-type,
    - `nullable` - whether the field can be null,    
    - `fbType` - the Firebird internal type code,
    - `offset` - the byte offset of this field in the row data buffer.
- `fieldNames()` - returns a list of just the field names in the result set.
- `fetchOneAsMap()` - fetches the next row from the data set as a map, with field names as keys (`null` is returned when there are no more rows in the data set),
- `fetchOneAsList()` - fetch the next row from the data set as a list of *field values*, without the names (`null` is returned when there are no more rows in the data set),
- `fetchAsMaps(maxCount)`, `fetchAsLists(maxCount)` - both fetch a group of rows, returning them as a list of maps or a list of lists (see `fetchOneAsMap` and `fetchOneAsList`); the returned list contains at most `maxCount` rows, but may be shorter if there are no more rows in the data set (in particular, upon reaching the end of the data set, an empty list will be returned),
- `fetchAllAsMaps()`, `fetchAllAsLists()` - both fetch *all* remaining rows from the data set and returns a list of maps or a list of lists (see `fetchOneAsMap` and `fetchOneAsList`); use with care, because it may consume a lot of memory (all rows are cached in the process memory), usually it's a better idea to use `fetchAsMaps` or `fetchAsLists` to process rows chunk by chunk or to iterate over the stream of rows (see the next section),
- `affectedRows()` - for DML queries (`INSERT`, `UPDATE`, `DELETE`) it returns the number of rows, which have been affected by the query,
- `getOutputAsMap()` - fetches the values, which have been returned from a query in output parameters (for example, an `EXECUTE PROCEDURE` statement, in which the stored procedure being executed contains output parameters and doesn't contain `SUSPEND`, i.e. one can't `SELECT` from the procedure); the values are returned in the same form as in `fetchOneAsMap`.
- `getOutputAsList()` - like the above, but returns just the list of values, not associating them with field names (it 's similar to `fetchOneAsList` in this regard).

>Please keep in mind, that all the above methods are **asynchronous** and you need to `await` their results.

>In the current version of FbDb, all queries are **unidirectional**, i.e. you can fetch subsequent rows, but you can't go back and access the previous rows. That may change in the future, especially now that Firebird supports server-side bidirectional cursors. For now, if you need to traverse the rows back and forth, you need to cache them in your code.

####  4.4.2. <a name='Usingrowstreams'></a>Using row streams
To use a Dart-idiomatic way of accessing rows, call the `FbQuery.rows()` method to obtain a `dart:async.Stream` object representing all rows of the result set (all remaining rows, to be precise). The stream can be iterated over with a standard `await for` loop:
```dart
await q.openCursor(sql: "select * from EMPLOYEE");
await for (var row in q.rows()) {
    // process the row
}
```

Obviously, calling `rows` makes sense only for queries, on which `openCursor` was called, and cannot be used on queries launched with `execute`. The latter don't return a data set, so there are no rows to iterate over.

The stream returned by `rows` can be used as any other stream in Dart, in particular the full `dart:async.Stream` API is available.

>Please note, that the `rows` method is **not** asynchronous, i.e. you don't need to `await` its results. That's because it only initializes the stream object and doesn't fetch any actual data yet.

>**Warning**. You should not call `rows()` while another stream returned by an earlier call to `rows()` (from the same query object) is still in use. The new call will cause the previous stream to be closed immediately. Similarly, you shouldn't call the `fetchOneAsMap`, `fetchAsLists`, etc. methods while iterating over a stream returned by `rows()`: these methods and the stream operate on the same physical data set.

####  4.4.3. <a name='Utilitymethods:selectOneselectAllexecute'></a>Utility methods: selectOne, selectAll, execute

It is a common scenario to execute a `SELECT` statement and fetch a single row of the result. Or execute `SELECT` and fetch all rows immediately (as a list). Or execute `INSERT` or `UPDATE` without getting any data back.

For these common tasks, the `FbDb` attachment object contains three utility methods: `selectOne`, `selectAll` and `execute`.

> Note, that `selectOne`, `selectAll` and `execute` are called directly from an attachment object, not from a query object.

The parameters of the methods are identical to those of `FbQuery.openCursor` and `FbQuery.execute`, resp. (in fact, underneath the hood the utility methods actually call `openCursor` or `execute` on an internally created `FbQuery` object, passing down all parameters and passing the results back up the call stack). The only exception is that `execute` accepts one more named parameter: `returnAffectedRows`. If set to `true` (the default value is `false`), `execute` will return the number of rows affected by the SQL statement (if `returnAffectedRows` is `false`, `execute` always returns `0`).

A temporary query object is instantiated internally in each of these methods, the statement gets executed, the results (in case of `selectOne` and `selectAll`) are fetched (a single row or all rows), and finally the temporary query gets closed automatically.

So, it's nothing that couldn't be done in code, it just saves some typing.

Examples:
```dart
    // db is an attached connection
    final cntRow = await db.selectOne(
        sql: "select count(*) as CNT from EMPLOYEE",
    );
    // cntRow is a map
    print(cntRow?["CNT"]); // cntRow is nullable
```

```dart
    // db is an attached connection
    final emps = await db.selectAll(
        sql: "select * from EMPLOYEE",
    );
    // emps is a list of maps, possibly empty
    for (var e in emps) {
        print(e["FIRST_NAME"]);
    }
```

```dart
    // db is an attached connection
    final affected = await db.execute(
        sql: "update EMPLOYEE set FIRST_NAME=? where EMP_NO=?",
        parameters: ["Adam", 5],
        returnAffectedRows: true,
    );
    print(affected); // "1"
```

###  4.5. <a name='Queries-examples'></a>Queries - examples
A common case: select the data from a table and process all rows of the result.
```dart
var q = db.query();
await q.openCursor(
    sql: "select * from EMPLOYEE where EMP_NO < ?",
    parameters: [100],
);
// q.rows() is a stream of rows (as maps)
await for (var r in q.rows()) {
    print("${r['EMP_NO']}: ${r['FIRST_NAME']}");
}
await q.close();
```

Update some rows and check how many have been affected by the update.
```dart
var q = db.query();
await q.execute(
    sql: "update EMPLOYEE set SALARY = SALARY * ? "
         "where EMP_NO between ? and ?",
    parameters: [1.1, 10, 100],
);
final ar = await q.affectedRows();
print("$ar employees got a raise");
```

For more examples, please take a look at the `example/fbdb/` folder. Most of the examples there use queries of one kind or another.

###  4.6. <a name='PreparedSQLstatements'></a>Prepared SQL statements
Some scenarios require multiple executions of the same SQL statement, but with different values passed as the query parameters.

While it is possible to use the standard `FbQuery.execute` / `FbQuery.openQuery` procedure, each call to `execute` or `openQuery` causes the SQL statement to be prepared anew, discarding previously prepared and executed one.

In such cases, it is more efficient to prepare a statement once, and then execute it multiple times, substituting different values for query parameters with each execution.

FbDb, starting with version 1.3, allows the application code to *prepare* a query in a separate step, and then to *execute* it as many times, as necessary, each time providing a different set of parameter values.

To prepare a statement, you need a `FbQuery` object, which you obtain as usual, by calling the `FbDb.query` method on an open attachment. Then, you call the `prepare` method on the query, providing an SQL statement to be parsed and prepared by the Firebird database server. The statement may contain any number of the `?` parameter placeholders.

When a query contains a prepared SQL statement, you can then call `executePrepared` or `openPrepared` multiple times, providing a new list of values for the query parameters with each execution. `executePrepared` and `openPrepared` correspond to the `execute` and `openCursor` methods, except they do not accept an SQL statement string, as the statement has beeen already passed and prepared when `prepare` was called.

> **IMPORTANT!** Do not call `close` on a prepared query between subsequent executions of the query. Calling `FbQuery.close` discards the prepared statement associated with the query. Calling `executePrepared` / `openPrepared` after `close` (and before another `prepare`) will cause an exception.

A query executed via `executePrepared` or `openPrepared` can be processed later in exactly the same way, as a query executed via `execute` or `openCursor`. The same rules and restrictions apply.

####  4.6.1. <a name='Preparedstatements-anexample'></a>Prepared statements - an example

Suppose you've got a database table `DICT`, with a dictionary-like structure, consisting of an integer `ID` field and a text `DESCRIPTION` field.

Now suppose you need to fill this table with a predefined data. For the sake of the example, we assume the data is a hardcoded list, but it could as well come from a file, a network connection, etc.

The hardcoded data is as follows:
```dart
final data = [
    [1, 'Description 1'],
    [2, 'Description 2'],
    [3, 'Description 3'],
    // imagine that many more entries follow
];
```

One way to put the entries from `data` into the table `DICT` would be:

```dart
// db is an attached FbDb connection
final q = db.query();
for (final [id, desc] in data) {
    await q.execute(
        sql: "insert into DICT(ID, DESCRIPTION) "
            "values (?, ?)",
        parameters: [id, desc],
    );
    await q.close();
}
```

This method works fine, but becomes inefficient with the growing number of entries in `data`.

The `INSERT` query is being parsed and prepared in each iteration, despite the fact that the actual SQL statement remains unchanged. It's only the data being inserted that's different in each iteration, not the statement.

To make the above loop more efficient, use a **prepared** query, like this:
```dart
// db is an attached FbDb connection
final q = db.query();
await q.prepare(
    sql: "insert into DICT(ID, DESCRIPTION) "
         "values (?, ?)",
);
for (final [id, desc] in data) {
    await q.executePrepared(
        parameters: [id, desc],
    );
}
await q.close();
```

Now the query is prepared once, before the loop. In each loop iteration, the previously prepared query gets executed (with different parameter values), which should be faster than the original loop.

Notice, that you don't call `close` after each `executePrepared` (it's called just once, after the `for` loop ends). Calling `close` discards the prepared statement.

##  5. <a name='Transactionhandling'></a>Transaction handling

###  5.1. <a name='Themodel'></a>The model
Currently, FbDb uses a mixed transaction model, in which some transactions are **implicit**, and some are **explicitly** started and finished.

Implicit transactions are started and finished automatically, and cover a single query execution (see the next section).

Explicit transactions are started on demand (by calling `startTransaction`) and need to be either committed or rolled back (by calling `commit` or `rollback`, respectively). Multiple subsequent queries can be executed in the context of a single explicit transaction (more details in the next sections).

The transaction model may be extended in future versions of FbDb to feature multiple concurrent explicit transactions. Currently, if your application needs multiple explicit transactions, active at the same time (each of which spans over mutliple SQL statements), you need to open multiple concurrent connections to the database.

###  5.2. <a name='Implicittransactions'></a>Implicit transactions
When you execute a query without explicitly starting a transaction, the query is executed in its own transaction (in an **auto commit** mode). The inner transaction of a query is committed:
- for queries run by calling the `execute` method - immediately after query execution,
- for queries run by calling the `openCursor` method - after all rows have been fetched (either by hand, by calling `fetchOneAsMap`, `fetchAsMaps`, `fetchAllAsMaps`, etc., or by using a stream and exhausting it),
- for all kinds of queries - when `close` is called on the query object.

>Please note, that opening a query with `openCursor` and **keeping it open** (not fetching all data rows and not calling `close`) may result in a long running implicit transaction, which in turn can contribute to the garbage record versions accumulating in the database (degrading the database performance and eventually causing the database sweep process to kick in on the server). It is a good practice to open a query and fetch all data from it as soon as possible, caching the data in the client code if needed.

###  5.3. <a name='Explicittransactions'></a>Explicit transactions
Explicit transactions can cover multiple queries (i.e. you can run many subsequent queries in the context of a single transaction and finally either commit or roll back all changes made to the database by those queries).
They neeed to be started manually in code, by calling `startTransaction`, and need to be either committed (by calling `commit`) or rolled back (by calling `rollback`).

If a connection is closed (detached) while an explicit transaction is pending (i.e. it's been started and neither committed nor rolled back), the transaction is automatically rolled back.

For explicit transaction handling, the `FbDb` connection objects publish the following methods related to transactions (all of them are asynchronous and need to be `await`ed):
- `startTransaction()` - starts a new transaction. All SQL statements issued from this moment will be executed in a single transaction context, until either `commit` or `rollback` method is called.
- `commit()` - commits a started transaction.
- `rollback()` - rolls back (cancels) a started transaction.
- `inTransaction()` - informs whether a transaction has been explicitly started and is currently pending (has been neither committed nor rolled back).

If no transaction has been started with `startTransaction`, then `commit` and `rollback` have no effect (but don't throw an exception).

>You need to take extra care with queries run with `openCursor` in the context of an explicit transaction. Ending a transaction (with `commit` or `rollback`) **invalidates** all data sets obtained in the context of that transaction, including any streams based on those data sets. Trying to fetch another row from such data sets (or streams) will result in an exception. 

####  5.3.1. <a name='Utilitymethod:runInTransaction'></a>Utility method: runInTransaction
To cover a common use case scenario, in which:

- one starts a transaction,
- a number of SQL statements get executed in the context of the transaction,
- if all of the statements complete successfully, the transaction is committed, otherwise it is rolled back and an error is reported up the call stack,

*fbdb* offers a utility method `runInTransaction`, which can be called on an attached `FbDb` connection object and passed a **function**, which gets executed in the context of an automatically managed explicit transaction. Moreover, if the custom function completes without errors (without throwin an exception), the transaction is **automatically** committed. If, on the other hand, an exception coming from the custom function gets caught, the transaction is **automatically** rolled back and the exception gets rethrown up the call stack. The custom function can (but doesn't have to) return a value of any type, and it becomes the return value of `runInTransaction`. If no value is returned, `runInTransaction` returns `null`.

Consider the following example:
```dart
    // db is an attached connection
    // assume COUNTRY is an empty table with a primary key on COUNTRY
    final cnt = await db.runInTransaction(() async {
        await db.execute(
            sql: "insert into COUNTRY (COUNTRY, CURRENCY) " 
                 "values (?, ?)",
            parameters: ["Poland", "PLN"],
        );
        await db.execute(
            sql: "insert into COUNTRY (COUNTRY, CURRENCY) " 
                 "values (?, ?)",
            parameters: ["USA", "USD"],
        );
        return 2;
    });
    // cnt == 2
    // COUNTRY contains 2 rows
```

In the example above, an anonymous async function is passed to `runInTransaction`. In the body of the function, two consecutive `INSERT` statements get executed, and the function returns `2` as its result. Before the execution of the anonymous function starts, `runInTransaction` starts a new transaction (it's the same explicit transaction, which would be started by calling `FbDb.startTransaction`). Assuming both statements complete without errors, the transaction is automatically committed when the anonymous function returns. The returned value (`2` in this case) becomes the return value of `runInTransaction`, therefore `2` is assigned to the final variable `cnt`.

Now let us consider another example:
```dart
    // db is an attached connection
    // assume COUNTRY is an empty table with a primary key on COUNTRY
    try {
        final cnt = await db.runInTransaction(() async {
            await db.execute(
                sql: "insert into COUNTRY (COUNTRY, CURRENCY) " 
                    "values (?, ?)",
                parameters: ["Poland", "PLN"],
            );
            await db.execute(
                sql: "insert into COUNTRY (COUNTRY, CURRENCY) " 
                    "values (?, ?)",
                parameters: ["Poland", "USD"],
            ); // primary key violation
            return 2;
        });
    } catch (_) {
        print("Error detected");
    }
    // COUNTRY contains 0 rows
```

This example is similar to the previous one, except that the second `INSERT` statement results in an exception, caused by the primary key violation on table `COUNTRY`. The exception is never caught inside the anonymous function, therefore it is passed up the call stack and detected by `runInTransaction`. The latter automatically rolls the transaction back and rethrows the exception, which is later caught by the `catch` block in the calling code (resulting in the `Error detected` message being printed out). Assuming `COUNTRY` was empty when the code started, it remains empty still, even though the first `INSERT` was successful. The exception occuring inside the anonymous function caused the whole transaction to be rolled back, including the first `INSERT`.

###  5.4. <a name='Transactionflags'></a>Transaction flags
Firebird supports different *transaction modes*, which are determined by a group of flags set in the *transaction parameter block* (TPB). FbDb abstracts away the actual manipulation of the native memory of a TPB, allowing the programmer to easily set the transaction flags.

There are two places, in which the transaction flags can be specified. 

The first one is when a database attachment (connection) is being opened, either by calling `attach()` or `createDatabase()`. You can pass an instance of the `FbOptions` class when opening a database connection. The options object allows you to specify default transaction flags. Those flags will be used each time you call `startTransaction()`, unless otherwise specified.

The second place where transaction flags can be set is the call to `startTransaction()`. This method accepts up to two named parameters:
- `flags` - a set of `FbTrFlag` values,
- `lockTimeout` - when `flags` contain `FbTrFlag.wait`, `lockTimeout` specifies the maximum time (in seconds) the server will wait for conflict resolution before firing a deadlock exception.

There are three global constants in FbDb, allowing you to quickly specify the three most frequently used transaction modes:
- `fbTrWriteWait` - a read/write transaction, waiting for deadlock resolution,
- `fbTrWriteNoWait` - a read/write transaction, not waiting for deadlock resolution,
- `fbTrRead` - a read-only transaction.

You can specify each of the above constants either as a connection default or for a particular transaction, for example:
```dart
await db.startTransaction(
    flags: fbTrWriteWait, 
    lockTimeout: 3,
);
```

Please take a look at `example/fbdb/ex_09_lock_wait.dart` for a demo showing the difference between wait and no-wait transactions.

###  5.5. <a name='Transactions-examples'></a>Transactions - examples

Two updates in a transaction.
```dart
var q = db.query();
await db.startTransaction();
await q.execute(
    sql: "update EMPLOYEE set PHONE_EXT=? "
         "where PHONE_EXT=?",
    parameters: ["220", "22"],
);
await q.execute(
    sql: "update EMPLOYEE set DEPT_NO=? "
         "where DEPT_NO=?",
    parameters: ["180", "130"],
);
await db.commit(); // commits both updates
```

Rolling back changes.
```dart
var q = db.query();
await db.startTransaction();
await q.execute(
    sql: "delete from EMPLOYEE",
);
// oops! changed my mind :)
await db.rollback();
```

You may also be interested in `example/fbdb/ex_03_transactions.dart` and `example/fbdb/ex_09_lock_wait.dart` (the latter shows also how to specify different transaction flags than the connection default ones).

##  6. <a name='Workingwithblobs'></a>Working with blobs
Although *blob* stands for *binary large object*, there are blobs and there are blobs. Not all of them are actually "large" in terms of contemporary computers' memory.

FbDb gives you two ways of dealing with blobs. For blobs of reasonable size, meaning those that can be fit into your process' memory, you can pass and/or obtain binary blob data directly to/from a FbQuery object as byte buffers. For larger blobs (or if the application runs in a memory constrained environment) you can transfer blob data segment by segment (in chunks), using a set of `FbDb` methods and `FbBlobId` identifiers (see below).

###  6.1. <a name='Passingblobsasqueryparameters'></a>Passing blobs as query parameters
When you intend to pass blob data as a value of a query parameter, you can pass either a `String` object (the actual blob will be the string encoded in UTF-8, possibly further converted by the Firebird server to whatever character encoding a particular column uses), a `ByteBuffer` object (in which case the data will be put into the blob without any conversions) or any `TypedData` object (in which case the `buffer` of the object will be used as the source of the blob data and the bytes will be placed inside the blob without any further conversion).
For example:
```dart
await query.execute(
    sql: "insert into BLOBS_TABLE(A_BLOB) values (?)",
    parameters: [blobData]
);
```

If the blobs you are processing are too large to be kept in the process' memory, you can use the alternative API, which allows you to send blobs to the database in chunks.

In order to do so, use the following procedure:

1. Start an explicit transaction (see [Explicit transactions](#Explicittransactions)):
    ```dart
    await db.startTransaction();
    ```
2. Create a new blob in the database and obtain its ID: 
    ```dart
    FbBlobId myBlobId = await db.createBlob();
    ```
3. Send the blob data as byte buffers in a loop:
    ```dart
    await db.putBlobSegment(
        id: myBlobId, 
        data: blobChunkBuffer,
    );
    ```
    or, if the data can be read from a stream, use the stream directly:
    ```dart
    await db.putBlobFromStream(
        id: myBlobId, 
        stream: blobStream,
    );
    ```
4. Close the blob as soon as all data has been sent.
    ```dart
    await db.closeBlob(id: myBlobId);
    ```
    Don't worry, `myBlobId` is still valid after the call to `closeBlob`, and can be passed as a query parameter. Closing the blob just indicates there's no more data to be put inside it.
5. As an alternative, if you wish to load the blob data directly from a file, you can use a utility method:
    ```dart
    await db.blobFromFile(
        id: myBlobId,
        file: File("blob_data.bin"),
    );
    ```
6. When executing a query, pass the blob id as a parameter value:
    ```dart
    await query.execute(
        sql: "insert into BLOBS_TABLE(A_BLOB) values (?)",
        params: [myBlobId]
    );
    ```
    >`FbQuery` will detect the value of a parameter is a blob ID, and not a data buffer, and will process the blob accordingly.
7. Execute additional queries in the transaction context (if needed), and, as soon as there are no more statements to execute, commit the transaction:
    ```dart
    await db.commit();
    ```

###  6.2. <a name='Fetchingblobsfromselectedrows'></a>Fetching blobs from selected rows
Similarly to passing blobs to queries, there are two ways to fetch blobs from query results. The simple way is to request an **inline** blob data, which will be returned in the data row as a `ByteBuffer` object. It's up to you to interpret and process the underlying binary data of the blob. Inline blobs are the default way of getting blob data from queries.

For larger blobs, or if you specifically need to fetch blob data in chunks / segments, or if it is convenient in a particular scenario to store blob data into a file, use the following procedure:

1. Start an explicit transaction:
    ```dart
    await db.startTransaction();
    ```
2. Open a query, setting the `inlineBlobs` parameter to `false` (meaning you don't want to get actual blob data as field values, just blob IDs):
    ```dart
    await query.openCursor(
        sql: "select A_BLOB from BLOBS_TABLE",
        inlineBlobs: false
    );
    ```
3. Process the rows of the result set in any way that's convenient for you (e.g. using the stream of rows). The value of the `A_BLOB` column will be a `FbBlobId` object, which can be used to fetch blob in segments:
    ```dart
    await for (var row in query.rows()) {
        final myBlobId = row['A_BLOB'];
        // fetch blob data - see below
    }
    ```
4. For each obtained `FbBlobId`, open the blob stream. The `segmentSize` parameter indicates the maximum size of the blob segment that will be returned by the stream in a single read (default is 4096 = 4 kB:
    ```dart
    Stream<ByteBuffer> myBlobStream = await db.openBlob(
        id: myBlobId,
        segmentSize: 4096
    );
    ```
5. Retrieve the blob data in segments:
    ```dart
    await for (var segment in myBlobStream) {
        // process the data segment
        // segment is an instance of ByteBuffer
        // it's up to you how you interpret the actual
        // bytes from the buffer
    }
    ```
6. As an alternative, if you wish to write the contents of the blob directly to a file, you can use a utility method:
    ```dart    
    await db.blobToFile(
        id: myBlobId,
        file: File("blob_contents.bin")
    );
    ```
7. There's no need to close the blob - depleting the blob data stream does it automatically for you. However, should you quit the loop reading the stream early, you can (and **should**) explicitly close the blob:
    ```dart
    await db.closeBlob(myBlobId);
    ```
8. End the explicit transaction when no longer needed:
    ```dart
    await db.commit();
    ```

###  6.3. <a name='Examples-blobs'></a>Examples - blobs
For a comprehensive blob processing example, please take a look at `example/fbdb/ex_05_blobs.dart` example code.