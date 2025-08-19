/// The format in which a query is supposed to return subsequent data rows.
///
/// This enum is used internally in the communication between the FbQuery
/// objects and their worker thread parties.
/// The calling code should use a specialized method of [FbQuery]:
/// - [FbQuery.rows] to obtain row data as maps,
/// - [FbQuery.rowValues] to obtain row data as lists,
/// - [FbQuery.fetchOneAsMap], [FbQuery.fetchAsMaps], [FbQuery.fetchAllAsMaps]
///   to obtain rows as maps,
/// - [FbQuery.fetchOneAsList], [FbQuery.fetchAsLists],
///   [FbQuery.fetchAllAsLists] to obtain rows as lists.
enum FbRowFormat {
  /// Rows are maps with keys being column names.
  ///
  /// The names are provided exactly as obtained from the database,
  /// no case or any other conversion is performed.
  asMap,

  /// Rows are list of field values only.
  ///
  /// Field names are not included in the row data in any way.
  /// Use [FbQuery.fieldNames] or [FbQuery.fieldDefs] to get a list
  /// of field names / definitions.
  asList,
}
