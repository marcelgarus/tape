part of '../blocks.dart';

/// Saves the length of the [child] block so that if a block-level parsing error
/// occurs, we can skip the block. This is not intended to be used by consumers.
/// Instead, the `blocks` codec will automatically insert this block when it
/// encodes newly supported blocks. Similarly, it will also remove the
/// [SafeBlock] during decoding, replacing it either with its child or an
/// [UnsupportedBlock].
class SafeBlock implements Block {
  SafeBlock({@required this.child}) : assert(child != null);

  final Block child;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SafeBlock && child == other.child;

  @override
  int get hashCode => runtimeType.hashCode ^ child.hashCode;

  @override
  String toString([int indention = 0]) =>
      'SafeBlock(\n${' ' * indention}${child.toString(indention + 1)}\n)';
}

/// Is produced during decoding if a [SafeBlock] contained an unsupported block.
/// Cannot be explicitly encoded.
class UnsupportedBlock implements Block {
  UnsupportedBlock(this.blockId) : assert(blockId != null);

  final int blockId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnsupportedBlock && blockId == other.blockId;

  @override
  int get hashCode => runtimeType.hashCode ^ blockId.hashCode;

  @override
  String toString([int _]) => 'UnsupportedBlock($blockId)';
}

// An encoded [BytesBlock] looks like this:
// | num bytes | child |
// The number of bytes is encoded as an int64.

extension _SafeBlockWriter on _Writer {
  void writeSafeBlock(SafeBlock block) {
    final lengthCursor = cursor;
    writeInt64(0);
    final childStart = cursor;
    writeBlock(block.child);
    final childEnd = cursor;
    final length = childEnd - childStart;
    jumpTo(lengthCursor);
    writeInt64(length);
    jumpTo(childEnd);
  }
}

extension _SafeBlockReader on _Reader {
  Block readSafeBlock() {
    final length = readInt64();
    if (length == 0) {
      throw SafeBlockWithZeroLengthException();
    }
    final childStart = cursor;
    final childEnd = childStart + length;
    try {
      final child = readBlock();
      if (cursor != childEnd) {
        throw SafeBlockLengthDoesNotMatchException();
      }
      return SafeBlock(child: child);
    } on UnsupportedBlockException catch (e) {
      jumpTo(childEnd);
      return UnsupportedBlock(e.id);
    }
  }
}
