@TestOn("vm")
library;

import 'dart:typed_data';
import 'dart:ffi';
import 'package:test/test.dart';
import 'package:fbdb/fbclient.dart';

/// Tests the loading of the Firebird client library
/// and the most basic interaction with the library.
/// Requires fbclient to be present in the _current_
/// (i.e. package root) directory.
void main() {
  FbClient? c;

  setUp(() {
    c = null;
  });

  tearDown(() {
    c?.close();
    c = null;
  });

  test("Loading the fbclient library", () {
    c = FbClient();
    expect(c, isNotNull);
    c?.close();
    expect(() => c?.fbGetMasterInterface(), throwsException);
    c?.close();
    expect(c?.lib, isNull);
    c = null;
  });

  test("Loading a non-existent library", () {
    expect(() => FbClient("wrong-library.name"), throwsArgumentError);
  });

  test("Getting the master interface reference", () {
    c = FbClient();
    expect(c, isNotNull);
    final m = c?.fbGetMasterInterface();
    expect(m, isNotNull);
    c?.close();
    c = null;
  });

  void testVaxInt(List<int> bytes, int nativeValue) {
    c = FbClient();
    expect(c, isNotNull);
    Pointer<Uint8> vaxInt = mem.allocate(bytes.length);
    try {
      vaxInt.fromDartMem(Uint8List.fromList(bytes));
      int? i = c?.iscVaxInteger(vaxInt, bytes.length);
      expect(i, isNotNull);
      expect(i, equals(nativeValue));
      c?.close();
      c = null;
    } finally {
      mem.free(vaxInt);
    }
  }

  test("Testing VAX integer of size 1B", () {
    testVaxInt([0x10], 0x10);
  });

  test("Testing VAX integer of size 2B", () {
    testVaxInt([0x10, 0x20], 0x2010);
  });

  test("Testing VAX integer of size 3B", () {
    testVaxInt(
      [0x10, 0x20, 0x30],
      0x302010,
    );
  });

  test("Testing VAX integer of size 4B", () {
    testVaxInt([0x10, 0x20, 0x30, 0x40], 0x40302010);
  });

  test("Testing VAX integer of size 5B", () {
    // integers larger than 32-bit are not supported
    // by iscVaxInteger, which returns 0 if the buffer size
    // is more than 4 bytes
    testVaxInt([0x10, 0x20, 0x30, 0x40, 0x50], 0);
  });

  test("Testing VAX integer of size 8B", () {
    // 64-bit integers are not supported by iscVaxInteger,
    // which returns 0 in such cases
    testVaxInt(
      [0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70, 0x71],
      0,
    );
  });
}
