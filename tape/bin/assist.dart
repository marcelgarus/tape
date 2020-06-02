import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_style/dart_style.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';
import 'package:dartx/dartx.dart';
import 'package:dartx/dartx_io.dart';

import 'code_replacement.dart';
import 'assist_utils.dart';
import 'tape.dart';

/// Assists the developer by autocompleting annotations.
final assist = Command(
  names: ['assist'],
  description: 'assists you while writing code',
  action: _assist,
);

Future<int> _assist(List<String> args) async {
  print('Running assist...');
  await _updateFile('lib/main.dart');

  Watcher('.').events.listen((event) {
    if (event.type == ChangeType.ADD || event.type == ChangeType.MODIFY) {
      _updateFile(event.path);
    }
  });
}

Future<void> _updateFile(String path) async {
  print('Updating $path…');

  if (!path.endsWith('.dart')) {
    print("Ignoring, since it's not a Dart file.");
    return;
  }

  // Read the source from the file and parse it into an AST.
  final file = File(path);
  final oldSource = await file.readAsString();
  String newSource;
  try {
    newSource = _enhanceSourceCode(
      fileName: file.name,
      sourceCode: oldSource,
    );
  } on SourceCodeHasErrorsException {
    print('Doing nothing, because file contains syntax errors.');
    return;
  } catch (e, st) {
    print("This shouldn't happen. Please file an issue.\n");
    print(e);
    print(st);
    return;
  }

  if (oldSource.length == newSource.length) {
    print('Nothing to be done.');
  } else {
    try {
      newSource = DartFormatter().format(newSource);
    } on FormatterException {
      print('The formatter threw an exception, which should not happen.');
      return;
    }

    await File(path).writeAsString(newSource);
    print('Done.');
  }
}

class SourceCodeHasErrorsException implements Exception {}

String _enhanceSourceCode({
  @required String fileName,
  @required String sourceCode,
}) {
  // Parse the source code.
  CompilationUnit compilationUnit;
  try {
    compilationUnit = parseString(content: sourceCode).unit;
  } on ArgumentError {
    throw SourceCodeHasErrorsException();
  }

  // These will be replacements for certain parts of the file. For example, an
  // unfinished `@TapeClass` may get replaced with `@TapeClass(nextFieldId: 10)`
  // or the space before a field inside a @TapeClass that is not annotated yet
  // will get replaced by `@TapeField(10, orDefault: ...)\n`.
  var replacements = <Replacement>[];

  var containsTapeAnnotations = false;
  final classDeclarations =
      compilationUnit?.declarations?.whereType<ClassDeclaration>() ??
          <ClassDeclaration>[];

  for (final declaration in classDeclarations.where((c) => c.isTapeClass)) {
    containsTapeAnnotations = true;
    final fields = declaration.members.whereType<FieldDeclaration>();
    var nextFieldId = declaration.tapeClassAnnotation.nextFieldId ??
        fields.map((field) => (field.fieldId ?? -1) + 1).max() ??
        0;

    for (final field in fields) {
      if (!field.isTapeField && !field.doNotTape) {
        // This field has no annotation although it is inside a @TapeClass.
        // Add a @TapeField annotation.
        replacements.add(Replacement(
          offset: field.offset,
          length: 0,
          replaceWith: '@TapeField($nextFieldId, defaultValue: TODO)\n',
        ));
        nextFieldId++;
      } else if (field.isTapeField && field.fieldId == null) {
        // Finish the @TapeField annotation.
        replacements.add(Replacement.forNode(
          field.tapeFieldAnnotation,
          '@TapeField($nextFieldId, defaultValue: TODO)',
        ));
        nextFieldId++;
      }
    }

    if (declaration.nextFieldId == null) {
      // Finish the @TapeClass annotation.
      replacements.add(Replacement.forNode(
        declaration.tapeClassAnnotation,
        '@TapeClass(nextFieldId: $nextFieldId)',
      ));
    }
  }

  if (containsTapeAnnotations) {
    assert(fileName.endsWith('.dart'));
    final extensionlessFileName =
        fileName.substring(0, fileName.length - '.dart'.length);
    final generatedFileName = '$extensionlessFileName.g.dart';

    // Make sure a `part 'some_file.g.dart';` directive exists.
    final hasDirective = compilationUnit.directives
        .whereType<PartDirective>()
        .any((part) => part.uri.stringValue == generatedFileName);
    if (!hasDirective) {
      final offset = compilationUnit.declarations.first.offset;

      replacements.add(Replacement(
        offset: offset,
        length: 0,
        replaceWith: "part '$generatedFileName';\n\n",
      ));
    }
  }

  return sourceCode.apply(replacements);
}