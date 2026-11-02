import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// By name, which is an identifier, so writing it never needs escaping.
///
/// Through `EnumName`, as an enum may declare a `name` of its own.
final class EnumCodec(this._type) extends FieldCodec {
  final EnumFieldType _type;

  @override
  String get typeName => _type.name;

  @override
  String convert(String value, int depth) => 'EnumName($value).name';

  @override
  String decode(String value, int depth) {
    return '$typeName.values.byName($value as String)';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    out.writeln('$target = $typeName.values.byName(\$r.readString());');
  }

  @override
  void write(Statements out, String value, int depth) {
    out
      ..literal('"')
      ..code('\$sink.write(${convert(value, depth)});')
      ..literal('"');
  }
}
