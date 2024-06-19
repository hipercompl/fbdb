# FBClient Programmer's Guide

This guide is copyritht © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is copyright © 2024 Tomasz Tyrakowski (t.tyrakowski @at@ hipercom.pl).

*fbdb* is licensed under open source BSD license (see the [LICENSE](https://github.com/hipercompl/fbdb/blob/main/LICENSE) file).

**TABLE OF CONTENTS**

<!-- vscode-markdown-toc -->
* 1. [Introduction](#Introduction)
	* 1.1. [Importing the module](#Importingthemodule)
	* 1.2. [Installing native Firebird client libraries](#InstallingnativeFirebirdclientlibraries)
	* 1.3. [Mixing the low-level and high-level API](#Mixingthelow-levelandhigh-levelAPI)
* 2. [Interfaces](#Interfaces)
	* 2.1. [Blocking calls](#Blockingcalls)
	* 2.2. [Releasing interfaces](#Releasinginterfaces)
* 3. [Obtaining the master interface](#Obtainingthemasterinterface)
* 4. [Interfaces available via the master interface](#Interfacesavailableviathemasterinterface)
	* 4.1. [Status](#Status)
* 5. [Buffers and builders](#Buffersandbuilders)
	* 5.1. [Native memory management](#Nativememorymanagement)
	* 5.2. [Parameter buffers](#Parameterbuffers)
	* 5.3. [Message buffers and metadata](#Messagebuffersandmetadata)
	* 5.4. [Builders](#Builders)
* 6. [Attachments](#Attachments)
* 7. [Transactions](#Transactions)
* 8. [Statements](#Statements)
* 9. [Cursors](#Cursors)
* 10. [Blobs](#Blobs)
* 11. [Error handling and reporting](#Errorhandlingandreporting)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

##  1. <a name='Introduction'></a>Introduction

This document provides an overview of the Dart bindings to *libfbclient*, the actual Firebird RDBMS client library. The Dart/Flutter code should use the low-level API only if fine-grained control over access to Firebird features is required. In all other cases, it is much more convenient to use the high-level and Dart-idiomatic API of *fbdb*. Please refer to [FbDb Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_guide.md) for more details.

From now on, the following naming convention will be used:
- **fbdb** is the name of the library (package), as published on pub.dev - it should be added to the pubspec.yaml of your project as a dependency,
- **FbDb** is the high-level part of the library, and, at the same time, the name of the main class of the high-level API,
- **FbClient** is the low-level part of the library, and, at the same time, the name of the main class of the low-level API.

It is highly recommended to get familiar with the 
["Firebird interfaces"](https://github.com/FirebirdSQL/firebird/blob/master/doc/Using_OO_API.html) 
document from the official Firebird repository. The document describes the basic usage
of the object-oriented API of the Firebird client library. It is bundled together with the Firebird server binaries and should be available in the documentation directory of a Firebird server installation.

For a set of example Dart applications using the low-level API, please refer to
 the [example/interfaces](https://github.com/hipercompl/fbdb/tree/main/example/interfaces) directory. The examples are
basically Dart implementation of the C++ examples, distributed together with the Firebird server
package (see the `examples/interfaces` folder in the 
[official Firebird repository](https://github.com/FirebirdSQL/firebird/tree/master/examples/interfaces)).

>This guide by no means covers all interfaces available in the Firebird client library (the set of available interfaces is quite vast). It covers only the most basic interfaces, which are essential to the interaction with databases.

###  1.1. <a name='Importingthemodule'></a>Importing the module
To get access to the low-level part of the FbDb library, add the following import to your code:
```dart
import "package:fbdb/fbclient.dart";
```

and add the *fbdb* library as your project dependency.

###  1.2. <a name='InstallingnativeFirebirdclientlibraries'></a>Installing native Firebird client libraries
In order for your final application to work, you also need to deploy the official native shared libraries from the Firebird distribution (*fbclient.dll* / *libfbclient.so*).

The procedure for different operating systems is described in the [FbDb Programmer's Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_guide.md) in section 2.2.

###  1.3. <a name='Mixingthelow-levelandhigh-levelAPI'></a>Mixing the low-level and high-level API
As was already mentioned, the *fbdb* library consists of two different APIs:
- FbDb is the high-level, Dart-idiomatic API, intended to be used by the client (application) code,
- FbClient is the low-level API, consisting mainly of Dart bindings to the C++ Firebird client interfaces.

You can use either of them (by importing the appropriate module from the library) and you can even mix them in a single project.

However, since FbDb is designed with asynchrony in mind, the actual interaction with the database takes place in a background isolate. That's where the native Firebird client code gets called. The native memory (and pointers) cannot be transfered between isolates, therefore your main application isolate doesn't (and cannot) have access to the low-level interfaces that are used by the worker (background) isolate.

Therefore, you can mix low-level and high-level APIs, but you cannot access the underlying low-level interfaces of the existing high-level objects, which makes the mixing useful only in some very specific scenarios (e.g. you use the high-level API to interact with the database, while switching to the low-level API to contact the service manager).

##  2. <a name='Interfaces'></a>Interfaces
Interfaces in Firebird client library are language agnostic. Although actually implemented in C++, they don't require the calling code to be compatible with C++ classes, nor to deal with C++ class memory layout (which in itself is not standarized). In Firebird, an interface is just a sequence of **function pointers** (of known and fixed order). The functions (methods) of an interface use the traditional C ABI, and therefore can be called from any programming language that is capable of calling external functions using the C calling convention.

All interfaces in the OO API extend (directly or indirectly) the `IVersioned` interface. Both `IDisposable` and `IReferenceCounted` base interfaces extend `IVersioned`, therefore `IVersioned`'s memory layout implies the inner layout of all interface objects.

The `IVersioned` native interface in libfbclient consists of a dummy `CLOOP` field (a single pointer to be ignored) and a pointer to the **VTable**, which is an array of method pointers. The VTable is the heart of an interface, because it is the only way to access the interface's functionality (its methods).

>This philosophy resembles somewhat the Windows COM model. The COM objects are also language agnostic and are in fact just sets of method (function) pointers, which can be used even from languages which are not object oriented.

A pointer to an interface returned by any libfbclient routine, which is declared as returning an interface object, should be treated (as long as the interface extends `IVersioned`) as an array of two subsequent pointers, from which only the second pointer is actually of any value, as it points to the `VTable` of the interface:

- `((uintptr_t*) IVersioned)[0]` - ignore: `CLOOP` dummy pointer,
- `((uintptr_t*) IVersioned)[1]` - points to the `VTable` of the interface.

Here is the relevant snippet from the `IVersioned` C++ implementation (the header file [include/firebird/IdlFbInterfaces.h](https://github.com/FirebirdSQL/firebird/blob/master/src/include/firebird/IdlFbInterfaces.h) from the Firebird server distribution):

```C++
class IVersioned
{
public:
	struct VTable
	{
		void* cloopDummy[1];
		uintptr_t version;
	};

	void* cloopDummy[1];
	VTable* cloopVTable;
    
    /* ... other members ... */
```

What's important is that the original pointer to the interface has to be retained, because methods of the interface require the **interface pointer** (which starts with the dummy `CLOOP` pointer), and **not** the interface's `VTable` pointer, to be passed as an argument. In other words, we invoke functions, which are pointed to by the entries of the `VTable`, but the functions receive (as their first argument) not the `VTable` as such, but a pointer to the enveloping structure (interface), from which `VTable` can be further obtained as the second pointer counting from the beginning of the interface.

Every interface extending `IVersioned` (which at this moment means literally every interface from libfbclient OO API) is represented in the following way in the Dart code.

Each Dart class wrapping a Firebird interface has the following attrbutes:
- `startIndex` - defines the first index (slot) in the `VTable`, which contains a method of this particular interface (all slots with lower indices contain methods of the ancestor interfaces); this attribute is calculated as `startIndex` + `metodCount` of the parent interface (except of `IVersioned`, for which those are hardcoded constants, because it's the ancestor of all other versioned interfaces and doesn't have its own parent),
- `methodCount` - defines the number of `VTable` slots, which this particular interface occupies. Therefore, if we have an interface hierarchy: `A <- B <- C` (B extends A, and C extends B), their attributes are defined as:
    - `A.startIndex` and `A.methodCount` are constant
    (`A.startIndex` is `0` if `A` is the `IVersioned` interface),
    - `B.startIndex = A.startIndex + A.methodCount`,
    - `B.methodCount` is constant (specific to interface `B` and hardcoded therein),
    - `C.startIndex = B.startIndex + B.methodCount`,
    - `C.methodCount` is constant (specific to interface `C`).

The calculation of `startIndex` in terms of the superclass' attributes and the definition of `methodCount` are both placed in the class
constructor (rather than being static class members). That's because FbClient is designed to support different versions of Firebird interfaces, and in the future, the value of the `methodCount` of an interface may change, and will depend on the version of the interface (which is available only at runtime).

Additionally, each interface defines (overrides) the method `minSupportedVersion`, which returns the minimum required version number of a particular interface, which is supported by FBClient. If a Dart object, created around a native Firebird interface pointer, detects that the native interface has a version lower than the minimum required version (which can mean, that not all methods, which the Dart class constructor will attempt to map, may be present in the interface's VTable), an exception is thrown.

Note, that using an interface with a higher version should be safe (as long as there are no descendant interfaces), the worst that can happen is that some new methods from the VTable won't be available in the Dart wrapper class.

The VTable layout of an example interface (`IMetadataBuilder` version 4, extending `IReferenceCounted`, which extends `IVersioned`) is as folows:

```
offset  value
[0]:    IVersioned.CLOOP dummy pointer (to be ignored)
[1]:    IVersioned.version number (from IVersioned)
[2]:    IReferenceCounted.addRef method pointer
[3]:    IReferenceCounted.release method pointer
[4]:    IMetadataBuilder.setType method pointer
...
[17]:   IMetadataBuilder.setAlias method pointer
```

###  2.1. <a name='Blockingcalls'></a>Blocking calls
It has to be pointed out, that calling methods of the interfaces is **synchronous**, that is, it's **blocking**. In other words, the flow of your application stops until the call is completed and a value is returned. During this time no events are processed by the event queue of the isolate, in which the call was made (which may be the main application isolate). That means the GUI of the application (if it has one) may be frozen for a significant amount of time (imagine an application not responding and not refreshing the GUI while a complex `JOIN` is executed by the remote database server).

That is just a statement of the fact, and needs to be taken into account when making the decision whether to use the low-level, interface based API of *fbdb*.

>The high-level API (FbDb), on the other hand, is fully **asynchronous**, i.e. the calls are not blocking the event queue. It is achieved by using a separate (background) isolate to make the actual Firebird interface calls, thus leaving the event queue of the main isolate free to refresh the GUI and process other events.

>Please note, that marking a function `async` in Dart doesn't make it automagically work in the background in a non-blocking way. The fact that `async` functions often do work in the background is implied by the proper implementation of those functions, and not by the `async` keyword alone.

###  2.2. <a name='Releasinginterfaces'></a>Releasing interfaces

In context of memory management, Firebird client interfaces can be generally divided into two groups, depending on which base interface they extend:
- `IDisposable` - when an interface object is no longer needed, you need to call its `dispose` method to free the interface immediately,
- `IReferenceCounted` - when an interface object is no longer needed, you need to call its `release` method, and the interface will be freed when all pieces of code that obtained a reference to the same interface object will *release* the object as well.

Those two interfaces are independent of each other (neither extends the other).

Releasing an interface doesn't mean it  immediately gets removed from the memory. It just decreases the reference count of this particular instance, and the interface object will be actually removed from memory when its reference count drops to zero. `IReferenceCounted` interfaces can be shared by various contexts, each of which increases the interface's reference count when obtaining the interface object reference, and decreases it by releasing the interface.

Examples of `IReferenceCounted` interfaces:
- `IAttachment`,
- `ITransaction`,
- `IStatement`,
- `IMessageMetadata`,
- `IMetadataBuilder`.

Interfaces extending `IDisposable`, on the other hand, are "private" to a context. When no longer needed, they can be removed from memory by calling the `dispose` method.

Examples of `IDisposable` interfaces:
- `IStatus`,
- `IXpbBuilder`.

>Neglecting to call `dispose` / `release` will result in an interface object being kept in memory until the application ends.

##  3. <a name='Obtainingthemasterinterface'></a>Obtaining the master interface

To start working with the interfaces, you need to instantiate `FbClient` (which loads the actual Firebird client dynamic library) and obtain the **master interface**.

To do so, you simply create an instance of the `FbClient` class:

```dart
client = FbClient();
```

and then store the reference to `IMaster` for future use:

```dart
IMaster master = client.fbGetMasterInterface();
```

##  4. <a name='Interfacesavailableviathemasterinterface'></a>Interfaces available via the master interface

The master interface serves as an entry point to obtain references to other interfaces.

Usually, you will want to get a reference to the `IUtil` interface, because `IUtil` comes handy in many common scenarios:

```dart
IUtil util = master.getUtilInterface();
```

To attach to a database, you also need an instance of `IProvider`, which can also be directly obtained from `IMaster`:

```dart
IProvider prov = master.getDispatcher();
```

The name of the method - `getDispatcher` - follows closely the name used in the Firebird header files. However, in order for the API to be more intuitive, the `IMaster` interface in FbClient package has another method - `getProvider` - which is nothing more than an alias to `getDispatcher`. Therefore, you may as well call:

```dart
IProvider prov = master.getProvider();
```

More information about `IProvider` can be found in the section [Attachments](#Attachments).

Other useful interfaces available via `IMaster` are various buffer **builders** (`IXpbBuilder`, `IMetadataBuilder`), which are described in the section [Buffers and builders](#Buffersandbuilders).

###  4.1. <a name='Status'></a>Status

Most database operations may result in an error. The native Firebird client library encapsulates the status of a finished database operation in an instance of the `IStatus` interface. The `IStatus` contains a vector of status values, and requires checking the contents of the vector after each database operation.

However, FBClient provides a level of indirection in this regard, and checks the status vector automatically after each database operation, which uses the status vector as an error indicator. If errors are detected, an exception will be thrown **automatically**. Therefore, you don't need to check the status vector manually (in an `if` statement), just execute database operations within a `try` block.

Nonetheless, various methods of FbClient interfaces still require an instance of `IStatus` to be passed as a parameter.

To obtain such an instance, simply call
```dart
var status = master.getStatus();
```
where `master` is an instance of `IMaster`. From now on you can pass `status` whenever a status vector is required, an you can **reuse** the same `IStatus` object in subsequent method calls.

Please take a look at the example code in the `examples/fbclient` directory of the FbDb package - the status objects are used in all examples.

See also the [Error handling and reporting](#Errorhandlingandreporting) section towards the end of this document.

##  5. <a name='Buffersandbuilders'></a>Buffers and builders

###  5.1. <a name='Nativememorymanagement'></a>Native memory management
To exchange data with the native Firebird client library, you need some means to move data between *Dart memory* and *native memory*. FBClient internally uses the native memory allocator, available as the package-global `mem` object. By default, this `mem` object points to the `calloc` allocator from the `dart:ffi` package. However, when diagnosing memory leaks, you can override this default, and use for example an instance of the `TracingAllocator`, which counts all allocations and releases of native memory (also by the background worker isolate of FbDb).

To use the tracing allocator, simply reassign the default allocator at the beginning of your code:

```dart
mem = TracingAllocator();
```

After that, you can use `mem.toString()` and `mem.toMap()` methods at any moment to access memory allocation statistics.

See `examples/fbdb/ex_11_mem_benchmark.dart` for some example code showing how to use the tracing allocator.

Regardless of which memory manager is used, to allocate a native memory buffer simply call
```dart
var buf = mem.allocate(byteCount);
```
and to release memory no longer needed, call
```dart
mem.free(buf);
```

>Memory allocated with `mem.allocate()` is not managed by Dart's garbage collector. You need to free it manually via `mem.free()`, otherwise it will keep being allocated until your application ends.

###  5.2. <a name='Parameterbuffers'></a>Parameter buffers

Firebird client library makes use of various *parameter buffers* (PB in short). The most frequently used parameter buffers are:
- DPB - the database parameter buffer, used when opening a database connection,
- TPB - the transaction parameter buffer, used when staring a new transaction.

There are other, less frequently used parameter buffers, for example the SPB (service parameter buffer).

The parameter buffers are just memory blocks with a specific byte layout. Filling them by hand is possible, but tedious. It's much more convenient to use a **parameter buffer builder** (an XPB builder), which exposes methods to add various information to the buffer, and finally returns a ready to use memory block. More on parameter buffer builders in the [Builders](#Builders) section.

###  5.3. <a name='Messagebuffersandmetadata'></a>Message buffers and metadata

To provide additional data to the SQL statement being executed and get the resulting data back, you need to pass **message buffers** to and from Firebird native client methods.

Message buffers, similarly to parameter buffers described earlier, are just memory blocks with specific layout. The layout, however, is defined by the **message metadata**, which are another blocks of memory (with specific layout).

So, in order to access data from the message buffer, first you need access to the corresponding message metadata, otherwise you don't know the layout of data in the message.

The message metadata can be obtained in various ways, depending on the context. Some of the ways are:
- obtaining it from the server, by preparing an SQL statement with `IStatement.preparePrefetchMetadata` flag set (you can then get the input and output message metadata by calling `IStatement.getInputMetadata` and `Istatement.getOutputMetadata`, respectively),
- building it yourself, preferably by using an instance of the `IMetadataBuilder` class (more on metadata builders in the [Builders](#Builders) section).

Having the metadata interface (an instance of `IMessageMetadata`), you can query it for many different parameters of the message buffer. The most important of those are:
- the number of data fields in the buffer (`IMessageMetadata.getCount`),
- the type of each field (`ImessageMetadata.getType`),
- the offset (in bytes) of each data field in the message buffer (`IMessageMetadata.getOffset`),
- the length (in bytes) of each data field (`IMessageMetadata.getLength`),
- the total length (in bytes) of the message (`IMessageMetadata.getMessageLength`).

There is more information you can obtain about each data field in the message buffer (like the character set, field name, subtype, nullability and null indicator offset, etc.). Knowing the data type and byte offset of a data field in an input buffer, you know where to put data and what kind (type) of data is compatible with a particular field. Similarly, you know from which part of the output buffer you can retrieve a piece of data corresponding to a particular data field, and what kind of data it is.

An example of processing messages can be found in the [Messages and builders - examples](#Messagesandbuilders-examples) section. More comprehensive examples can be found in the `examples/interfaces` directory of the *fbdb* library.

###  5.4. <a name='Builders'></a>Builders

It was mentioned before, that the Firebird client contains a ready to use objects, which greatly simplify dealing with buffers of various fixed formats.

>Please note, that builders are in fact part of the Firebird client library, the FBClient package provides only Dart wrappers around them.

To obtain a builder for the DPB (database parameter block), you can use the `IUtil` interface (see [Interfaces available via the master interface](#Interfacesavailableviathemasterinterface) ):
```dart
var util = master.getUtil();
var builder = util.getXpbBuilder(status, IXpbBuilder.dpb);
```
(`status` is an instance of `IStatus` - see the [Status](#Status) section).

You can then use various methods of `builder`, most important of which are:
- `clear` - clear the buffer,
- `insertInt` - put an int into the buffer,
- `insertString` - put a string into the buffer,
- `getBufferLength` - get the size of the resulting buffer,
- `getBuffer` - get the pointer to the actual buffer.

>The buffer returned by `getBuffer` is managed internally by the builder object. It is released when the builder is released - you don't call `mem.free` on buffers obtained from builders via `getBuffer`.

>For complete examples using different kinds of builders, please take a look at the `example/interfaces` folder. Virtually all examples in that folder use various builders, buffers, and messages.

##  6. <a name='Attachments'></a>Attachments
An connection to a database is represented by an instance of the `IAttachment` interface. You can obtain an attachment object in two ways:
- by connecting to an existing database using `IProvider.attachDatabase`,
- by creating a new database using `IProvider.createDatabase`.

Both calls require you to pass a *connection string* and some additional parameters, if required.

The connection string specifies the database and server location. 

The older (legacy) form of the connection string is `host/port:database` (the `port` part can be omitted if it's the default 3050, the `host` part can be omitted to use embedded mode, the `database` part can be iether a path to the database file or an alias name), for example: `localhost:employee`, `some_server/3051:/path/to/database.fdb`, or just `/some/path/database.fdb`.

The modern form of a connection string (available since Firebird 3.0) is `protocol://host:port/database`, where protocol can be either of `INET`, `WNET` or `XNET` (can also be omitted when using embedded mode), and `host`, `port` and `database` are the same as in the legacy form described above (the omission rules also apply), for example `inet://some_server:3051/path/to/database.fdb`.

Apart from the database location, you may also need to provide additional information, like autentication data: a user name and a password (but not only that, you may wish for example to specify the page size and default character set for the database about to be created, or a user role). All additional information is passed to `attachDatabase` and `createDatabase` via a DPB (database parameter block) buffer. The buffer has to adhere to a specific memory layout, that's why it's usually prepared by a builder object, and not filled by hand.

The usual procedure of connecting to a database with a DPB is:
- obtain an instance of the DPB builder:
	```dart
	var builder = util.getXpbBuilder(status, IXpbBuilder.dpb);
	```
- put required data into the DPB via the builder:
	```dart
	builder.insertString(status, FbConsts.isc_dpb_user_name, "SYSDBA");
	builder.insertString(status, FbConsts.isc_dpb_password, "masterkey");
	builder.insertString(status, FbConsts.isc_dpb_lc_ctype, "UTF8");
	```
- use the prepared DPB when connecting:
	```dart
	var prov = master.getDispatcher();
	var att = prov.attachDatabase(
		status, 
		"localhost:employee", 
		builder.getBufferLength(status),
		builder.getBuffer(status)
	);
	builder.dispose(); // frees both the buffer and the builder
	```

>The calling code is not supposed to free the memory returned by `IXpbBuilder.getBuffer` manually (via `mem.free`). Instead, call `dispose` on the builder instance when no longer needed, and it will release both the builder and the buffer (which gets allocated and freed internally by the builder). To prepare another DPB buffer, simply obtain another instance of the builder.

>It is generally a good idea to specify the connection character set (the parameter of the DPB tagged by `FbConsts.isc_dpb_lc_ctype`) as "UTF8". Dart can easily encode / decode UTF8 strings, but using other encodings would probably require some third party libraries.

When the interaction with the database is done, the client code should close the connection (attachment). There are two calls that close the connection:
- `IAttachment.detach` - closes the connection and leaves the database as is (that's the most common way of ending the connection),
- `IAttachment.dropDatabase` - deletes the database and closes the connection at the same time.

>Please note, that `dropDatabase` **physically removes** the database file from the file system. 

##  7. <a name='Transactions'></a>Transactions
Not digging too deep into the theory and role of transactions in a database system, we can shortly summarize, that each SQL statement is executed in a context of an active **transaction**. A transaction may cover just a single statement, or any sequence of them. The changes the statements make to the database may be either **committed** at the end of the transaction, or **rolled back**. The client code decides whether to commit a transaction or roll it back (cancel it).

In Firebird client code, a transaction is represented by an instance of the `ITransaction` interface. To obtain such instance, the client code needs to **start** a transaction by calling the `IAttachment.startTransaction` method:
```dart
var t = attachment.startTransaction(status);
```
Committing or rolling back a transaction requires calling the appropriate method of `ITransaction`: `commit` or `rollback`. After calling either of those methods, the transaction ends and the transaction object is no longer valid.

>You can also call `commitRetaining` and `rollbackRetaining`, which will commit / rollback the statements executed so far within a transaction, and keep the transaction open. However, that's usually unhealthy for the database, as it may lead to long-running transactions, which in turn cause piling up of garbage record versions.

Firebird supports multiple transaction **flags**, which determine the behavior of a transaction, its isolation from changes made by other concurrent transactions, and locking of data to prevent it from being accessed by other transactions. For a detailed description of the flags please refer to the Firebird server manual.

To set the transaction flags, the client code needs to prepare a TPB (transaction parameter buffer) and pass it to `startTransaction`.

The default transaction flags (if not specified otherwise) are: `isc_tpb_concurrency`, `isc_tpb_write`, `isc_tpb_wait`. These flags will be used if you omit the TPB when calling `startTransaction`.

As you have probably guessed, the easiest way to create a TPB is to use a builder.

For example, to start a read-write transaction, which doesn't wait for lock conflicts to be resolved, but instead throws an error when such a conflict occurs, you may prepare and use a TPB in the following way:
```dart
// util is an instance of IUtil
var b = util.getXpbBuilder(status, IXpbBuilder.tpb);
b.insertTag(status, FbConsts.isc_tpb_concurrency);
b.insertTag(status, FbConsts.isc_tpb_write);
b.insertTag(status, FbConsts.isc_tpb_no_wait);
// att is an active attachment 
// (an instance of IAttachment)
var t = att.startTransaction(
	status, 
	b.getBufferLength(status),
	b.getBuffer(status),
);
// ... you can use t here ...
t.commit(status);
// t is invalid after this point
```

>When you call `commit` or `rollback`, you don't have to release the transaction object separately. In other cases, you need to call its `release` method to free the interface instance.

>When you disconnect from a database, any still pending transactions are automatically rolled back.

##  8. <a name='Statements'></a>Statements
The Firebird client library provides several ways of executing SQL statements.

In this guide we focus on one of them, which requires *preparing* the statement first, and executing it in a separate step (at any later point). It is also possible to execue a statement directly via `IAttachment`, without the actual statement object (please refer to the aforementioned ["Firebird interfaces"](https://github.com/FirebirdSQL/firebird/blob/master/doc/Using_OO_API.html) document for more information about this way of executing statements).

The SQL statements, prepared and ready to be executed by the database engine, are represented in the client code as instances of the `IStatement` interface.

To prepare a statement, you need an `IAttachment` instance, together with an active `ITransaction` object:
```dart
tra = att.startTransaction(status);
stmt = att.prepare(
	status,
	tra,
	"update EMPLOYEE set SALARY = SALARY * 1.1",
	FbConsts.sqlDialectCurrent,
	IStatement.preparePrefetchMetadata
);
```
When calling `prepare`, you need to provide at least the following arguments:
- an `IStatus` instance for error detection,
- an `ITransaction` instance,
- the SQL text of the statement.

Optionally, you can specify the SQL dialect to be used, and pass another very useful flag: `IStatement.preparePrefetchMetadata`. Doing so causes the server to send back some additional information about the required query parameters and the structure of query results.

Prefetching the metadata is not required, you may build the message metadata by hand (using a builder of course), but prefetching is a very convenient feature and saves some coding (at the cost of more data being exchanged between the client code and Firebird server).

When the metadata is prefetched, you can access it by calling:
```dart
var im = stmt.getInputMetadata(status);
```
and
```dart
var om = stmt.getOutputMetadata(status);
```
Both calls return an instance of the `IMessageMetadata` interface, which helps in allocating memory buffers and accessing the actual data being processed by the query.

The most important methods of `IMessageMetadata` are described in the [Message buffers and metadata](#Messagebuffersandmetadata) section.

When the size of the input or output message is known (from the metadata), the message buffer (in the native memory) has to be allocated:
```dart
var meta = stmt.getInputMetadata(status);
final msgLen = meta.getMessageLength(status);
var msg = mem.allocate(msgLen);
```
and freed when no longer needed:
```dart
mem.free(msg);
```
To put some data into an input message buffer, you need to know the number of slots (query parameters) in the buffer, together with the type and byte offset of each parameter. This information can be obtained from the metadata:
- `getCount(status)` - returns the number of query parameters (message slots),
- `getType(status, index)` - returns the type code of a particular parameter,
- `getOffset(status, index)` - returns the byte offset of a parameter in the message buffer.

The client code needs to handle SQL `NULL` values in a special way. To set a parameter to `NULL`, you need to obtain a special *null offset* of the parameter:
- `getNullOffset(status, index)`

and then set a 16-bit integer value at this offset: `1` for null, and `0` for not null.

Storing data in the message buffer requires usually some pointer arithmetic and casting, possibly with data conversion in between.

As an example, consider an input buffer, which contains three parameters:
- an integer, which is supposed to be `NULL`,
- a varchar, which is supposed to contain the string `Firebird`,
- another integer, with the value 3050.

The code preparing such a message might look like this:
```dart
// stmt is a prepared statement
var m = stmt.getInputMetadata(status);
var len = stmt.getMessageLength(status);
var msg = mem.allocate(len);

// set the parameter at index 0 to null
msg.writeInt16(m.getNullOffset(status, 0), 1);

// store a VARCHAR in the parameter 1
msg.writeVarchar(
	m.getOffset(status, 1),
	"Firebird"
);

// store 3050 in the parameter 2
msg.writeInt32(m.getOffset(status, 2), 3050);

// ...
// execute the statement here
// ...

mem.free(msg);
m.release();
```

The utility methods `writeInt16`, `writeVarchar`, `writeInt32` (and many other methods for other data types) are **extension methods** on the type `Pointer<Uint8>`, implemented by the *fbdb* library. Were it not for these methods, instead of `writeVarchar`, you'd need to store the length of the string in the first 16 bits of the parameter slot, and the bytes representing the actual characters at subsequent addresses.

The input messages make sense for **parametrized** queries, that is SQL statements containing `?` placeholders. For example, a statement `select * from EMPLOYEE` does not require an input message at all, while `select * from EMPLOYEE where EMP_NO=?` does.

For the output messages (the messages containing the data returned by a query), the scheme is similar. You call `getMessageLength` from the output metadata object, allocate a buffer large enough to accomodate output data, then retrieve a row (a message) from the server (see the next section) and get data from the message.

To access the data in an output message, you need to know the byte offsets of individual fields (you can obtain them via metadata's `getOffset` and `getNullOffset` methods), and then use the utility methods (`readInt16`, `readInt32`, `readVarchar`, etc.) to retrieve the data from the message buffer.

Consider the previous example, but with an output buffer instead. That is, we want to read an integer (which happens to be null), a varchar and another integer:
```dart
// stmt is a prepared and executed statement
var m = stmt.getOutputMetadata(status);
var len = stmt.getMessageLength(status);
var msg = mem.allocate(len);

// field at index 0
if (msg.readInt16(m.getNullOffset(status, 0)) == 1) {
	print("NULL");
} else {
	final v = msg.readInt32(m.getOffset(status, 0));
	print(v);
}

// field at index 1
String s = msg.readVarchar(m.getOffset(status, 1));
print(s);

// field at index 2
int i = msg.readInt32(m.getOffset(status, 2));
print(i);

// clean up
mem.free(msg);
m.release();
```

Of course, we might as well have checked the other values in the message for being `NULL`, not just the first one, which was omitted for brevity.

To actually **execute** a statement, you need to call one of two methods of the `IAttachment` interface: `execute` or `openCursor`. Which one to call depends on te kind of query (the actual SQL statement) to be executed:
- for queries not returning any data back (e.g. `UPDATE`, `DELETE`, `CREATE`, etc.), or returning data via output parameters (like `EXECUTE PROCEDURE` when the procedure returns values via its output parameters), use `execute`,
- for queries, which are supposed to return a set of **rows** (records), i.e. `SELECT` statements, as well as some forms of `EXECUTE BLOCK`, or even `UPDATE` or `DELETE` with the `RETURNING` clause, use `openCursor`.

When you call `execute`, after the call returns you can extract the data from the output message (you have to allocate the message buffer first, and pass it to `execute`):
```dart
// stmt is a prepared statement, tra is an active transaction
var m = stmt.getOutputMetadata();
var l = m.getMessageLength();
var om = mem.allocate(l);
stmt.execute(
	status, 
	tra, 
	0,    // no input message
	null, // no input message
	l,    // output message size
	om,   // output message buffer
);

// now use the metadata information to extract the actual
// data from the output message om

// finally free the output message buffer
mem.free(om);
```

The syntax of calling `openCursor` is similar (you can provide input and/or output message buffers, but an output buffer is usually provided while fetching individual rows of the result - see below):
```dart
// stmt is a prepared SELECT statement, tra is an active transaction
var m = stmt.getOutputMetadata();
var l = m.getMessageLength();
var cur = stmt.openCursor(
	status, 
	tra, 
	0,    // no input message
	null, // no input message
	// no output message at the moment
	0,    // output message size
	null, // output message buffer
	0,    // cursor flags
);

// cur is an instance of IResultSet
```

`openCursor` returns an instance of the `IResultSet` interface. Handling result sets is described in the [Cursors](#Cursors) section below.

The last argument to `openCursor` - the cursor flags - is usually 0, but in some cases you may want to request special behavior of the cursor (for example `IStatement.cursorTypeScrollable` flag requests a bi-directional cursor).

##  9. <a name='Cursors'></a>Cursors
A call to `IStatement.openCursor` returns an instance of the `IResultSet` interface. The `IResultSet` is the client code representation of a *database cursor*, created and being kept active by the database server. The cursor is associated with the results of a particular SQL statement.

To access the rows constituting the result of the SQL statement, the client code should iterate over the `IResultSet` instance (calling its `fetchNext` method) until there are no more rows tp fetch, and for each obtained row, retrieve the data from the message buffer.

The general scheme looks as follows:
```dart
// cur is the result of openCursor
// msg is the allocated message buffer
while (cur.fetchNext(status, msg) == IStatus.resultOK) {
	// decode and process data from msg
	// with the help of the output message metadata
}
```

Usually you call `fetchNext`, as long as it returns `IStatus.resultOK`, meaning that another row has been successfully fetched from the database. The `IResultSet` exposes other methods to traverse the set of rows (`fetchPrior`, `fetchFirst`, `fetchLast`, `fetchRelative`, `isBof`, `isEof`), but most of them requires a bi-directional cursor (see the flags passed to `openCursor`), which may or may not be available, depending on the Firebird version.

In summary, the `while fetchNext` scheme is the most common way to process all rows of the result set sequentially (of course you can break out of the loop at any time if there's no need to process all rows).

After iterating over all rows, the client code should call `close` on the `IResultSet` instance, which releases both the server-side cursor resources and the client-side `IResultSet` instance.

>Calling `close` on `IResultSet` automatically decreases its reference count (the client code should not call `release` on a closed cursor).

##  10. <a name='Blobs'></a>Blobs
A BLOB (*B*inary *L*arge *Ob*ject) is a piece of data, that is usually too large to fit into a scalar column of a database table. Blobs may contain large amount of text or binary data (e.g. images, sound, movies). Since the size of a blob can be so large as to exceed the available process memory, handling blobs requires special techniques.

First, we are going to analyze, how to send binary data to the database. Assume you wish to put some blob data into a table via a parametrized `INSERT` or `UPDATE` query. If the data was a scalar, it would be written directly into an input message, as decribed in the [Statements](#Statements) section. However, as was mentioned before, putting a whole blob as a single memory block is not (in general) a feasible solution, due to the sheer volume of data. Therefore, we need to send the data to the server in chunks, called **segments**.

To do so, first we need to **create** an empty blob in the database, and get both its **ID** (which is just a number) and an instance of the `IBlob` interface. The blob ID is a value of type `IscQuad`, and what the client code is dealing with, are actually pointers to such IDs, that is: values of type `Pointer<IscQuad>`.

To create a new, initially empty blob, you call `createBlob` on an attachment object, in scope of an active transaction:
```dart
// att is an instance of IAttachment
// tra is an instance of ITransaction
// bId is an allocated buffer capable of storing IscQuad,
// allocated for example like this:
Pointer<IscQuad> bId = mem.allocate(sizeOf<IscQuad>());

// now we can ask the server to create a blob:
IBlob blob = att.createBlob(status, tra, bId);
```

When the blob is created, you can send data chunks (segments) to the blob by repeatedly calling: 
```dart
// len is the buffer size in bytes
// buffer is a memory buffer containing a blob segment
blob.putSegment(status, len, buffer);
```

When all data has been sent, close the blob:
```dart
blob.close(status);
// blob object cannot be used after this point
```

Yes, you **do** close the `IBlob` interface instance before actually executing a query involving the blob. However, apart from the `IBlob` instance, we also have the blob **ID**, obtained from `createBlob`. That ID value is what we actually pass as a query parameter, putting it into the input message buffer, at the offset reported by the message metadata. The code for the last step might look like this:
```dart
// meta is the input message metadata
// paramIndex is the index of the blob parameter
// in the input message
msg.fromNativemem(
	bId, // source pointer
	sizeOf<IscQuad>(), // byte count
	0, // source offset
	meta.getOffset(status, paramIndex), // offset within msg
);
```
The `fromNativeMem` method is an extension method, defined by *fbdb* on the `Pointer<Uint8>` type. It copies a block of native memory from another native buffer (and our blob ID is a native pointer to an `IscQuad` value).

To show how to fetch blob data from the database, suppose we've just executed a `SELECT` query and one of the selected columns is a blob (assume it's the column with the index `3`). We have opened a cursor, and fetched a row, the row data (message) being the `msg` buffer, while the message metadata is in the `meta` object.

To fetch the blob data from the database, first we need to **open** the blob:
```dart
// att is an instance of IAttachment
// tra is an instance of ITransaction
IBlob blob = att.openBlob(
	att,
	tra,
	// a pointer to the blob ID (IscQuad)
	// the blob ID is a part of the message
	// the number 3 in getOffset is the blob column index
	(msg + meta.getOffset(status, 3)).cast(), 
);
```

>The pointer arithmetic `(msg + offset).cast()` is possible due to extension methods defined by *fbdb* on the `Pointer<Uint8>` type. It is not a standard Dart feature.

Once the blob is open, and an instance of `IBlob` is obtained, it is possible to retrieve the blob data from the database in chunks. To fetch the complete blob data, code similar to this one can be used:
```dart
// len will contain the number of bytes actually fetched
Pointer<UnsignedInt> len = mem.allocate(sizeOf<UnsignedInt>());
const segSize = 128; // segment size in bytes
// the segment data
Pointer<Uint8> seg = mem.allocate(segSize);
for (;;) {
	final rc = blob.getSegment(
		status,
		segSize, // the buffer size
		seg, // the buffer
		len, // this is an output parameter
	);
	if (![IStatus.resultOK, IStatus.resultSegment].contains(rc)) {
		// status other than resultOK or resultSegment
		// means there is no more data to be fetched
		break;
	}
	// process the segment data from seg here
	// len contains the number of bytes fetched
	// and placed in seg
}
// cleanup code
mem.free(seg);
mem.free(len);
```

When the blob is no longer needed, you should close it:
```dart
blob.close();
// don't call release / dispose after close
```

A more comprehensive example regarding blobs can be found in `example/interfaces/ex_07_blob.dart` in the *fbdb* repository.

##  11. <a name='Errorhandlingandreporting'></a>Error handling and reporting
Traditionally, Firebird has reported errors via a **status vector**. The status vector is just a collection (an array, to be precise) of integer numbers, each of which represents an error code.

Therefore, most of the methods of Firebird interfaces require an instance of the `IStatus` interface (which encapsulates the status vector) to be passed as an argument and they set the entries of the vector if an error occurs during a method call.

FBClient adds one more layer of abstraction. After each call of the native implementation of a method, the FbClient library code checks the `IStatus` for errors, and if any occur, an exception is thrown **automatically**. The exception being thrown in such case is `FbStatusException`, and it contains the instance of `IStatus` (with error codes) inside.

First of all, the client code should obtain an instance of `IStatus` and dispose of it when no longer needed:
```dart
var client = FbClient();
var master = client.fbGetMasterInterface();
var status = master.getStatus();

// call Firebird interface methods passing status
// as an argument

// when status is no longer needed, dispose of it
status.dispose();
```

When you call methods of Firebird interfaces, catch any `FbStatusException` errors:
```dart
try {
	cur.fetchNext(status);
} on FbStatusException catch (e) {
	// util is an instance of IUtil
	// obtained via master.getUtil

	// show the error message
	final msg = util.formattedStatus(e.status);
	print("Server error: $msg");
}
```

The `status` attribute of `FbStatusException` contains an instance of `IStatus` with the error codes (it's the same instance that was passed to the method call that caused the error). From the `IStatus`, you can access the actual error codes using the `errors` property (which is a `List<int>`), but it is probably more convenient to prepare and display a human readable error message instead. To do so, you need an instance of `IUtil` (which can be obtained directly from the master interface - see [Interfaces available via the master interface](#Interfacesavailableviathemasterinterface)), and call its `formattedStatus` method, passing the `status` attribute of the exception as an argument. The return value of `formattedStatus` is a string describing the error.

>Encapsulating an `IStatus` instance inside `FbStatusException` neither increases nor decreases the reference count of the interface. Make sure your `IStatus` lives long enough for the `FbStatusException.status` reference to be used safely. Don't call `dispose` on the status object while there still are unhandled exceptions containing it inside.
