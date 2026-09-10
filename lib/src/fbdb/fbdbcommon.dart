import "dart:convert";

import "package:fbdb/fbclient.dart";

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

/// The result of a batch execution.
///
/// The result contains a list of status values. The contents of the list
/// depend on the [FbBatchOptions.multiError] flag passed during
/// the batch creation.
///
/// - If [FbBatchOptions.multiError] was `true`, the [FbBatchResult.statuses]
/// will contain an etry for each statement executed in the batch
/// (successful or not).
/// For valid statements, the entry will be either [FbBatchResult.successNoInfo]
/// or the number of rows affected (if [FbBatchOptions.recordCounts] was set).
/// For invalid statements, the result will contain
/// an instance of [FbServerException]. The exception will contain
/// detailed error description, if the particular error fits below
/// the [maxDetailedErrors] limit, or a generic error message otherwise.
///
/// - If [FbBatchOptions.multiError] was `false` (or not set), the batch
/// execution of the batch **stops** at the first error. Therefore,
/// the [FbBatchResult.statuses] list will contain success indicators
/// ([FbBatchResult.successNoInfo] or numbers of affected rows, depending
/// on the [FbBatchOptions.recordCounts] flag) for all valid statements,
/// and **the last** entry of [FbBatchResult.statuses] will be the error
/// caused by the first invalid statement in the batch.
///
/// Obviously, if all statements in the batch completed without errors,
/// the [FbBatchResult.statuses] list will contain only success indicators
/// or record counts, no instance of [FbServerException] will be present.
class FbBatchResult {
  /// A successful execution of a single statement in a batch,
  /// or the whole batch if [FbBatchOptions.multiError] flag was not set.
  static const successNoInfo = -2;

  /// A generic value meaning execution of a statement (message)
  /// failed, but no additional information is available.
  static const executeFailed = -1;

  static const _noMoreErrors = 0xffffffff;

  /// A list of statuses for every executed statement in this batch.
  ///
  /// The list may contain just a single entry, when [FbBatchOptions.multiError]
  /// flag was not set during the batch creation, or it may contain an entry
  /// for each statement executed within the batch.
  ///
  /// Each entry can be either and instance of [FbServerException],
  /// or an integer, in which case it contains either
  /// [FbBatchResult.successNoInfo] (the statement succeeded), or
  /// the row count affected by the statement (if [FbBatchOptions.recordCounts]
  /// flag was set during batch creation).
  ///
  /// Please note, that for large batches, only up to
  /// [FbBatchOptions.maxDetailedErrors]
  /// first entries in [FbBatchResult.statuses] (for failed statements)
  /// will contain [FbServerException] errors with an actual error details.
  /// The rest of the failures (above the limit)
  /// will be represented by an instance of [FbServerException]
  /// with a generic error message ("Execution failed, no detailes available").
  /// The limit can be set via [FbBatchOptions.maxDetailedErrors] during the
  /// creation of a batch, but the limit is itself limited by the hard
  /// server limit (256 for Firebird 5). The default error count limit is 64,
  /// so if you don't execute more than 64 statements in a single batch,
  /// all reported errors will be detailed.
  List<dynamic> statuses = [];

  /// A property to quickly check if the status array contains any errors,
  /// without iterating over the array.
  ///
  /// This is just a convenience attribute. If you only need to know whether
  /// the batch fully succeeded or contains any failed statements, check
  /// the allOK property (it takes O(1) time, no list scan is performed).
  int errorCount = 0;

  /// A generic constructor. Generally use [FbBatchResult.fromCompletionState]
  /// instead.
  FbBatchResult({this.statuses = const [], this.errorCount = 0});

  /// Initializes [FbBatchResult] from an [IBatchCompletionState] interface.
  /// The [status] [IStatus] is required and must be properly allocated.
  /// The second [tmpStatus] [IStatus] instance is needed to retrieve
  /// detailed error information. If not provided, all unsuccesful
  /// executions will have a generic error message. If provided,
  /// up to [FbBatchOptions.maxDetailedErrors] (set upon batch creation)
  /// errors will have detailed error information, the remaining errors
  /// will be generic. To obtain actual error messages in the detailed errors,
  /// an instance of [IUtil] has to be provided as well.
  FbBatchResult.fromCompletionState({
    required IStatus status,
    required IBatchCompletionState state,
    IStatus? tmpStatus,
    IUtil? util,
    bool withRecordCounts = false,
  }) {
    status.init();
    final procSize = state.getSize(status);
    statuses = List<dynamic>.filled(procSize, successNoInfo, growable: false);

    if (withRecordCounts) {
      // copy all states from the batch completion state, because they
      // contain record counts, not just successNoInfo
      for (var i = 0; i < procSize; i++) {
        statuses[i] = state.getState(status, i);
      }
    }

    // process detailed errors
    int pos = -1;
    int lastPos = pos + 1;
    errorCount = 0;
    if (tmpStatus != null) {
      while (pos != _noMoreErrors) {
        lastPos = pos + 1;
        pos = state.findError(status, pos + 1);
        if (pos != _noMoreErrors) {
          tmpStatus.init();
          try {
            state.getStatus(status, tmpStatus, pos);
          } on FbStatusException catch (e) {
            if (e.status.errors.isNotEmpty &&
                e.status.errors.contains(FbErrorCodes.isc_batch_compl_detail)) {
              status.init(); // clear the error flag - error was handled here
              lastPos = pos; // process non-detailed errors from this one
              break; // no more detailed errors
            }
          }
          statuses[pos] = FbServerException.fromStatus(tmpStatus, util: util);
          errorCount++;
        }
      }
    }

    // all remaining errors, without any details
    final msg = "Execution failed, no details available";
    final msgBytes = Utf8Encoder().convert(msg);
    for (var i = lastPos; i < procSize; i++) {
      final st = state.getState(status, i);
      if (st == executeFailed) {
        errorCount++;
        statuses[i] = FbServerException([executeFailed], msg, true, msgBytes);
      }
    }
  }

  /// The total number of processed statements.
  int processed() {
    return statuses.length;
  }

  /// Returns only errors from the [statuses] list.
  /// The keys in the resultin maps are status indices (i.e. the indices
  /// of batch operations), and the values are corresponding [FbServerException]
  /// instances.
  Map<int, FbServerException> errors() {
    Map<int, FbServerException> res = {};
    for (var i = 0; i < statuses.length; i++) {
      if (statuses[i] is FbServerException) {
        res[i] = statuses[i];
      }
    }
    return res;
  }

  /// Returns only successes from the [statuses] list.
  /// The keys in the resultin maps are status indices (i.e. the indices
  /// of batch operations), and the values are corresponding status
  /// values (integers), denoting either the number of rows affected
  /// by a particular batch operation (if recordCounts was set during
  /// the batch creation), or [FbBatchResult.successNoInfo] constants.
  Map<int, int> successes() {
    Map<int, int> res = {};
    for (var i = 0; i < statuses.length; i++) {
      if (statuses[i] is int && statuses[i] != executeFailed) {
        res[i] = statuses[i];
      }
    }
    return res;
  }
}

/// The information about the current memory usage of a batch.
class FbBatchInfo {
  /// The batch buffer size in bytes (either default or set upon batch creation).
  int maxBufferSize = 0;

  /// The memory (in bytes) currently occupied by the batch data.
  int dataSize = 0;

  /// The memory (in bytes) currently occupied by the blobs in the batch.
  int blobSize = 0;
}
