import "package:fbdb/fbclient.dart";

/// The definition of a table field in the database.
///
/// Objects of class [FbFieldDef] are immutable and in general
/// are constructed internally by FbDb routines.
/// There is little use of creating [FbFieldDef] objects by hand
/// in code.
/// However, you can obtain and examine [FbFieldDef] objects
/// from queries to determine the structure of the underlying data set.
class FbFieldDef {
  /// The name of the field.
  final String name;

  /// The offset of this field in the message.
  ///
  /// See [IMessageMetadata] for details.
  final int offset;

  /// The type of the field.
  ///
  /// The type definition is simplified and is Dart-based rather than
  /// SQL-based. For example, all integer types are described as
  /// [FbFieldType.ftInt], while all text types (CHAR as well as VARCHAR)
  /// are described as [FbFieldType.ftString].
  /// The type is intended more for a programmer to know, which type of
  /// Dart objects can be passed to / returned from a particular field,
  /// than to examine the actual SQL definition of the field
  /// (for the latter see the [fbType] attribute).
  /// See [FbFieldType] for possible values and [fbTypeMap] for mappings
  /// between Firebird types and Dart types.
  final FbFieldType type;

  /// The size of the field (both character and numeric).
  ///
  /// Please note, that [length] is measured in bytes, i.e. it determines
  /// the size of the memory block required to accomodate the field /
  /// parameter value, rather than being the "size" attribute of SQL
  /// data types.
  final int length;

  /// The field scale (when applicable).
  ///
  /// For some field types, Firebird stores real values as scaled integers,
  /// i.e. using the fixed point representation.
  /// For example, a value 100.01 can be stored as an integer 10001 with
  /// scale -2. It depends on the definition of a particular field in
  /// the database.
  /// FbDb returns all values scaled properly (and scales all parameters),
  /// so there is no need to scale / unscale them by hand.
  final int scale;

  /// Subtype of blob fields.
  ///
  /// Ignored for non-blob fields.
  final int subType;

  /// Is the field nullable.
  ///
  /// If True, null can be passed as a parameter value and can be obtained
  /// as a field value. In FbDb, SQL NULLs are mapped directly to Dart nulls.
  final bool nullable;

  /// The Firebird type code.
  ///
  /// This is the actual field type code, as returned by the Firebird
  /// server. The type constants are defined in [FbConsts] class,
  /// as SQL_* attributes.
  /// See [fbTypeMap] for mappings between Firebird types and Dart types.
  final int fbType;

  /// Constructs a constant field definition.
  const FbFieldDef(
    this.name,
    this.offset,
    this.type, {
    this.length = 0,
    this.subType = 0,
    this.scale = 0,
    this.nullable = true,
    this.fbType = 0,
  });

  /// Constructs the field definition from Firebird's message metadata.
  ///
  /// Analyzes [metadata] at the field index [fieldIdx]
  /// and constructs the field definition based on the metadata
  /// contents.
  static FbFieldDef fromMetadata(
      IMessageMetadata? metadata, int fieldIdx, IStatus status) {
    if (metadata == null) {
      throw FbClientException("No metadata provided for field definition");
    }
    var name = metadata.getField(status, fieldIdx);
    final alias = metadata.getAlias(status, fieldIdx);
    if (alias != "") {
      name = alias;
    }
    final int fbtype = metadata.getType(status, fieldIdx);

    // if the fbTypeMap doesn't contain a mapping between the FB
    // type code and FbDb type, then this particular type is
    // not supported by FbDb yet and we can't proceed
    if (!fbTypeMap.containsKey(fbtype)) {
      throw FbClientException(
          "The data type code $fbtype for field $name is not supported");
    }
    FbFieldType type = fbTypeMap[fbtype] ?? FbFieldType.ftString;

    final int subtype = metadata.getSubType(status, fieldIdx);
    final bool nullable = metadata.isNullable(status, fieldIdx);
    final int offset = metadata.getOffset(status, fieldIdx);
    final int scale = metadata.getScale(status, fieldIdx);
    final int length = metadata.getLength(status, fieldIdx);

    // special case: scaled integer
    if (type == FbFieldType.ftInt && scale != 0) {
      type = FbFieldType.ftFloat;
    }

    return FbFieldDef(
      name,
      offset,
      type,
      length: length,
      subType: subtype,
      scale: scale,
      nullable: nullable,
      fbType: fbtype,
    );
  }

  @override
  String toString() {
    final sc = scale != 0 ? ", ${-scale}" : "";
    return "$name : ${type.name} ($length$sc)";
  }
}

/// Supported field types.
enum FbFieldType {
  /// All text-based fields (CHAR, VARCHAR).
  ftString,

  /// All unscaled integer fields.
  ///
  /// Scaled integer fields actually contain real numbers and are given
  /// the [ftFloat] type.
  ftInt,

  /// All numeric, non-integer fields.
  ftFloat,

  /// All date, time and timestamp fields, both with and without the time zone.
  ftDatetime,

  /// Boolean fields.
  ftBoolean,

  /// Blob fields.
  ftBlob,

  /// Only NULL / NOT NULL indicators, no actual value.
  ///
  /// This field type is used mostly in query parameters, for queries
  /// like SELECT ... WHERE ? IS NULL
  /// The "?" parameter placeholder has no particular data type,
  /// for the query to execute properly it only needs to indicate
  /// whether it's NULL or NOT NULL. In such cases, the parameter
  /// type will be reported as [ftNull], so that you know not to
  /// set any meaningful value in it, but to pass either null
  /// or any non-null value as the query parameter instead.
  ftNull
}

/// Mappings between actual Firebird type codes and FbDb supported types.
const Map<int, FbFieldType> fbTypeMap = {
  /// SQL CHAR mapping
  FbConsts.SQL_TEXT: FbFieldType.ftString,

  /// SQL nullable CHAR mapping
  FbConsts.SQL_TEXT + 1: FbFieldType.ftString,

  /// SQL VARCHAR mapping
  FbConsts.SQL_VARYING: FbFieldType.ftString,

  /// SQL nullable VARCHAR mapping
  FbConsts.SQL_VARYING + 1: FbFieldType.ftString,

  /// SQL SMALLINT mapping
  FbConsts.SQL_SHORT: FbFieldType.ftInt,

  /// SQL nullable SMALLINT mapping
  FbConsts.SQL_SHORT + 1: FbFieldType.ftInt,

  /// SQL INTEGER mapping
  FbConsts.SQL_LONG: FbFieldType.ftInt,

  /// SQL nullable INTEGER mapping
  FbConsts.SQL_LONG + 1: FbFieldType.ftInt,

  FbConsts.SQL_FLOAT: FbFieldType.ftFloat,
  FbConsts.SQL_FLOAT + 1: FbFieldType.ftFloat,

  /// SQL DOUBLE PRECISION mapping
  FbConsts.SQL_DOUBLE: FbFieldType.ftFloat,

  /// SQL nullable DOUBLE PRECISION mapping
  FbConsts.SQL_DOUBLE + 1: FbFieldType.ftFloat,

  /// SQL TIMESTAMP mapping
  FbConsts.SQL_TIMESTAMP: FbFieldType.ftDatetime,

  /// SQL nullable TIMESTAMP mapping
  FbConsts.SQL_TIMESTAMP + 1: FbFieldType.ftDatetime,

  /// SQL BLOB mapping
  FbConsts.SQL_BLOB: FbFieldType.ftBlob,

  /// SQL nullable BLOB mapping
  FbConsts.SQL_BLOB + 1: FbFieldType.ftBlob,

  /// SQL TIME mapping
  FbConsts.SQL_TYPE_TIME: FbFieldType.ftDatetime,

  /// SQL nullable TIME mapping
  FbConsts.SQL_TYPE_TIME + 1: FbFieldType.ftDatetime,

  /// SQL DATE mapping
  FbConsts.SQL_TYPE_DATE: FbFieldType.ftDatetime,

  /// SQL nullable DATE mapping
  FbConsts.SQL_TYPE_DATE + 1: FbFieldType.ftDatetime,

  /// SQL BIGINT or scaled NUMERIC(N,M) mapping
  FbConsts.SQL_INT64: FbFieldType.ftInt,

  /// SQL nullable BIGINT or scaled NUMERIC(N,M) mapping
  FbConsts.SQL_INT64 + 1: FbFieldType.ftInt,

  /// SQL INT128 or scaled NUMERIC(N,M) mapping
  FbConsts.SQL_INT128: FbFieldType.ftFloat,

  /// SQL nullable INT128 or scaled NUMERIC(N,M) mapping
  FbConsts.SQL_INT128 + 1: FbFieldType.ftFloat,

  /// SQL TIMESTAMP WITH TIME ZONE mapping
  FbConsts.SQL_TIMESTAMP_TZ: FbFieldType.ftDatetime,

  /// SQL nullable TIMESTAMP WITH TIME ZONE mapping
  FbConsts.SQL_TIMESTAMP_TZ + 1: FbFieldType.ftDatetime,

  /// SQL TIME WITH TIME ZONE mapping
  FbConsts.SQL_TIME_TZ: FbFieldType.ftDatetime,

  /// SQL nullable TIME WITH TIME ZONE mapping
  FbConsts.SQL_TIME_TZ + 1: FbFieldType.ftDatetime,

  /// SQL TIMESTAMP WITH TIME ZONE mapping
  FbConsts.SQL_TIMESTAMP_TZ_EX: FbFieldType.ftDatetime,

  /// SQL nullable TIMESTAMP WITH TIME ZONE mapping
  FbConsts.SQL_TIMESTAMP_TZ_EX + 1: FbFieldType.ftDatetime,

  /// SQL TIME WITH TIME ZONE mapping
  FbConsts.SQL_TIME_TZ_EX: FbFieldType.ftDatetime,

  /// SQL nullable TIME WITH TIME ZONE mapping
  FbConsts.SQL_TIME_TZ_EX + 1: FbFieldType.ftDatetime,

  /// SQL BOOLEAN mapping
  FbConsts.SQL_BOOLEAN: FbFieldType.ftBoolean,

  /// SQL nullable BOOLEAN mapping
  FbConsts.SQL_BOOLEAN + 1: FbFieldType.ftBoolean,

  /// SQL DECIMAL(N,M) (DEC16) mapping
  FbConsts.SQL_DEC16: FbFieldType.ftFloat,

  /// SQL nullable DECIMAL(N,M) (DEC16) mapping
  FbConsts.SQL_DEC16 + 1: FbFieldType.ftFloat,

  /// SQL DECIMAL(N,M) (DEC34) mapping
  FbConsts.SQL_DEC34: FbFieldType.ftFloat,

  /// SQL nullable DECIMAL(N,M) (DEC34) mapping
  FbConsts.SQL_DEC34 + 1: FbFieldType.ftFloat,

  /// SQL NULL mapping
  FbConsts.SQL_NULL: FbFieldType.ftNull,

  /// SQL nullable NULL (?) mapping (just in case ;))
  FbConsts.SQL_NULL + 1: FbFieldType.ftNull,
};
