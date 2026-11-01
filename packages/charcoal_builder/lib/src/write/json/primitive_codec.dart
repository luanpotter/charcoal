import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

final class PrimitiveCodec(this._type) extends FieldCodec {
  final PrimitiveFieldType _type;

  @override
  String get typeName => _type.primitive.typeName;

  @override
  bool get isPassthrough => true;

  @override
  String convert(String value, int depth) => value;

  @override
  String decode(String value, int depth) {
    return _type.primitive == DartPrimitive.double
        ? '($value as num).toDouble()'
        : '$value as $typeName';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final method = switch (_type.primitive) {
      DartPrimitive.string => 'readString',
      DartPrimitive.int => 'readInt',
      DartPrimitive.double => 'readDouble',
      DartPrimitive.num => 'readNum',
      DartPrimitive.bool => 'readBool',
    };
    out.writeln('$target = \$r.$method();');
  }

  @override
  void write(Statements out, String value, int depth) {
    out.code(switch (_type.primitive) {
      DartPrimitive.string => 'CharcoalJson.writeString(\$sink, $value);',
      DartPrimitive.int || DartPrimitive.bool => '\$sink.write($value);',
      DartPrimitive.double ||
      DartPrimitive.num => 'CharcoalJson.writeNumber(\$sink, $value);',
    });
  }
}
