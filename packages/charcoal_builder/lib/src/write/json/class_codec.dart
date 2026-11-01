import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// An annotated class, calling the code generated for it.
final class ClassCodec(this._type) extends FieldCodec {
  final ClassFieldType _type;

  @override
  String get typeName => _type.name;

  @override
  String convert(String value, int depth) {
    return '${typeName}Charcoal.\$encode($value)';
  }

  @override
  String decode(String value, int depth) {
    return '${typeName}Charcoal.\$decode($value as Map<String, Object?>)';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    out.writeln('$target = ${typeName}Charcoal.\$read(\$r);');
  }

  @override
  void write(Statements out, String value, int depth) {
    out.code('${typeName}Charcoal.\$write($value, \$sink);');
  }
}
