import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/write/copy_writer.dart';
import 'package:charcoal_builder/src/write/equality_writer.dart';
import 'package:charcoal_builder/src/write/family_writer.dart';
import 'package:charcoal_builder/src/write/json_writer.dart';
import 'package:dart_style/dart_style.dart';

abstract final class CharcoalWriter() {
  static const _pageWidth = 120;

  static String write({
    required String partOf,
    required LibraryModel model,
  }) {
    final buffer = StringBuffer()
      ..writeln('// dart format width=$_pageWidth')
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln()
      ..writeln("part of '$partOf';");
    if (CopyWriter.needsSentinel(model.classes)) {
      buffer
        ..writeln()
        ..writeln(CopyWriter.sentinel);
    }
    for (final classModel in model.classes) {
      buffer
        ..writeln()
        ..writeln(_mixin(classModel));
    }
    for (final family in model.families) {
      buffer
        ..writeln()
        ..writeln(FamilyWriter.write(family));
    }

    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
      pageWidth: _pageWidth,
    ).format(buffer.toString());
  }

  static String _toString(ClassModel model) {
    if (model.inherited.contains('toString')) {
      return '';
    }
    return '''
  @override
  String toString() {
    final \$it = this as ${model.name};
    return '${_toStringOf(model)}';
  }
''';
  }

  static String _toStringOf(ClassModel model) {
    final fields = model.fields
        .map((field) {
          final label = field.name.replaceAll(r'$', r'\$');
          return '$label: \${\$it.${field.name}}';
        })
        .join(', ');
    return '${model.name}($fields)';
  }

  static String _mixin(ClassModel model) {
    final name = model.name;
    final entries = JsonWriter.encodeEntries(model);
    final arguments = model.fields.indexed
        .map((entry) => JsonWriter.decodeArgument(entry.$2, entry.$1))
        .join(', ');

    return '''
mixin ${name}Charcoal {
  Map<String, Object?> toMap() => \$encode(this as $name);

  void writeJson(StringBuffer \$sink) => \$write(this as $name, \$sink);

  String toJsonString() => encodeJsonString(this as $name);

  ${CopyWriter.members(model)}

  ${EqualityWriter.members(model)}

  ${_toString(model)}

  static bool \$equals($name \$a, $name \$b) {
    ${EqualityWriter.equals(model)}
  }

  static int \$hash($name \$it) {
    ${EqualityWriter.hash(model)}
  }

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
      final \$r = CharcoalJsonReader(\$source);
      final \$it = \$read(\$r);
      \$r.finish();
      return \$it;
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static const List<String> \$keys = [${JsonWriter.keys(model)}];

  ${JsonWriter.defaults(model)}

  static $name \$read(CharcoalJsonReader \$r) {
    ${JsonWriter.read(model)}
  }

  static $name \$decode(Map<String, Object?> \$json) => ${model.constructor}($arguments);
}
''';
  }
}
