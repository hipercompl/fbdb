// Demonstrates how to access output data when a stored procedure
// is not selectable (doesn't contain SUSPEND, so one can't SELECT
// from the procedure), but instead returns its data via output parameters.
//
// NOTICE: change the user name and/or password to match your Firebird setup.

import "package:fbdb/fbdb.dart";
import "ex_auth.dart";

void main() async {
  FbDb? db;
  try {
    print("Creating ex_06.fdb");
    db = await FbDb.createDatabase(
      database: "ex_06.fdb",
      user: userName,
      password: userPassword,
    );
    print("Created.");

    print("Creating stored procedure COUNT_DOTS");
    // The procedure actually counts the dots in the input string S
    // and returns the number of dots in its output parameter
    // CNT.
    const procSql = """
    create procedure COUNT_DOTS (S varchar(200))
    returns (CNT integer)
    as
      declare variable I integer;
    begin
      I = 1;
      CNT = 0;
      while (I <= char_length(S)) do
      begin
        if (substring(S from I for 1) = '.') then
          CNT = CNT + 1;
        I = I + 1;
      end
    end
    """;

    var q = db.query();
    await q.execute(sql: procSql);
    print("Procedure created.");

    const inTxt = "A.B.C.D.E.F.";
    print("Executing COUNT_DOTS('$inTxt')");

    await q.execute(
      sql: "execute procedure COUNT_DOTS(?)",
      parameters: [inTxt],
    );

    print("Fetching the procedure output");
    final o = await q.getOutputAsMap();
    print("The number of dots is ${o['CNT']} (should be 6)");

    await q.close();
  } catch (e) {
    print("Error detected: $e");
  } finally {
    if (db != null) {
      print("Dropping the database");
      await db.dropDatabase();
      print("Dropped.");
    }
  }
}
