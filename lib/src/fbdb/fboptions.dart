import "package:fbdb/fbclient.dart";

/// Database connection options.
///
/// Objects of class [FbOptions] can be passed to
/// [FbDb.attach] and [FbDb.createDatabase] to set some additional
/// properties of the attachment or the database that is about to
/// be created.
///
/// Example:
/// ```dart
/// final db = await FbDb.createDatabase(
///   host: "localhost",
///   database: "testdb",
///   // set the page size of the new database to 8kB
///   // and the default database character set to UTF8
///   options: FbOptions(pageSize: 8192, dbCharset: "UTF8"),
/// );
/// // work with the database here using the db attachment object
/// await db.detach();
/// // db cannot be used any more
/// ```
///
/// See FbDb Programmer's Guide for details.
class FbOptions {
  /// Default flags for new transactions.
  ///
  /// Those flags will be used if no flags are specified
  /// in the call to [FbDb.startTransaction].
  Set<FbTrFlag> transactionFlags;

  /// The timeout for resolving lock conflicts with wait transactions.
  int? lockTimeout;

  /// The page size for new databases (relevant only when calling
  /// [FbDb.createDatabase]).
  int pageSize;

  /// The default database character set for new databases.
  String dbCharset;

  /// The default collation for new databases.
  ///
  /// If not specified, the default collation for the database
  /// character set will be used.
  String? dbCollation;

  /// The location of the fbclient native dynamic library.
  ///
  /// You can provide full relative or absolute path to the Firebird
  /// client dynamic library (fbclient.dll / libfbclient.so /
  /// libfbclient.dylib) or just the file name. In the latter case
  /// the standard resolving mechanism for a particular operating
  /// system will be used. If not specified, defaults to fbclient.dll
  /// on Windows, libfbclient.so on linux and libfbclient.dylib on MacOS.
  String? libFbClient;

  /// Default transaction flags.
  ///
  /// These flags will be used in each call to [FbDb.startTransaction],
  /// unless specified otherwise during the call.
  /// The lock timeout for wait transactions is infinite by default.
  static const defaultTransactionFlags = fbTrWriteWait;

  /// Constructs a new options object with reasonable defaults.
  ///
  /// When called with no arguments whatsoever, the constructed
  /// object will represent the default values of each parameter
  /// (in which case there's no point in passing it to the attachment
  /// initialization routine, because it won't change anything in
  /// the default behavior).
  FbOptions({
    this.transactionFlags = defaultTransactionFlags,
    this.lockTimeout,
    this.pageSize = 4096,
    this.dbCharset = "UTF8",
    this.dbCollation,
    this.libFbClient,
  });

  /// Checks if the current transaction flags are the same as default ones.
  ///
  /// If they are, there's not need to pass a TPB block when starting
  /// a new transaction (it won't change anything and can be safely omitted
  /// to save resources).
  bool transactionFlagsDefault() {
    for (var f in defaultTransactionFlags) {
      if (!transactionFlags.contains(f)) {
        return false;
      }
    }
    for (var f in transactionFlags) {
      if (!defaultTransactionFlags.contains(f)) {
        return false;
      }
    }
    // two-sided set inclusion => sets equal

    // non-null lockTimeout means non-default transaction setup
    return (lockTimeout == null);
  }
}

/// Transaction flags.
///
/// The options and their meaning are described in Firebird server
/// documentation.
/// See also FbDb Programmer's Guide for more information.
enum FbTrFlag {
  /// read-only transaction
  read,

  /// read-write transaction
  write,

  /// prefer concurrency (takes advantage of record versioning)
  concurrency,

  /// prefer consistency (table locking)
  consistency,
  readCommitted,
  recVersion,
  noRecVersion,

  /// wait on conflicting updates
  wait,

  /// don't wait on deadlocks
  noWait,
  shared,
  protected,
  exclusive,
  lockWrite,
  lockRead,
}

/// Default flags for writing transaction waiting on locks.
const fbTrWriteWait = {FbTrFlag.concurrency, FbTrFlag.write, FbTrFlag.wait};

/// Default flags for writing transaction not waiting on locks.
const fbTrWriteNoWait = {FbTrFlag.concurrency, FbTrFlag.write, FbTrFlag.noWait};

/// Default flags for read-only transaction.
const fbTrRead = {FbTrFlag.concurrency, FbTrFlag.read};

/// Mapping of transaction flags to specific TPB flag values.
Map<FbTrFlag, int> fbTrParTags = {
  FbTrFlag.read: FbConsts.isc_tpb_read,
  FbTrFlag.concurrency: FbConsts.isc_tpb_concurrency,
  FbTrFlag.write: FbConsts.isc_tpb_write,
  FbTrFlag.consistency: FbConsts.isc_tpb_consistency,
  FbTrFlag.readCommitted: FbConsts.isc_tpb_read_committed,
  FbTrFlag.recVersion: FbConsts.isc_tpb_rec_version,
  FbTrFlag.noRecVersion: FbConsts.isc_tpb_no_rec_version,
  FbTrFlag.wait: FbConsts.isc_tpb_wait,
  FbTrFlag.noWait: FbConsts.isc_tpb_nowait,
  FbTrFlag.shared: FbConsts.isc_tpb_shared,
  FbTrFlag.protected: FbConsts.isc_tpb_protected,
  FbTrFlag.exclusive: FbConsts.isc_tpb_exclusive,
  FbTrFlag.lockWrite: FbConsts.isc_tpb_lock_write,
  FbTrFlag.lockRead: FbConsts.isc_tpb_lock_read,
};
