## 1.0.2

- Fixed a bug related to issue [#3](https://github.com/hipercompl/fbdb/issues/3). The bug manifested itself when an error was reported by Firebird, but the actual error message could not be obtained by `IUtil` due to a malformed UTF-8 string (so there was an error while handling another error).

## 1.0.1

- Completed API documentation.

## 1.0.0

- The first published version.
