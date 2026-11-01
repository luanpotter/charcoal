import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

/// Writes all JSON code: map entries, decoder arguments and the direct writer.
abstract final class JsonWriter() {
  static String encodeEntry(ClassModel model, FieldModel field) {
    final key = _mapKeyOf(field);
    final value = _encode(field.type, '\$it.${field.name}');
    return _isDroppable(model, field) ? '$key: ?$value' : '$key: $value';
  }

  static String decodeArgument(FieldModel field) {
    final value = _decode(field.type, '\$json[${_mapKeyOf(field)}]');
    return field.isNamedParameter ? '${field.name}: $value' : value;
  }

  static String _mapKeyOf(FieldModel field) {
    return "'${field.name.replaceAll(r'$', r'\$')}'";
  }

  /// Whether a value already is what JSON holds, so `toMap` can reuse it.
  static bool _isPassthrough(FieldType type) {
    return switch (type) {
      PrimitiveFieldType() => true,
      EnumFieldType() || ClassFieldType() => false,
      IterableFieldType(kind: IterableKind.list, :final element) =>
        _isPassthrough(element),
      IterableFieldType() => false,
      MapFieldType(key: PrimitiveFieldType(), :final value) => _isPassthrough(
        value,
      ),
      MapFieldType() => false,
      NullableFieldType(:final inner) => _isPassthrough(inner),
    };
  }

  static String _encode(FieldType type, String value, {int depth = 0}) {
    if (_isPassthrough(type)) {
      return value;
    }
    final item = '\$e$depth';
    final next = depth + 1;
    return switch (type) {
      PrimitiveFieldType() => value,
      EnumFieldType() => '$value.name',
      ClassFieldType(:final name) => '${name}Charcoal.\$encode($value)',
      IterableFieldType(:final element) =>
        '[for (final $item in $value) '
            '${_encode(element, item, depth: next)}]',
      MapFieldType(:final key, value: final valueType) =>
        '{for (final $item in $value.entries) '
            '${_encode(key, '$item.key', depth: next)}: '
            '${_encode(valueType, '$item.value', depth: next)}}',
      NullableFieldType(inner: EnumFieldType()) => '$value?.name',
      NullableFieldType(:final inner) =>
        'switch ($value) { '
            'null => null, '
            'final \$v => ${_encode(inner, r'$v', depth: depth)} '
            '}',
    };
  }

  static String _decode(FieldType type, String value, {int depth = 0}) {
    final item = '\$e$depth';
    final next = depth + 1;
    return switch (type) {
      PrimitiveFieldType(primitive: DartPrimitive.double) =>
        '($value as num).toDouble()',
      PrimitiveFieldType(:final primitive) => '$value as ${primitive.typeName}',
      EnumFieldType(:final name) => '$name.values.byName($value as String)',
      ClassFieldType(:final name) =>
        '${name}Charcoal.\$decode($value as Map<String, Object?>)',
      IterableFieldType(kind: IterableKind.set, :final element) =>
        '{for (final $item in $value as List<Object?>) '
            '${_decode(element, item, depth: next)}}',
      IterableFieldType(:final element, :final ofClass) => _built(
        ofClass,
        '[for (final $item in $value as List<Object?>) '
        '${_decode(element, item, depth: next)}]',
      ),
      MapFieldType(:final key, value: final valueType, :final ofClass) =>
        _built(
          ofClass,
          '{for (final $item in ($value as Map<String, Object?>).entries) '
          '${_decodeKey(key, '$item.key', next)}: '
          '${_decode(valueType, '$item.value', depth: next)}}',
        ),
      NullableFieldType(:final inner) =>
        'switch ($value) { '
            'null => null, '
            'final \$v => ${_decode(inner, r'$v', depth: depth)} '
            '}',
    };
  }

  static String _decodeKey(FieldType key, String value, int depth) {
    return key is EnumFieldType ? _decode(key, value, depth: depth) : value;
  }

  static String _built(String? ofClass, String literal) {
    return ofClass == null ? literal : '$ofClass.of($literal)';
  }

  /// The keys `$read` looks for, in the order it expects them.
  static String keys(ClassModel model) {
    return model.fields.map(_mapKeyOf).join(', ');
  }

  /// The body of `$read`, which builds no map.
  static String read(ClassModel model) {
    final out = StringBuffer();
    final fields = model.fields;
    for (final (index, field) in fields.indexed) {
      out.writeln('${_nullableTypeOf(field.type)} \$f$index;');
    }
    out
      ..writeln(r'if ($r.enterObject()) {')
      ..writeln(r'var $next = 0;')
      ..writeln('do {')
      ..writeln(r'final $field = $r.readField($keys, $next);')
      ..writeln(r'switch ($field) {');
    for (final (index, field) in fields.indexed) {
      out.writeln('case $index:');
      _read(out, field.type, '\$f$index', 0);
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

  static void _read(
    StringBuffer out,
    FieldType type,
    String target,
    int depth,
  ) {
    final collection = '\$c$depth';
    final item = '\$e$depth';
    final next = depth + 1;
    switch (type) {
      case PrimitiveFieldType(:final primitive):
        final method = switch (primitive) {
          DartPrimitive.string => 'readString',
          DartPrimitive.int => 'readInt',
          DartPrimitive.double => 'readDouble',
          DartPrimitive.num => 'readNum',
          DartPrimitive.bool => 'readBool',
        };
        out.writeln('$target = \$r.$method();');
      case EnumFieldType(:final name):
        out.writeln('$target = $name.values.byName(\$r.readString());');
      case ClassFieldType(:final name):
        out.writeln('$target = ${name}Charcoal.\$read(\$r);');
      case IterableFieldType(:final element, :final kind, :final ofClass):
        final elementType = _typeOf(element);
        final isSet = kind == IterableKind.set;
        out
          ..writeln(
            'final $collection = <$elementType>${isSet ? '{}' : '[]'};',
          )
          ..writeln(r'if ($r.enterArray()) {')
          ..writeln('do {')
          ..writeln('final $elementType $item;');
        _read(out, element, item, next);
        out
          ..writeln('$collection.add($item);')
          ..writeln(r'} while ($r.nextInArray());')
          ..writeln('}')
          ..writeln('$target = ${_built(ofClass, collection)};');
      case MapFieldType(:final key, value: final valueType, :final ofClass):
        final readKey = key is EnumFieldType
            ? '${key.name}.values.byName(\$r.readKey())'
            : r'$r.readKey()';
        out
          ..writeln(
            'final $collection = '
            '<${_typeOf(key)}, ${_typeOf(valueType)}>{};',
          )
          ..writeln(r'if ($r.enterObject()) {')
          ..writeln('do {')
          ..writeln('final \$k$depth = $readKey;')
          ..writeln('final ${_typeOf(valueType)} $item;');
        _read(out, valueType, item, next);
        out
          ..writeln('$collection[\$k$depth] = $item;')
          ..writeln(r'} while ($r.nextInObject());')
          ..writeln('}')
          ..writeln('$target = ${_built(ofClass, collection)};');
      case NullableFieldType(:final inner):
        out
          ..writeln(r'if ($r.tryReadNull()) {')
          ..writeln('$target = null;')
          ..writeln('} else {');
        _read(out, inner, target, depth);
        out.writeln('}');
    }
  }

  static String _nullableTypeOf(FieldType type) {
    return type is NullableFieldType ? _typeOf(type) : '${_typeOf(type)}?';
  }

  static String _typeOf(FieldType type) {
    return switch (type) {
      PrimitiveFieldType(:final primitive) => primitive.typeName,
      EnumFieldType(:final name) || ClassFieldType(:final name) => name,
      IterableFieldType(:final element, :final kind, :final ofClass) =>
        '${ofClass ?? (kind == IterableKind.set ? 'Set' : 'List')}'
            '<${_typeOf(element)}>',
      MapFieldType(:final key, value: final valueType, :final ofClass) =>
        '${ofClass ?? 'Map'}<${_typeOf(key)}, ${_typeOf(valueType)}>',
      NullableFieldType(:final inner) => '${_typeOf(inner)}?',
    };
  }

  /// The body of `$write`, which builds no map.
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

  static void _writeValue(
    _Statements out,
    FieldType type,
    String value, {
    int depth = 0,
  }) {
    final next = depth + 1;
    switch (type) {
      case PrimitiveFieldType(:final primitive):
        out.code(switch (primitive) {
          DartPrimitive.string => 'CharcoalJson.writeString(\$sink, $value);',
          DartPrimitive.int || DartPrimitive.bool => '\$sink.write($value);',
          DartPrimitive.double ||
          DartPrimitive.num => 'CharcoalJson.writeNumber(\$sink, $value);',
        });
      case EnumFieldType():
        out
          ..literal('"')
          ..code('\$sink.write($value.name);')
          ..literal('"');
      case ClassFieldType(:final name):
        out.code('${name}Charcoal.\$write($value, \$sink);');
      case IterableFieldType(kind: IterableKind.list, :final element):
        final index = '\$i$depth';
        out
          ..literal('[')
          ..code('for (var $index = 0; $index < $value.length; $index++) {')
          ..code("if ($index > 0) \$sink.write(',');");
        _writeValue(out, element, '$value[$index]', depth: next);
        out
          ..code('}')
          ..literal(']');
      case IterableFieldType(:final element):
        final item = '\$e$depth';
        out.literal('[');
        _openIteration(out, value, depth);
        _writeValue(out, element, item, depth: next);
        out
          ..code('}')
          ..code('}')
          ..literal(']');
      case MapFieldType(:final key, value: final valueType):
        final item = '\$e$depth';
        out.literal('{');
        _openIteration(out, '$value.entries', depth);
        _writeValue(out, key, '$item.key', depth: next);
        out.literal(':');
        _writeValue(out, valueType, '$item.value', depth: next);
        out
          ..code('}')
          ..code('}')
          ..literal('}');
      case NullableFieldType(:final inner):
        out.code('if ($value case final \$v?) {');
        _writeValue(out, inner, r'$v', depth: depth);
        out.code('} else {');
        out.literal('null');
        out.code('}');
    }
  }

  /// Opens a block and a loop over anything without an index.
  static void _openIteration(_Statements out, String iterable, int depth) {
    final isFirst = '\$isFirst$depth';
    out
      ..code('{')
      ..code('var $isFirst = true;')
      ..code('for (final \$e$depth in $iterable) {')
      ..code("if ($isFirst) { $isFirst = false; } else { \$sink.write(','); }");
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
