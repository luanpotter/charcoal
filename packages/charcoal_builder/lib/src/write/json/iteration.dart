import 'package:charcoal_builder/src/write/json/statements.dart';

/// What iterables and maps have in common.
abstract final class Iteration() {
  /// Opens a block and a loop over anything without an index.
  static void open(Statements out, String iterable, int depth) {
    final isFirst = '\$isFirst$depth';
    out
      ..code('{')
      ..code('var $isFirst = true;')
      ..code('for (final \$e$depth in $iterable) {')
      ..code("if ($isFirst) { $isFirst = false; } else { \$sink.write(','); }");
  }

  static void close(Statements out) {
    out
      ..code('}')
      ..code('}');
  }

  /// Builds the declared collection out of what was decoded, if not core.
  static String built(String? ofClass, String collection) {
    return ofClass == null ? collection : '$ofClass.of($collection)';
  }
}
