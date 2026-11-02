import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

final class NullableCodec(this._type) extends FieldCodec {
  final NullableFieldType _type;

  FieldCodec get _inner => FieldCodec.of(_type.inner);

  @override
  String get typeName => '${_inner.typeName}?';

  @override
  bool get isPassthrough => _inner.isPassthrough;

  @override
  String convert(String value, int depth) {
    return 'switch ($value) { '
        'null => null, '
        'final \$v => ${_inner.encode(r'$v', depth)} '
        '}';
  }

  @override
  String decode(String value, int depth) {
    return 'switch ($value) { '
        'null => null, '
        'final \$v => ${_inner.decode(r'$v', depth)} '
        '}';
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    out
      ..writeln(r'if ($r.tryReadNull()) {')
      ..writeln('$target = null;')
      ..writeln('} else {');
    _inner.read(out, target, depth);
    out.writeln('}');
  }

  @override
  void write(Statements out, String value, int depth) {
    out.code('if ($value case final \$v?) {');
    _inner.write(out, r'$v', depth);
    out.code('} else {');
    out.literal('null');
    out.code('}');
  }
}
