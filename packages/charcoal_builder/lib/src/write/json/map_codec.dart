import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/iteration.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A JSON object, whose keys always turn into strings.
final class MapCodec(this._type) extends FieldCodec {
  final MapFieldType _type;

  FieldCodec get _key => FieldCodec.of(_type.key);
  FieldCodec get _value => FieldCodec.of(_type.value);

  @override
  String get typeName {
    return '${_type.ofClass ?? 'Map'}<${_key.typeName}, ${_value.typeName}>';
  }

  @override
  bool get isPassthrough => _isStringKey(_type.key) && _value.isPassthrough;

  @override
  String convert(String value, int depth) {
    final item = '\$e$depth';
    return '{for (final $item in $value.entries) '
        '${_keyToString(_type.key, '$item.key')}: '
        '${_value.encode('$item.value', depth + 1)}}';
  }

  @override
  String decode(String value, int depth) {
    final item = '\$e$depth';
    return Iteration.built(
      _type.ofClass,
      '{for (final $item in ($value as Map<String, Object?>).entries) '
      '${_keyFromString(_type.key, '$item.key')}: '
      '${_value.decode('$item.value', depth + 1)}}',
    );
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final collection = '\$c$depth';
    final key = '\$k$depth';
    final item = '\$e$depth';
    out
      ..writeln('final $collection = <${_key.typeName}, ${_value.typeName}>{};')
      ..writeln(r'if ($r.enterObject()) {')
      ..writeln('do {')
      ..writeln('final $key = ${_keyFromString(_type.key, r'$r.readKey()')};')
      ..writeln('final ${_value.typeName} $item;');
    _value.read(out, item, depth + 1);
    out
      ..writeln('$collection[$key] = $item;')
      ..writeln(r'} while ($r.nextInObject());')
      ..writeln('}')
      ..writeln('$target = ${Iteration.built(_type.ofClass, collection)};');
  }

  @override
  void write(Statements out, String value, int depth) {
    final item = '\$e$depth';
    out.literal('{');
    Iteration.open(out, '$value.entries', depth);
    _writeKey(out, '$item.key');
    out.literal(':');
    _value.write(out, '$item.value', depth + 1);
    Iteration.close(out);
    out.literal('}');
  }

  /// A key that is not a string is an int or a name, which need no escaping.
  void _writeKey(Statements out, String key) {
    final text = _keyToString(_type.key, key);
    if (_isStringKey(_type.key)) {
      out.code('CharcoalJson.writeString(\$sink, $text);');
    } else {
      out
        ..literal('"')
        ..code('\$sink.write($text);')
        ..literal('"');
    }
  }

  bool _isStringKey(FieldType key) {
    return switch (key) {
      PrimitiveFieldType(primitive: DartPrimitive.string) => true,
      ExtensionFieldType(:final representation) => _isStringKey(representation),
      _ => false,
    };
  }

  String _keyToString(FieldType key, String value) {
    return switch (key) {
      EnumFieldType() => FieldCodec.of(key).encode(value, 0),
      ExtensionFieldType(:final representation) => _keyToString(
        representation,
        '($value as ${FieldCodec.of(representation).typeName})',
      ),
      PrimitiveFieldType(primitive: DartPrimitive.int) => '$value.toString()',
      _ => value,
    };
  }

  String _keyFromString(FieldType key, String value) {
    return switch (key) {
      EnumFieldType(:final name) => '$name.values.byName($value)',
      ExtensionFieldType(:final typeName, :final representation) =>
        '(${_keyFromString(representation, value)}) as $typeName',
      PrimitiveFieldType(primitive: DartPrimitive.int) => 'int.parse($value)',
      _ => value,
    };
  }
}
