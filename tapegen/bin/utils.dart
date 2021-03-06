import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import 'console.dart';
import 'errors.dart';

export 'dart:io';

export 'package:dartx/dartx.dart';
export 'package:dartx/dartx_io.dart';

typedef VoidCallback = void Function();

extension NullableCast on Object {
  T as<T>() => this is T ? (this as T) : null;
}

extension SingleOrNull<T> on Iterable<T> {
  T get singleOrNull => length == 1 ? single : null;
  Iterable<T> withoutNulls() => where((val) => val != null);
}

extension StreamyAdd<T> on List<T> {
  Future<void> addStream(Stream<T> stream) async {
    addAll(await stream.toList());
  }
}

extension NormalizedPath on File {
  /// The [path], but without unnecessary './' or '.\' or '..'.
  /// For example, "main.dart" instead of "./lib/../main.dart".
  String get normalizedPath => normalize(path);
}

extension ReadCliFile on File {
  Future<String> read([Task task]) async {
    task?.subtask('reading');
    if (!existsSync()) {
      throw FileNotFoundError(this);
    }

    try {
      return await readAsString();
    } catch (_) {
      throw CannotReadFromFileError(this);
    }
  }
}

extension WriteCliFile on File {
  Future<void> write(String content, [Task task]) async {
    task?.subtask('writing to file');
    try {
      await writeAsString(content);
    } catch (e) {
      throw CannotWriteToFileError(this);
    }
  }
}

extension CompilableSourceCode on String {
  CompilationUnit compile([Task task]) {
    task?.subtask('compiling');
    try {
      return parseString(content: this).unit;
      // Sadly, we can't always ensure that we pass in correct Dart code. But
      // that's okay, I guess.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw FileContainsSyntaxErrors();
    }
  }
}

extension FormattableSourceCode on String {
  String formatted() {
    try {
      return DartFormatter().format(this);
    } on FormatterException {
      throw CannotFormatCodeError();
    }
  }
}

class Replacement {
  Replacement({
    @required this.offset,
    @required this.length,
    @required this.replaceWith,
  });
  Replacement.forNode(AstNode node, this.replaceWith)
      : offset = node.offset,
        length = node.length;
  Replacement.insert({@required this.offset, @required this.replaceWith})
      : length = 0;

  final int offset;
  final int length;
  final String replaceWith;
}

extension ModifyCode on String {
  String applyAll(List<Replacement> replacements) {
    // We now got a list of replacements. The order in which we apply them is
    // important so that we don't mess up the offsets.
    replacements = replacements.sortedBy((replacement) => replacement.offset);
    var cursor = 0;
    final buffer = StringBuffer();
    for (final replacement in replacements) {
      buffer
        ..write(substring(cursor, replacement.offset))
        ..write(replacement.replaceWith);
      cursor = replacement.offset + replacement.length;
    }
    buffer.write(substring(cursor));
    return buffer.toString();
  }

  String apply(Replacement replacement) => applyAll([replacement]);
}

extension ModifyableSourceCode on String {
  String modify(
    Iterable<Replacement> Function() modify, {
    VoidCallback onNothingModified,
  }) {
    final replacements = modify().toList();
    if (replacements.isEmpty) {
      if (onNothingModified != null) {
        onNothingModified();
      }
      return this;
    } else {
      return applyAll(replacements);
    }
  }
}

void makeSureNoMoreArguments(List<String> args) {
  if (args.isNotEmpty) {
    throw UnexpectedArgumentError(args.first);
  }
}
