import 'dart:convert';

import '../blocks/blocks.dart';
import 'registry.dart';
import 'utils.dart';

export 'adapter.dart';
export 'errors.dart';
export 'registry.dart';
export 'utils.dart';

const adapters = _AdaptersCodec();

class _AdaptersCodec extends Codec<Object, Block> {
  const _AdaptersCodec();

  @override
  Converter<Object, Block> get encoder => const _AdaptersEncoder();

  @override
  Converter<Block, Object> get decoder => const _AdaptersDecoder();
}

class _AdaptersEncoder extends Converter<Object, Block> {
  const _AdaptersEncoder();

  @override
  Block convert(Object object) {
    final adapter = defaultTapeRegistry.adapterByValue(object);
    return TypedBlock(
      typeId: defaultTapeRegistry.idOfAdapter(adapter),
      child: adapter.toBlock(object),
    );
  }
}

class _AdaptersDecoder extends Converter<Block, Object> {
  const _AdaptersDecoder();

  @override
  Object convert(Block block) {
    final typedBlock = block.as<TypedBlock>();
    return defaultTapeRegistry
        .adapterForId(typedBlock.typeId)
        .fromBlock(typedBlock.child);
  }
}
