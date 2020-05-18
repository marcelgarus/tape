class TapeType {
  const TapeType(this.trackingCode);

  final String trackingCode;
}

/// Annotating a class with `@TapeClass` indicates that a [TapeAdapter] should
/// get generated for it when running `tapegen`.
class TapeClass {
  const TapeClass({this.nextFieldId});

  /// The id of the next field to be inserted.
  final int nextFieldId;
}

/// Annotating a field in a `@TapeClass` class with `@TapeField` indicates that
/// it should get serialization and deserialization code should get created for
/// it when running `tapegen`.
class TapeField {
  const TapeField([this.id]);

  /// An id that uniquely identifies this field among other fields of this
  /// class that currently exist, existed in the past, and will exist in the
  /// future.
  final int id;
}

const DoNotTape = DoNotTapeImpl();

class DoNotTapeImpl {
  const DoNotTapeImpl();
}