import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/tape_generator.dart';
import 'src/tape_all_generator.dart';

/// Builds generators for `build_runner` to run.
Builder getTapeBuilder(BuilderOptions options) {
  return SharedPartBuilder([TapeAllGenerator(), TapeGenerator()], 'tape');
}
