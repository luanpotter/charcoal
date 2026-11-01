import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';
import 'package:charcoal_builder/src/write/json/iteration.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';

/// A JSON array, using the fastest code its [IterableKind] allows.
final class IterableCodec(this._type) extends FieldCodec {
  final IterableFieldType _type;

  FieldCodec get _element => FieldCodec.of(_type.element);
  bool get _isList => _type.kind == IterableKind.list;
  bool get _isSet => _type.kind == IterableKind.set;

  @override
  String get typeName {
    final name = _type.ofClass ?? (_isSet ? 'Set' : 'List');
    return '$name<${_element.typeName}>';
  }

  @override
  bool get isPassthrough => _isList && _element.isPassthrough;

  @override
  String convert(String value, int depth) {
    final item = '\$e$depth';
    return '[for (final $item in $value) '
        '${_element.encode(item, depth + 1)}]';
  }

  @override
  String decode(String value, int depth) {
    final item = '\$e$depth';
    final loop =
        'for (final $item in $value as List<Object?>) '
        '${_element.decode(item, depth + 1)}';
    return _isSet ? '{$loop}' : Iteration.built(_type.ofClass, '[$loop]');
  }

  @override
  void read(StringBuffer out, String target, int depth) {
    final collection = '\$c$depth';
    final item = '\$e$depth';
    final elementType = _element.typeName;
    out
      ..writeln('final $collection = <$elementType>${_isSet ? '{}' : '[]'};')
      ..writeln(r'if ($r.enterArray()) {')
      ..writeln('do {')
      ..writeln('final $elementType $item;');
    _element.read(out, item, depth + 1);
    out
      ..writeln('$collection.add($item);')
      ..writeln(r'} while ($r.nextInArray());')
      ..writeln('}')
      ..writeln('$target = ${Iteration.built(_type.ofClass, collection)};');
  }

  @override
  void write(Statements out, String value, int depth) {
    out.literal('[');
    if (_isList) {
      _writeWithIndex(out, value, depth);
    } else {
      Iteration.open(out, value, depth);
      _element.write(out, '\$e$depth', depth + 1);
      Iteration.close(out);
    }
    out.literal(']');
  }

  void _writeWithIndex(Statements out, String value, int depth) {
    final index = '\$i$depth';
    out
      ..code('for (var $index = 0; $index < $value.length; $index++) {')
      ..code("if ($index > 0) \$sink.write(',');");
    _element.write(out, '$value[$index]', depth + 1);
    out.code('}');
  }
}
