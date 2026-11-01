import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:dart_style/dart_style.dart';

abstract final class CharcoalWriter {
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
    final entries = model.fields.map(_encodeEntry).join(', ');
    final arguments = model.fields.map(_decodeArgument).join(', ');

    return '''
mixin ${name}Charcoal {
  Map<String, Object?> toMap() => \$encode(this as $name);

  static Map<String, Object?> \$encode($name \$it) => {$entries};

  static $name fromMap(Map<String, Object?> \$json) {
    try {
      return \$decode(\$json);
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static $name \$decode(Map<String, Object?> \$json) => ${model.constructor}($arguments);
}
''';
  }

  static String _encodeEntry(FieldModel field) {
    final key = _key(field);
    return switch (field.type) {
      PrimitiveFieldType() => '$key: \$it.${field.name}',
      NullableFieldType() => '$key: ?\$it.${field.name}',
    };
  }

  static String _decodeArgument(FieldModel field) {
    final value = _decode(field.type, '\$json[${_key(field)}]');
    return field.isNamedParameter ? '${field.name}: $value' : value;
  }

  static String _decode(FieldType type, String value) {
    return switch (type) {
      PrimitiveFieldType(primitive: DartPrimitive.double) =>
        '($value as num).toDouble()',
      PrimitiveFieldType(:final primitive) => '$value as ${primitive.typeName}',
      NullableFieldType(:final inner) =>
        'switch ($value) { '
            'null => null, '
            'final \$v => ${_decode(inner, r'$v')} '
            '}',
    };
  }

  static String _key(FieldModel field) {
    return "'${field.name.replaceAll(r'$', r'\$')}'";
  }
}
