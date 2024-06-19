abstract class TestConfig {
  /// The user name used when connecting to the Firebird server.
  /// The user has to have database creation rights.
  static final String dbUser = "SYSDBA";

  /// The password to authorize dbUser.
  static final String dbPassword = "masterkey";

  /// The location for temporary databases, to be created
  /// for some of the unit tests. The databases will be
  /// automatically dropped after a test completes.
  /// The directory should end with "/".
  static final String tmpDbDir = "localhost:/tmp/";

  /// The location of the default Firebird employee database,
  /// to be used in some tests.
  static final String employeeDB = "inet://localhost/employee";
}
