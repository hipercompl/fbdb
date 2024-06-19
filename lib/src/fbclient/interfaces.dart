import "dart:ffi";

import "package:fbdb/fbclient.dart";

typedef FbInterface = Pointer<UintPtr>;

/// Basic interface, from which all specialized interfaces descend.
///
/// For more information about using the OO API to access Firebird databases,
/// please refer to the doc/Using_OO_API.html document in the official
/// Firebird installation.
///
/// Technical notes.
///
/// All interfaces in the OO API extend (directly or indirectly)
/// the IVersioned interface. Both IDisposable and IReferenceCounted
/// base interfaces also extend IVersioned, therefore IVersioned's memory
/// layout implies the inner layout of all interface objects.
///
/// The IVersioned native interface in libfbclient consists of a dummy
/// CLOOP field (a single pointer to be ignored) and a pointer to the VTable,
/// i.e. an array of method pointers. The VTable is the heart of an interface,
/// because it is the only way to access the interface's functionality
/// (its methods).
///
/// Note: this philosophy resembles somewhat the Windows COM model.
///
/// A pointer to an interface returned by any libfbclient routine, which
/// is declared as returning an interface object, should be treated
/// (as long as the interface extends IVersioned) as an array of two
/// consecutive pointers, from which only the second pointer is actually
/// of any value, because it points to the VTable of the interface:
///
/// `((uintptr_t*) IVersioned)[0]` - ignore: CLOOP dummy pointer
/// `((uintptr_t*) IVersioned)[1]` - points to the VTable of the interface
///
/// The relevant snippet from the `IVersioned` C++ implementation
/// (include/firebird/IdlFbInterfaces.h):
///
/// ```
/// class IVersioned
/// {
/// public:
/// 	struct VTable
/// 	{
/// 		void* cloopDummy[1];
/// 		uintptr_t version;
/// 	};
///
/// 	void* cloopDummy[1];
/// 	VTable* cloopVTable;
/// ```
///
/// However, the original pointer to the interface has to be retained,
/// because methods of the interface require the interface pointer (and not
/// the interface's VTable pointer) to be passed as the first argument.
/// In other words, we invoke functions, which come from the VTable,
/// but the functions receive (as their first argument) not the VTable
/// as such, but an interface pointer, from which VTable can be further
/// obtained (as the second pointer counting from the beginning of
/// the interface).
///
/// Every interface extending IVersioned (which at this moment means
/// every interface from libfbclient OO API) on the Dart side is constructed
/// in the following way.
/// The Dart class, wrapping the Firebird interface, has the following
/// attrbutes:
/// - `startIndex` - defines the first index (slot) in the VTable,
/// which contains a method of this particular interface (all slots
/// with lower indices contain methods of ancestor interfaces); this attribute
/// is calculated as `startIndex` + `metodCount` of the parent interface
/// (except of `IVersioned`, for which those are constant, because it's
/// the ancestor of all other versioned interfaces),
/// - `methodCount` - defines the number of VTable slots, which this particular
/// interface occupies.
///
///
/// Therefore, if we have an interface hierarchy: A <- B <- C (B extends A,
/// and C extends B), their attributes are defined as:
/// - `A.startIndex` and `A.methodCount` are constant
/// (`A.startIndex` is most likely 0),
/// - `B.startIndex = A.startIndex + A.methodCount`,
/// - `B.methodCount` is constant (specific to interface B),
/// - `C.startIndex = B.startIndex + B.methodCount`,
/// - `C.methodCount` is constant (specific to interface C).
///
/// The calculation of `startIndex` in terms of the superclass' attributes
/// and the definition of `methodCount` are both placed in the class
/// constructor.
/// That's because fbclient is supposed to support different versions of
/// the Firebird interfaces, and in the future the values of
/// `methodCount` will depend on the version of the interface.
///
/// Additionally, each interface defines (overrides) the method
/// `minSupportedVersion`, which return the minimal required interface
/// version number. If a Dart object, created around a native Firebird
/// interface pointer, detects that the native interface has a version
/// lower than the minimum required (which can mean not all methods,
/// which the Dart class constructor will attempt to map, may be present
/// in the interface's VTable), an exception is thrown.
/// Note, that receiving a higher interface version should be safe
/// (as long as there are no descendant interfaces), the worst that can
/// happen is that some new methods from the VTable won't be available
/// in the Dart class.
///
/// The VTable layout of an example interface (IMetadataBuilder version 4,
/// extending IReferenceCounted, which extends IVersioned):
///
/// ```
/// [0]: IVersioned.CLOOP dummy pointer (to be ignored)
/// [1]: IVersioned.version number (from IVersioned)
/// [2]: IReferenceCounted.addRef method pointer
/// [3]: IReferenceCounted.release method pointer
/// [4]: IMetadataBuilder.setType method pointer
/// ...
/// [17]: IMetadataBuilder.setAlias method pointer
/// ```
///
/// In version 4, IMetadataBuilder has 14 methods (`VTable[4]` ... `VTable[17]`).
class IVersioned {
  /// The raw pointer to the native interface.
  FbInterface self = nullptr;

  /// The pointer to the interface's VTable.
  FbInterface vtable = nullptr;

  /// The first entry in the VTable the interface uses.
  int startIndex = 0;

  /// The number of entries in the VTable the interface occupies.
  int methodCount = 2;

  /// The interface version. Copied from the VTable for convenience.
  int version = 0;

  IVersioned(this.self) {
    if (self == nullptr) {
      throw FbClientException(
          "Attempt to create an interface from a null reference.");
    }
    vtable = FbInterface.fromAddress(self[1]);
    version = vtable[1];
    // both version and minSupportedVersion() will come from
    // the interface actually being instantiated
    // (possibly a descendant of IVersioned)
    if (version < minSupportedVersion()) {
      throw FbClientException(
          "${runtimeType.toString()}: interface version $version "
          "not supported (minimum supported version is ${minSupportedVersion()})");
    }
  }

  /// Defines the minimum native interface version supported by
  /// this class in fbclient.
  ///
  /// Overrided in all subclasses, as it's interface-specific.
  int minSupportedVersion() => 1;
}

/// The base for all reference counted interfaces.
/// Allows to call [release] when an interface is no longer needed.
class IReferenceCounted extends IVersioned {
  late void Function(FbInterface self) _addRef;
  late int Function(FbInterface self) _release;

  IReferenceCounted(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _addRef = Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
            vtable[idx++])
        .asFunction();
    _release = Pointer<NativeFunction<Int Function(FbInterface)>>.fromAddress(
            vtable[idx++])
        .asFunction();
  }

  /// Increase the reference count of the interface.
  void addRef() {
    _addRef(self);
  }

  /// Decrease the reference count of the interface, possibly causing
  /// the destruction of the interface (if its refcount reaches 0).
  /// After calling [release], the calling code must not use the
  /// interface in any fashion.
  int release() {
    return _release(self);
  }

  @override
  int minSupportedVersion() => 2;
}

/// The base for disposable interfaces, i.e. such that can be disposed of
/// when no longer needed by calling the [dispose] method.
/// They are not the same as reference counted interface, because in
/// refcounted ones calling release does not need to mean an immediate
/// deletion of the interface object, it just decrements the reference count
/// and the actual object is removed from memory when the refcount reaches zero.
/// A disposable interface, on the other hand, gets rid of the object
/// upon calling [dispose].
class IDisposable extends IVersioned {
  late void Function(FbInterface self) _dispose;

  IDisposable(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 1;
    _dispose = Pointer<NativeFunction<Void Function(FbInterface)>>.fromAddress(
            vtable[startIndex])
        .asFunction();
  }

  void dispose() {
    _dispose(self);
  }

  @override
  int minSupportedVersion() => 2;
}
