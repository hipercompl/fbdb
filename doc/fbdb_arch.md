# FbDb Architecture Overview

This document is copyritht © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is copyright © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is licensed under open source BSD license (see the [LICENSE](https://github.com/hipercompl/fbdb/blob/main/LICENSE) file).

**TABLE OF CONTENTS**

<!-- vscode-markdown-toc -->
* 1. [Low-level and high-level API](#Low-levelandhigh-levelAPI)
	* 1.1. [Firebird interfaces](#Firebirdinterfaces)
	* 1.2. [FbClient: interface wrappers](#FbClient:interfacewrappers)
	* 1.3. [FbDb: high-level abstractions](#FbDb:high-levelabstractions)
* 2. [Asynchronous database access](#Asynchronousdatabaseaccess)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


##  1. <a name='Low-levelandhigh-levelAPI'></a>Low-level and high-level API

The *fbdb* package is in fact a conglomerate of two complementary programming APIs. One of them (*FBClient*) is a low-level set of classes, directly interfacing with the native Firebird client library (the *libfbclient* dynamic library, which is a part of the Firebird distribution). This API is intended to be used only when some very specific Firebird features are required in an application, and they are not supported by the high-level API (for example, at the moment FbDb doesn't support interaction with the service manager; in order to do so, you'd need to use the FbClient classes directly). The alternative, on the other hand, is a high-level API (*FbDb*), wrapping Firebird concepts (attachments, transactions, statements, buffers, metadata, etc.) with Dart idioms (classes, methods, streams, futures).

To use the high-level FbDb API, import the package in the following way:
```dart
import "package:fbdb/fbdb.dart";
```

To use the low-level FbClient classes, import:
```dart
import "package:fbdb/fbclient.dart";
```

You can use either of them (by importing the appropriate module from the library), and you can even mix them in a single project.

From now on, the following naming convention will be used:
- **fbdb** is the name of the library (package), as published on pub.dev - it should be added to the pubspec.yaml of your project as a dependency,
- **FbDb** is the high-level part of the library, and, at the same time, the name of the main class of the high-level API,
- **FbClient** is the low-level part of the library, and, at the same time, the name of the main class of the low-level API.

Since FbDb (the high-level API) is designed with asynchrony in mind, the actual interaction with the database takes place in a background isolate. That's where the native Firebird client code gets called. The native memory (and pointers) cannot be transfered between isolates, therefore your main application isolate doesn't (and cannot) have access to the low-level interfaces that are used by the worker (background) isolate.

Therefore, you can mix low-level and high-level APIs, but you cannot access the underlying low-level interfaces of the existing high-level objects, which makes the mixing of APIs useful only in some very specific scenarios (e.g. you use the high-level API to interact with the database, but switch to the low-level API to contact the service manager). In all other cases it's best to decide up front whether to use the high-level API (recommended), or the low-level one.


###  1.1. <a name='Firebirdinterfaces'></a>Firebird interfaces

Starting with version 3.0, Firebird offers a new client API to access database features. Apart from the traditional set of functions (the `isc_*` functions, designed back in the Interbase days), the client library offers a set of *interfaces* encapsulating database concepts.

Although the interfaces are composed in a class-like hierarchy, their construction is fairly generic and is not tied to any particular programming language. Despite being implemented in C++, they are not C++ classes strictly speaking, but rather collections of plain C function pointers, and therefore can be accessed via a standard C ABI.

FbDb takes advantage of this fact and interacts with the native Firebird client interfaces via FFI (Foreign Function Interface). Please refer to the [C interop using dart:ffi](https://dart.dev/interop/c-interop) article on dart.dev for more information about FFI.

###  1.2. <a name='FbClient:interfacewrappers'></a>FbClient: interface wrappers

The FbClient part of the *fbdb* package wraps native Firebird client interfaces with Dart classes.

Not all available Firebird interfaces are currently supported, but the set of supported interfaces will be extended in the future releases, eventually covering all interfaces available in the Firebird client library.

The native Firebird interfaces are in fact collections containing function pointers placed next to each other. Those function pointers are extracted from the client library by the constructors of the Dart wrapper classes and mapped to Dart functions via FFI. For convenience, pure Dart methods are implemented in the wrapping classes (operating on Dart types), which, when called, delegate the execution to the native implementations.

This sequence of calls is illustrated by the example below:
```
   provider = master.getDispatcher()
                          |
.-------------------------'
|
|
|  +-master (IMaster)--------+
|  |                         |
|  | _getDispatcher ----------------.
|  |         ^               |      |
|  |         |               |      |
|  |         `------------.  |      |
|  |                      |  |      |
`--->getDispatcher()      |  |      |
   |   _getDispatcher() --'  |      |
   |                         |      |
   +-------------------------+      |
                                   FFI
           Dart code                |
----------------------------------- |
     native libfbclient code        |
                                    |
   +-IMaster-----------------+      |
   | +-VTable--------------+ |      |
   | |                     | |      |
   | | * version           | |      |
   | |                     | |      |
   | | * getDispatcher() <----------'
   | +---------------------+ |
   +-------------------------+
```

The instance of the Dart `IMaster` class keeps pointers to all functions from the native `IMaster` interface's VTable (method table). 

> As a side note, the C++ header file of the Firebird distribution (`IdlFbInterfaces.h`) defines `IMaster` to be a C++ class with `VTable` as its static member. However, the **actual** `IMaster` interface (as a Firebird concept) is the `VTable` (a sequence of function pointers in a known order), while the `IMaster` class is just a C++-specific wrapper around the `VTable` (interface). The Dart implementation of `IMaster` interacts only with function pointers from the `VTable`, completely disregarding the fact, that the `VTable` may (or may not) be a member of a C++ language construct.

Calling `master.getDispatcher()` executes the Dart implementation of the method. The implementation, in turn, calls the native function (via a function pointer kept in the private member `_getDispatcher`), dealing with all data conversions between Dart types and native types, allocating native memory buffers (if necessary), converting Unicode strings to and from UTF-8, etc. All those implementation details are being dealt with by the Dart wrapper methods.

> Some methods require native memory buffers to be passed as parameters. Those can be allocated with `mem.allocate()` and released with `mem.free()`.

To work with the low-level FbClient API, you need to understand Firebird interfaces and how they interact with each other. FbClient provides only Dart-side wrappers for them, together with some basic data marshalling, but you still need to have some knowledge about how the interfaces work together.
 
Please refer to [Using OO API](https://github.com/FirebirdSQL/firebird/blob/master/doc/Using_OO_API.html) document from the official Firebird distribution for more information on that subject.

You may also be interested in exploring some demo code from the `example/interfaces` directory of the *fbdb* package.

###  1.3. <a name='FbDb:high-levelabstractions'></a>FbDb: high-level abstractions
Although it's perfectly feasible to implement the interaction with a Firebird database using just the FbClient's low-level classes, this approach has three main disadvantages:

1. It requires a lot of boilerplate code and frequent dealing with FFI types and native memory management.
2. The code written this way doesn't have the Dart "feel" to it (doesn't take advantage of intrinsic Dart constructs, like streams or futures). It looks more like C++ code, machine-translated to Dart.
3. The native calls to Firebird interfaces are always **synchronous**, i.e. they block the event loop until the call completes. For database operations, this can take a significant amout of time, leaving the application unresponsive in the meantime. Especially for GUI applications (Flutter), that's a very undesirable property.

Therefore, apart from the low-lever FbClient API, the *fbdb* library offers also a high-level, Dart-idiomatic and **fully asynchronous** FbDb API, wchich covers:
* database operations (attaching, detaching, creating, dropping), 
* transactions (starting, committing, rolling back), 
* executing SQL queries (including parametrized ones) and fetching their results (in form of streams, lists of rows or individual rows),
* BLOB handling (storing and retrieving).

FbDb addresses the issues mentioned earlier in the following way:
1. The boilerplate code is minimal, in par with database interaction code in other languages.
2. The code takes advantage of futures and streams, encapsulating data transfer and time consuming operations with Dart-idiomatic constructs.
3. Due to automatically spawned worker isolates (see the next section), all calls in FbDb are **asynchronous** (non-blocking), therefore the main event loop is free to process other events (like GUI refreshes) while waiting for the results of a database operation.

##  2. <a name='Asynchronousdatabaseaccess'></a>Asynchronous database access

Every time a new connection to a database is made (either by calling `FbDb.attach` or `FbDb.createDatabase`), a new worker *isolate* is spawned by FbDb.

An *isolate* in Dart is something in between a separate process and a separate thread. In a way it behaves like another process, because it doesn't share memory with other isolates. On the other hand, it's much more lightweight than a fully fledged parallel process, being more similar to a thread in this regard. For more information about isolates, please refer to the [Isolates](https://dart.dev/language/isolates) article at dart.dev.

FbDb automatically spawns a separate isolate for each active connection in your application:

```
+-------------main isolate-------------+
| +-------------+      +-------------+ |
| | connection1 |      | connection2 | |
| +----- ^ -----+      +----- ^ -----+ |
+------- | ------------------ | -------+
         |                    |
+------- | -------+  +------- | -------+
| +----- v -----+ |  | +----- v -----+ |
| |   worker1   | |  | |   worker2   | |
| +-------------+ |  | +-------------+ |
+----isolate 1----+  +----isolate 2----+
```

The worker isolate is automatically terminated when a database connection is closed (by calling either `detach` or `dropDatabase` on an active connection).

When you create a new *query* object (an instance of `FbQuery`) associated with a particular database connection, a corresponding *worker query* object is created in the worker isolate of that connection:
```
+-------------main isolate--------------+
| +-------------+      +--------------+ |
| | connection1 |<-----|    query1    | |
| +----- ^ -----+      +----- ^ ------+ |
+------- | ------------------ | --------+
         |                    |
+------- | ------------------ | --------+
| +----- v -----+      +----- v ------+ |
| |   worker1   |<-----| worker query | |
| +-------------+      +--------------+ |
+------------worker isolate-------------+
```

In a way, the object tree of the worker isolate mirrors that of the connection and queries in the main isolate. All queries associated with a particular connection share a common worker isolate, spawned when the connection has been opened.

Now the key point: every database request, which is performed in the main application isolate, either by calling a method of an `FbDb` instance or a `FbQuery` instance, is forwarded (by a `SendPort` - `ReceivePort` pair connecting the main and worker isolates) to its counterpart in the worker isolate. Then, the main isolate **asynchronously** waits for a response from the worker isolate, allowing the event loop to process other events in the meantime. The objects in the worker isolate call the actual databse routines (from FbClient interface objects) **synchronously** (i.e. blocking until they complete), but that only blocks the worker isolate, not the main one.

However, should the main isolate execute another database operation (via the same attachment) before the previous one completes, it would be handled **after** the already pending one is finished. That would still **not** block the event loop in the main isolate, though.
