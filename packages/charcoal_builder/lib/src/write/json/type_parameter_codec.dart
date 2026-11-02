import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A type parameter, which only has a name, as a generic class has no JSON.
final class TypeParameterCodec(this._type) extends FieldCodec {
  final TypeParameterFieldType _type;

  @override
  String get typeName => _type.name;

  @override
  String convert(String value, int depth) => _unreachable();

  @override
  String decode(String value, int depth) => _unreachable();

  @override
  void read(StringBuffer out, String target, int depth) => _unreachable();

  @override
  void write(Statements out, String value, int depth) => _unreachable();

  Never _unreachable() {
    throw StateError('${_type.name} has no JSON until the class is used.');
  }
}
