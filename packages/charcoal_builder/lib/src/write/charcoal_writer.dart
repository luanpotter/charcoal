import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/write/json_writer.dart';
import 'package:dart_style/dart_style.dart';

abstract final class CharcoalWriter() {
  static const _pageWidth = 120;

  static String write({
    required String partOf,
    required Iterable<ClassModel> classes,
  }) {
    final buffer = StringBuffer()
      ..writeln('// dart format width=$_pageWidth')
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln("part of '$partOf';");
    for (final model in classes) {
      buffer
        ..writeln()
        ..writeln(_mixin(model));
    }

    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
      pageWidth: _pageWidth,
    ).format(buffer.toString());
  }

  static String _mixin(ClassModel model) {
    final name = model.name;
    final entries = model.fields
        .map((field) => JsonWriter.encodeEntry(model, field))
        .join(', ');
    final arguments = model.fields.map(JsonWriter.decodeArgument).join(', ');

    return '''
mixin ${name}Charcoal {
  Map<String, Object?> toMap() => \$encode(this as $name);

  void writeJson(StringBuffer \$sink) => \$write(this as $name, \$sink);

  String toJsonString() => encodeJsonString(this as $name);

  static Map<String, Object?> \$encode($name \$it) => {$entries};

  static void \$write($name \$it, StringBuffer \$sink) {
    ${JsonWriter.write(model)}
  }

  static String encodeJsonString($name \$it) {
    final \$sink = StringBuffer();
    \$write(\$it, \$sink);
    return \$sink.toString();
  }

  static $name fromMap(Map<String, Object?> \$json) {
    try {
      return \$decode(\$json);
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static $name fromJsonString(String \$source) {
    try {
      return \$decode(CharcoalJson.decodeObject(\$source));
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static $name \$decode(Map<String, Object?> \$json) => ${model.constructor}($arguments);
}
''';
  }
}
