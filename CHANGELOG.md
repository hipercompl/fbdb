## 1.1.0

- Added comatibility with the Firebird client libraries version 3.x (versions older than 3.0 don't work and **will not** work, as they don't expose interfaces-based API to the client code). Please note, that some functionality of the API, introduced in later versions of Firebird, will not be available when using client libraries from the previous versions (e.g. dec16, dec34 and time zones aren't supported when using client libraries from version 3). The appropriate Dart wrappers over native Firebird interfaces now use conditional method binding, throwing `UnimplementedError` when being invoked with an incompatible version of the client library. As a rule of thumb, it's always best to use the most recent officially available Firebird client library with *fbdb*.

- Verified compatibility with the Firebird libraries version 5.x in all currently supported Firebird client interfaces.

## 1.0.2

- Fixed a bug related to issue [#3](https://github.com/hipercompl/fbdb/issues/3). The bug manifested itself when an error was reported by Firebird, but the actual error message could not be obtained by `IUtil` due to a malformed UTF-8 string (so there was an error while handling another error).

## 1.0.1

- Completed API documentation.

## 1.0.0

- The first published version.
