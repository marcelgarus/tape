part of '../blocks.dart';

/// Annotates the subtree with a [typeId] that indicates which `TapeAdapter` can
/// interpret the blocks.
class TypedBlock implements Block {
  TypedBlock({@required this.typeId, @required this.child})
      : assert(typeId != null),
        assert(child != null);

  final int typeId;
  final Block child;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypedBlock && typeId == other.typeId && child == other.child;

  @override
  int get hashCode => runtimeType.hashCode ^ typeId.hashCode ^ child.hashCode;

  @override
  String toString([int indention = 0]) => 'TypedBlock(\n'
      '${'  ' * indention}  typeId: $typeId,\n'
      '${'  ' * indention}  child: ${child.toString(indention + 1)},\n'
      '${'  ' * indention})';
}

// An encoded [TypedBlock] looks like this:
// | type id as int64 | child block |
// The type id is encoded as int64.

extension _TypedBlockWriter on _Writer {
  void writeTypedBlock(TypedBlock block) {
    writeInt64(block.typeId);
    writeBlock(block.child);
  }
}

extension _TypedBlockReader on _Reader {
  TypedBlock readTypedBlock() {
    return TypedBlock(
      typeId: readInt64(),
      child: readBlock(),
    );
  }
}
