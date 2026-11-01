import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// Writes the JSON code of a class, leaving each field to its [FieldCodec].
abstract final class JsonWriter() {
  static String encodeEntry(ClassModel model, FieldModel field) {
    final key = _mapKeyOf(field);
    final value = FieldCodec.of(field.type).encode('\$it.${field.name}', 0);
    if (!_isDroppable(model, field)) {
      return '$key: $value';
    }
    return field.type is NullableFieldType
        ? '$key: ?$value'
        : 'if (\$it.${field.name}.isNotEmpty) $key: $value';
  }

  static String decodeArgument(FieldModel field, int index) {
    final key = _mapKeyOf(field);
    final decoded = FieldCodec.of(field.type).decode('\$json[$key]', 0);
    final value = field.defaultValue == null
        ? decoded
        : '\$json.containsKey($key) ? $decoded : \$d$index';
    return field.isNamedParameter ? '${field.name}: $value' : value;
  }

  /// One constant per default, typed so that it means what it does in the
  /// parameter, where the context is also constant.
  static String defaults(ClassModel model) {
    return [
      for (final (index, field) in model.fields.indexed)
        if (field.defaultValue case final value?)
          _defaultOf(field, index, value),
    ].join('\n');
  }

  static String _defaultOf(FieldModel field, int index, String value) {
    final type = FieldCodec.of(field.type).typeName;
    return 'static const $type \$d$index = $value;';
  }

  /// The keys `$read` looks for, in the order it expects them.
  static String keys(ClassModel model) {
    return model.fields.map(_mapKeyOf).join(', ');
  }

  static String _mapKeyOf(FieldModel field) {
    return "'${field.name.replaceAll(r'$', r'\$')}'";
  }

  /// The body of `$read`, which builds no map.
  static String read(ClassModel model) {
    final out = StringBuffer();
    final fields = model.fields;
    for (final (index, field) in fields.indexed) {
      final type = FieldCodec.of(field.type).typeName;
      final local = field.type is NullableFieldType ? type : '$type?';
      final initial = field.defaultValue == null ? '' : ' = \$d$index';
      out.writeln('$local \$f$index$initial;');
    }
    out
      ..writeln(r'if ($r.enterObject()) {')
      ..writeln(r'var $next = 0;')
      ..writeln('do {')
      ..writeln(r'final $field = $r.readField($keys, $next);')
      ..writeln(r'switch ($field) {');
    for (final (index, field) in fields.indexed) {
      out.writeln('case $index:');
      FieldCodec.of(field.type).read(out, '\$f$index', 0);
    }
    out
      ..writeln(r'default: $r.skipValue();')
      ..writeln('}')
      ..writeln(r'$next = $field + 1;')
      ..writeln(r'} while ($r.nextInObject());')
      ..writeln('}');

    final arguments = fields.indexed
        .map((entry) {
          final (index, field) = entry;
          final local = field.type is NullableFieldType
              ? '\$f$index'
              : '\$f$index!';
          return field.isNamedParameter ? '${field.name}: $local' : local;
        })
        .join(', ');
    out.writeln('return ${model.constructor}($arguments);');
    return out.toString();
  }

  /// The body of `$write`, which builds no map.
  static String write(ClassModel model) {
    final out = Statements()..literal('{');
    final fields = model.fields;
    final certain = fields.indexWhere((field) => !_isDroppable(model, field));

    if (certain == -1) {
      _writeOnlyDroppable(out, fields);
    } else {
      for (final field in fields.take(certain)) {
        _writeDroppable(out, field, after: ',');
      }
      _writeCertain(out, fields[certain]);
      for (final field in fields.skip(certain + 1)) {
        if (_isDroppable(model, field)) {
          _writeDroppable(out, field, before: ',');
        } else {
          _writeCertain(out, field, before: ',');
        }
      }
    }

    return (out..literal('}')).finish();
  }

  /// Only what decoding brings back to the same value can be dropped.
  static bool _isDroppable(ClassModel model, FieldModel field) {
    if (model.omit == Omit.none) {
      return false;
    }
    if (field.type is NullableFieldType) {
      return field.defaultValue == null || field.isDefaultNull;
    }
    return model.omit == Omit.empty &&
        field.isDefaultEmpty &&
        _canBeEmpty(field.type);
  }

  static bool _canBeEmpty(FieldType type) {
    return switch (type) {
      PrimitiveFieldType(primitive: DartPrimitive.string) => true,
      IterableFieldType() || MapFieldType() => true,
      _ => false,
    };
  }

  static void _writePresentValue(Statements out, FieldModel field) {
    if (field.type case NullableFieldType(:final inner)) {
      FieldCodec.of(inner).write(out, r'$v', 0);
    } else {
      FieldCodec.of(field.type).write(out, '\$it.${field.name}', 0);
    }
  }

  static void _writeCertain(
    Statements out,
    FieldModel field, {
    String before = '',
  }) {
    out.literal('$before${_keyOf(field)}');
    FieldCodec.of(field.type).write(out, '\$it.${field.name}', 0);
  }

  static void _writeDroppable(
    Statements out,
    FieldModel field, {
    String before = '',
    String after = '',
  }) {
    out
      ..code(_ifPresent(field))
      ..literal('$before${_keyOf(field)}');
    _writePresentValue(out, field);
    out
      ..literal(after)
      ..code('}');
  }

  /// With no certain field, only a flag can tell if a comma is needed.
  static void _writeOnlyDroppable(Statements out, List<FieldModel> fields) {
    if (fields.length > 1) {
      out.code(r'var $comma = false;');
    }
    for (final (index, field) in fields.indexed) {
      out.code(_ifPresent(field));
      if (index > 0) {
        out.code(r"if ($comma) $sink.write(',');");
      }
      out.literal(_keyOf(field));
      _writePresentValue(out, field);
      if (index < fields.length - 1) {
        out.code(r'$comma = true;');
      }
      out.code('}');
    }
  }

  static String _ifPresent(FieldModel field) {
    return field.type is NullableFieldType
        ? 'if (\$it.${field.name} case final \$v?) {'
        : 'if (\$it.${field.name}.isNotEmpty) {';
  }

  static String _keyOf(FieldModel field) {
    return '"${field.name.replaceAll(r'$', r'\$')}":';
  }
}
