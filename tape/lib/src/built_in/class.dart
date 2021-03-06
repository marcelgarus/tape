import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../blocks/blocks.dart';

const throwIfMissing = Object();

/// A snapshot of a class's field values.
class Fields extends Iterable<Field<dynamic>> {
  const Fields(this._fields);

  final Map<int, dynamic> _fields;
  Map<int, dynamic> toMap() => Map.from(_fields);

  T get<T>(int fieldId, {dynamic orDefault = throwIfMissing}) {
    if (_fields.containsKey(fieldId)) {
      return _fields[fieldId];
    }
    if (orDefault == throwIfMissing) {
      throw 'Missing field!';
      // throw MissingFieldException();
    }
    return orDefault;
  }

  bool containsId(int fieldId) => _fields.containsKey(fieldId);

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('Fields({');
    for (final field in this) {
      buffer.writeln('  ${field.id}: ${field.value},');
    }
    buffer.writeln('})');
    return buffer.toString();
  }

  @override
  Iterator<Field<dynamic>> get iterator => _fields.entries
      .map((entry) => Field(entry.key, entry.value))
      .toList()
      .iterator;
}

class Field<T> {
  Field(this.id, this.value);

  final int id;
  final T value;
}

/// [TapeClassAdapter]s can be extended to support serializing and
/// deserializing Dart objects of type [T].
@immutable
abstract class TapeClassAdapter<T> extends TapeAdapter<T> {
  const TapeClassAdapter();

  Fields toFields(T object);
  T fromFields(Fields fields);

  @override
  T fromBlock(Block block) {
    final fields = Fields({
      for (final field in block.as<FieldsBlock>().fields.entries)
        field.key: adapters.decode(field.value),
    });
    return fromFields(fields);
  }

  @override
  Block toBlock(T object) {
    return FieldsBlock({
      for (final field in toFields(object)._fields.entries)
        field.key: adapters.encode(field.value),
    });
  }
}
