import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A user's `CharcoalAdapter`, leaving the rest to its wire type.
final class AdapterCodec(this._type) extends FieldCodec {
  final AdapterFieldType _type;

  FieldCodec get _wire => FieldCodec.of(_type.wire);

  String _encoded(String value) => '${_type.adapter}.encode($value)';

  @override
  String get typeName => _type.typeName;

  @override
  String convert(String value, int depth) => _encoded(value);

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

  @override
  void write(Statements out, String value, int depth) {
    _wire.write(out, _encoded(value), depth);
  }
}
