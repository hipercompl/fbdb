import "dart:ffi";
import "package:fbdb/fbclient.dart";

/// The base interface for all interfaces defining plugins.
/// Allows to build a basic owner-owned relationship.
class IPluginBase extends IReferenceCounted {
  @override
  int minSupportedVersion() => 3;

  late void Function(FbInterface self, FbInterface owner) _setOwner;
  late FbInterface Function(FbInterface self) _getOwner;

  IPluginBase(super.self) {
    startIndex = super.startIndex + super.methodCount;
    methodCount = 2;
    var idx = startIndex;
    _setOwner = Pointer<
            NativeFunction<
                Void Function(
                    FbInterface, FbInterface)>>.fromAddress(vtable[idx++])
        .asFunction();
    _getOwner =
        Pointer<NativeFunction<FbInterface Function(FbInterface)>>.fromAddress(
                vtable[idx++])
            .asFunction();
  }

  void setOwner(IReferenceCounted owner) {
    _setOwner(self, owner.self);
  }

  IReferenceCounted getOwner() {
    return IReferenceCounted(_getOwner(self));
  }
}
