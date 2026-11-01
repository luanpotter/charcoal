import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/enum_codec.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/iteration.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A JSON object, with keys that are strings or enums.
final class MapCodec(this._type) extends FieldCodec {
  final MapFieldType _type;

  FieldCodec get _key => FieldCodec.of(_type.key);
  FieldCodec get _value => FieldCodec.of(_type.value);
  bool get _hasEnumKey => _key is EnumCodec;

  @override
  String get typeName {
    return '${_type.ofClass ?? 'Map'}<${_key.typeName}, ${_value.typeName}>';
  }

  @override
  bool get isPassthrough => !_hasEnumKey && _value.isPassthrough;

  @override
  String convert(String value, int depth) {
    final item = '\$e$depth';
    final next = depth + 1;
    return '{for (final $item in $value.entries) '
        '${_key.encode('$item.key', next)}: '
        '${_value.encode('$item.value', next)}}';
  }

  @override
  String decode(String value, int depth) {
    final item = '\$e$depth';
    final next = depth + 1;
    final key = _hasEnumKey ? _key.decode('$item.key', next) : '$item.key';
    return Iteration.built(
      _type.ofClass,
      '{for (final $item in ($value as Map<String, Object?>).entries) '
      '$key: ${_value.decode('$item.value', next)}}',
    );
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final collection = '\$c$depth';
    final key = '\$k$depth';
    final item = '\$e$depth';
    final readKey = _hasEnumKey
        ? '${_key.typeName}.values.byName(\$r.readKey())'
        : r'$r.readKey()';
    out
      ..writeln('final $collection = <${_key.typeName}, ${_value.typeName}>{};')
      ..writeln(r'if ($r.enterObject()) {')
      ..writeln('do {')
      ..writeln('final $key = $readKey;')
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
    _key.write(out, '$item.key', depth + 1);
    out.literal(':');
    _value.write(out, '$item.value', depth + 1);
    Iteration.close(out);
    out.literal('}');
  }
}
