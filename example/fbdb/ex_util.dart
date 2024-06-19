// Some utility functions shared between examples.
String mapToString(Map<String, dynamic> m) {
  final b = StringBuffer();
  for (var k in m.keys) {
    b.writeln("$k :: ${m[k]}");
  }
  return b.toString();
}
