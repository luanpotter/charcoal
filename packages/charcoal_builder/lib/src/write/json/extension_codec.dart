import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// An extension type, which is the same as its representation in JSON.
final class ExtensionCodec(this._type) extends FieldCodec {
  final ExtensionFieldType _type;

  FieldCodec get _representation => FieldCodec.of(_type.representation);

  @override
  String get typeName => _type.typeName;

  @override
  bool get isPassthrough => _representation.isPassthrough;

  @override
  String convert(String value, int depth) {
    return _representation.encode('$value.${_type.field}', depth);
  }

  @override
  String decode(String value, int depth) {
    return '${_type.constructor}(${_representation.decode(value, depth)})';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final raw = '\$x$depth';
    out.writeln('final ${_representation.typeName} $raw;');
    _representation.read(out, raw, depth + 1);
    out.writeln('$target = ${_type.constructor}($raw);');
  }

  @override
  void write(Statements out, String value, int depth) {
    _representation.write(out, '$value.${_type.field}', depth);
  }
}
