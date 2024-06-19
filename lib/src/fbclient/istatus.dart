import "dart:ffi";
import "package:fbdb/fbclient.dart";

/// The status vector, containing errors or warnings.
typedef StatusVec = Pointer<IntPtr>;

/// Interface wrapping the status of a database operation.
class IStatus extends IDisposable {
  @override
  int minSupportedVersion() => 3;

  static const iscStatusLength = 20; // from firebird/impl/types_pub.h
  static const stateWarnings = 0x1;
  static const stateErrors = 0x2;
  static const resultError = -1;
  static const resultOK = 0;
  static const resultNoData = 1;
  static const resultSegment = 2;

  late void Function(FbInterface self) _init;
  late int Function(FbInterface self) _getState;
  late void Function(FbInterface self, int length, StatusVec value) _setErrors2;
  late void Function(FbInterface self, int length, StatusVec value)
      _setWarnings2;
  late void Function(FbInterface self, StatusVec value) _setErrors;
  late void Function(FbInterface self, StatusVec value) _setWarnings;
  late StatusVec Function(FbInterface self) _getErrors;
  late StatusVec Function(FbInterface self) _getWarnings;
  late FbInterface Function(FbInterface self) _clone;

  /// Constructs the wrapper around the native IStatus interface.
  /// The [self] argument should be the raw pointer returned by
  /// the [IMaster._getStatus] method.
  /// The public [IMaster.getStatus] method returns the status already
  /// wrapped, so there should be no need to use the generative constructor
  /// directly.
  IStatus(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 9;
    var idx = startIndex;
    _init = Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
            vtable[idx++])
        .asFunction();
    _getState =
        Pointer<NativeFunction<UintPtr Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
    _setErrors2 = Pointer<
            NativeFunction<
                Void Function(FbInterface, UintPtr,
                    StatusVec)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setWarnings2 = Pointer<
            NativeFunction<
                Void Function(FbInterface, UintPtr,
                    StatusVec)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setErrors = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, StatusVec)>>.fromAddress(vtable[idx++])
        .asFunction();
    _setWarnings = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, StatusVec)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getErrors = Pointer<
            NativeFunction<
                StatusVec Function(
                    FbInterface self)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getWarnings = Pointer<
            NativeFunction<
                StatusVec Function(
                    FbInterface self)>>.fromAddress(vtable[idx++])
        .asFunction();
    _clone =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
  }

  void init() {
    _init(self);
  }

  int getState() {
    return _getState(self);
  }

  void setErrors2(int length, StatusVec value) {
    _setErrors2(self, length, value);
  }

  void setWarnings2(int length, StatusVec value) {
    _setWarnings2(self, length, value);
  }

  void setErrors(StatusVec value) {
    _setErrors(self, value);
  }

  void setWarnings(StatusVec value) {
    _setWarnings(self, value);
  }

  StatusVec getErrors() {
    return _getErrors(self);
  }

  StatusVec getWarnings() {
    return _getWarnings(self);
  }

  IStatus clone() {
    return IStatus(_clone(self));
  }

  /// Called automatically in all API methods.
  /// Throws an exception (wrapped around the status) if the status
  /// contains errors.
  void checkStatus() {
    if (isError) {
      throw FbStatusException(this);
    }
  }

  bool get isError => getState() & stateErrors != 0;
  bool get isWarning => getState() & stateWarnings != 0;

  List<int> get errors {
    if (isError) {
      return getErrors().cast<Int64>().asTypedList(iscStatusLength);
    } else {
      return [];
    }
  }

  List<int> get warnings {
    if (isWarning) {
      return getWarnings().cast<Int64>().asTypedList(iscStatusLength);
    } else {
      return [];
    }
  }
}
