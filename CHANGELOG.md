## 1.3.4

- No actual code changes. Version bumped to force re-analysis of the package at pub.dev (code analysis of 1.3.3 at pub.dev broke, resulting in "platforms unknown" and incomplete README at the landing page).

## 1.3.3

- Fixed a bug that sometimes prevented Firebird error messages from being passed from the worker isolate to the main isolate (which resulted in an `FbServerException` without the actual error message getting caught in the main isolate).

## 1.3.2

- Added an example showing how to use prepared queries and what efficiency gain they may give you in some scenarios. See [`examples/fbdb/ex_12_prepared_statements.dart`](https://github.com/hipercompl/fbdb/blob/main/example/fbdb/ex_12_prepared_statements.dart).

## 1.3.1

- Added a more robust implementation of the fix to issue [#7](https://github.com/hipercompl/fbdb/issues/7), based on runes rather than simple string length. Truncating a string in Dart to the given length truncates in fact UTF-16 code points, and not characters, which may result in too many actual characters being truncated (when the character codes exceed `0xFFFF` and require two UTF-16 code points to encode a single character). Added specific test cases for selecting such character combinations as `CHAR(N)` values.

## 1.3.0

- Implemented prepared statements. Now you can prepare a query once, and then execute it multiple times, with different values passed as parameters each time (see section 4.6 of the [FbDb Programmers Guide](https://github.com/hipercompl/fbdb/blob/main/doc/fbdb_guide.md) for more details and an example).

## 1.2.2

- A better solution to issue [#7](https://github.com/hipercompl/fbdb/issues/7) was implemented, taking into account the actual encoding of a particular text value returned as `CHAR(N)` by a query, and truncating the value only if the character set is other than `NONE`, `ASCII` or `OCTETS`. In case of those three no truncation is necessary (truncating might actually remove intentional spaces from the end of the text).

## 1.2.1

- Fixed issue [#7](https://github.com/hipercompl/fbdb/issues/7), which is a regression caused by a way issue [#5](https://github.com/hipercompl/fbdb/issues/5) was fixed. While truncating the returned text in a `CHAR` field to the reported byte length divided by 4 (maximum 4 bytes per Unicode character in UTF-8 encoding) works fine for databases encoded in UTF-8, it doesn't work for databases with character set `NONE`, `ASCII` or `OCTETS`. In this release, the truncating is restricted to trailing spaces only.

## 1.2.0

- Implemented `FbDb.execute` and `FbDb.runInTransaction` utility methods. Together with `FbDb.selectOne` and `FbDb.selectAll` they cover all common scenarios, allowing to interact with databases without explicit creation of query objects and handling transactions by hand.
- Fixed a subtle bug, causing an exception thrown by a failing query to be repeated as a result of the next query (even if the next query was in fact executed successfully), but only if both queries were executed in a single explicit transaction. The bug was not reported as a GitHub issue, it manifested itself by accident in some test code for the new `FbDb.runInTransaction` method.

## 1.1.3

- Updated dependencies, fixed some wording in README (roadmap section listed array types twice).

## 1.1.2

- Fixed issue [#5](https://github.com/hipercompl/fbdb/issues/5) - `CHAR` fields right-padded with extra spaces due to 4-byte UTF-8 representation of each field character and the fact, that the Firebird client library reports the size of a returned `CHAR` field in bytes, not in characters. Detailed explanation can be found in [this article at StackOverflow](https://stackoverflow.com/questions/54657441/when-use-charset-parameter-pdo-fetchs-blank-spaces-in-fields#54672762).

## 1.1.1

- Fixed [issue #4](https://github.com/hipercompl/fbdb/issues/4): parameters being bound as `VARCHAR` could get truncated by 2 characters if they reach the maximum length reported by message metadata. This was due to the fact, that **fbdb** treated the 2-byte character count of a `VARCHAR` parameter as taking 2 bytes out of the reported parameter length (that's why exactly 2 characters were chopped off), while in fact the reported length mean just the maximum number of characters (and the 2-byte character count is not included). When the database used UTF-8 as field encoding, the issue was usually invisible, because in that case the actual number of bytes in the parameter buffer is 4 times the number of characters (and the extra 2-byte length almost always fit in the extra space).

## 1.1.0

- Added comatibility with the Firebird client libraries version 3.x (versions older than 3.0 don't work and **will not** work, as they don't expose interfaces-based API to the client code). Please note, that some functionality of the API, introduced in later versions of Firebird, will not be available when using client libraries from the previous versions (e.g. dec16, dec34 and time zones aren't supported when using client libraries from version 3). The appropriate Dart wrappers over native Firebird interfaces now use conditional method binding, throwing `UnimplementedError` when being invoked with an incompatible version of the client library. As a rule of thumb, it's always best to use the most recent officially available Firebird client library with *fbdb*.

- Verified compatibility with the Firebird libraries version 5.x in all currently supported Firebird client interfaces.

## 1.0.2

- Fixed a bug related to issue [#3](https://github.com/hipercompl/fbdb/issues/3). The bug manifested itself when an error was reported by Firebird, but the actual error message could not be obtained by `IUtil` due to a malformed UTF-8 string (so there was an error while handling another error).

## 1.0.1

- Completed API documentation.

## 1.0.0

- The first published version.
