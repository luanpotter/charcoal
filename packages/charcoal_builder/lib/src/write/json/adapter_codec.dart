import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A user's `CharcoalAdapter`, leaving the rest to its wire type.
final class AdapterCodec(this._type) extends FieldCodec {
  final AdapterFieldType _type;

  FieldCodec get _wire => FieldCodec.of(_type.wire);

  @override
  String get typeName => _type.typeName;

  @override
  String convert(String value, int depth) {
    return _wire.encode('${_type.adapter}.encode($value)', depth);
  }

  @override
  String decode(String value, int depth) {
    return '${_type.adapter}.decode(${_wire.decode(value, depth)})';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final raw = '\$x$depth';
    out.writeln('final ${_wire.typeName} $raw;');
    _wire.read(out, raw, depth + 1);
    out.writeln('$target = ${_type.adapter}.decode($raw);');
  }

  /// In a block, as writing a list refers to its value more than once.
  @override
  void write(Statements out, String value, int depth) {
    final encoded = '\$a$depth';
    out
      ..code('{')
      ..code('final $encoded = ${_type.adapter}.encode($value);');
    _wire.write(out, encoded, depth + 1);
    out.code('}');
  }
}
