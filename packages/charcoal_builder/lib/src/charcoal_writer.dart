abstract final class CharcoalWriter {
  static String write({
    required String partOf,
    required Iterable<String> classes,
  }) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln("part of '$partOf';");
    for (final name in classes) {
      buffer
        ..writeln()
        ..writeln('mixin ${name}Charcoal {}');
    }
    return buffer.toString();
  }
}
