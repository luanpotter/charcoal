import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

/// Writes the body of a direct JSON writer, which builds no map.
abstract final class JsonWriter() {
  static String write(ClassModel model) {
    final out = _Statements()..literal('{');
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

  static bool _isDroppable(ClassModel model, FieldModel field) {
    return field.type is NullableFieldType && model.omit == Omit.nulls;
  }

  static void _writeCertain(
    _Statements out,
    FieldModel field, {
    String before = '',
  }) {
    out.literal('$before${_keyOf(field)}');
    _writeValue(out, field.type, '\$it.${field.name}');
  }

  static void _writeDroppable(
    _Statements out,
    FieldModel field, {
    String before = '',
    String after = '',
  }) {
    out
      ..code(_ifPresent(field))
      ..literal('$before${_keyOf(field)}');
    _writeValue(out, _innerOf(field), r'$v');
    out
      ..literal(after)
      ..code('}');
  }

  /// With no certain field, only a flag can tell if a comma is needed.
  static void _writeOnlyDroppable(_Statements out, List<FieldModel> fields) {
    if (fields.length > 1) {
      out.code(r'var $comma = false;');
    }
    for (final (index, field) in fields.indexed) {
      out.code(_ifPresent(field));
      if (index > 0) {
        out.code(r"if ($comma) $sink.write(',');");
      }
      out.literal(_keyOf(field));
      _writeValue(out, _innerOf(field), r'$v');
      if (index < fields.length - 1) {
        out.code(r'$comma = true;');
      }
      out.code('}');
    }
  }

  static String _ifPresent(FieldModel field) {
    return 'if (\$it.${field.name} case final \$v?) {';
  }

  static FieldType _innerOf(FieldModel field) {
    return (field.type as NullableFieldType).inner;
  }

  static String _keyOf(FieldModel field) {
    return '"${field.name.replaceAll(r'$', r'\$')}":';
  }

  static void _writeValue(_Statements out, FieldType type, String value) {
    switch (type) {
      case PrimitiveFieldType(:final primitive):
        out.code(switch (primitive) {
          DartPrimitive.string => 'CharcoalJson.writeString(\$sink, $value);',
          DartPrimitive.int || DartPrimitive.bool => '\$sink.write($value);',
          DartPrimitive.double ||
          DartPrimitive.num => 'CharcoalJson.writeNumber(\$sink, $value);',
        });
      case NullableFieldType(:final inner):
        out.code('if ($value case final \$v?) {');
        _writeValue(out, inner, r'$v');
        out.code('} else {');
        out.literal('null');
        out.code('}');
    }
  }
}

/// Statements, with adjacent literal writes merged into one.
final class _Statements() {
  final StringBuffer _code = StringBuffer();
  final StringBuffer _literal = StringBuffer();

  void literal(String text) => _literal.write(text);

  void code(String statement) {
    _flush();
    _code.writeln(statement);
  }

  String finish() {
    _flush();
    return _code.toString();
  }

  void _flush() {
    if (_literal.isNotEmpty) {
      _code.writeln("\$sink.write('$_literal');");
      _literal.clear();
    }
  }
}
