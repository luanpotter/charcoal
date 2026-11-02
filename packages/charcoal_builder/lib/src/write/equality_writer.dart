import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';

/// What a comparison costs, so that cheap ones can tell values apart first.
enum _Cost() {
  cheap,
  string,
  collection,
  nested,
}

/// Writes the bodies of `$equals` and `$hash`, and the rest of what they back.
abstract final class EqualityWriter() {
  /// Not zero, as mixing a zero into a zero would leave no trace of it.
  static const _seed = '0x2f1b';

  static String members(ClassModel model) {
    final name = model.name;
    if (model.isImmutable) {
      if (model.handWritten.contains('==')) {
        return '';
      }
      return '''
  @override
  bool operator ==(Object \$other) =>
      identical(this, \$other) || \$other is $name && \$equals(this as $name, \$other);

  @override
  int get hashCode => \$hash(this as $name);
''';
    }
    return '''
  bool contentEquals($name \$other) => \$equals(this as $name, \$other);

  int get contentHash => \$hash(this as $name);
''';
  }

  static String equals(ClassModel model) {
    final out = StringBuffer();
    for (final cost in _Cost.values) {
      for (final field in model.fields) {
        if (_costOf(field.type) == cost) {
          final name = field.name;
          _compare(out, field.type, '\$a.$name', '\$b.$name', 0);
        }
      }
    }
    out.writeln('return true;');
    return out.toString();
  }

  static String hash(ClassModel model) {
    final out = StringBuffer()..writeln('var \$h = $_seed;');
    for (final field in model.fields) {
      _mix(out, field.type, '\$it.${field.name}', r'$h', 0);
    }
    out.writeln(r'return CharcoalHash.finish($h);');
    return out.toString();
  }

  static _Cost _costOf(FieldType type) {
    return switch (type) {
      PrimitiveFieldType(:final primitive) =>
        primitive == DartPrimitive.string ? _Cost.string : _Cost.cheap,
      EnumFieldType() => _Cost.cheap,
      ExtensionFieldType(:final representation) => _costOf(representation),
      NullableFieldType(:final inner) => _costOf(inner),
      IterableFieldType() || MapFieldType() => _Cost.collection,
      ClassFieldType() ||
      AdapterFieldType() ||
      TypeParameterFieldType() => _Cost.nested,
    };
  }

  /// Statements returning false if [a] and [b] differ.
  static void _compare(
    StringBuffer out,
    FieldType type,
    String a,
    String b,
    int depth,
  ) {
    switch (type) {
      case EnumFieldType():
        out.writeln('if (!identical($a, $b)) return false;');
      case PrimitiveFieldType() ||
          AdapterFieldType() ||
          TypeParameterFieldType():
        _compareEquals(out, a, b);
      case ClassFieldType(:final isImmutable, :final owner):
        if (isImmutable) {
          _compareEquals(out, a, b);
        } else {
          out.writeln('if (!$owner.\$equals($a, $b)) return false;');
        }
      case ExtensionFieldType(:final isValue, :final representation):
        if (isValue) {
          _compareEquals(out, a, b);
        } else {
          final cast = FieldCodec.of(representation).typeName;
          _compare(
            out,
            representation,
            '($a as $cast)',
            '($b as $cast)',
            depth,
          );
        }
      case NullableFieldType(:final isValue, :final inner):
        if (isValue) {
          _compareEquals(out, a, b);
        } else {
          _compareNullable(out, inner, a, b, depth);
        }
      case final IterableFieldType type:
        _compareIterable(out, type, a, b, depth);
      case MapFieldType(:final value):
        _compareMap(out, value, a, b, depth);
    }
  }

  static void _compareEquals(StringBuffer out, String a, String b) {
    out.writeln('if ($a != $b) return false;');
  }

  static void _compareNullable(
    StringBuffer out,
    FieldType inner,
    String a,
    String b,
    int depth,
  ) {
    final left = '\$v$depth';
    final right = '\$w$depth';
    out
      ..writeln('if ($a case final $left?) {')
      ..writeln('if ($b case final $right?) {');
    _compare(out, inner, left, right, depth + 1);
    out
      ..writeln('} else { return false; }')
      ..writeln('} else if ($b != null) { return false; }');
  }

  static void _compareIterable(
    StringBuffer out,
    IterableFieldType type,
    String a,
    String b,
    int depth,
  ) {
    if (type.isSet) {
      final item = '\$e$depth';
      out
        ..writeln('if ($a.length != $b.length) return false;')
        ..writeln('for (final $item in $a) {')
        ..writeln('if (!$b.contains($item)) return false;')
        ..writeln('}');
    } else if (type.kind == IterableKind.list) {
      final index = '\$i$depth';
      out
        ..writeln('if ($a.length != $b.length) return false;')
        ..writeln('for (var $index = 0; $index < $a.length; $index++) {');
      _compare(out, type.element, '$a[$index]', '$b[$index]', depth + 1);
      out.writeln('}');
    } else {
      final left = '\$x$depth';
      final right = '\$y$depth';
      out
        ..writeln('{')
        ..writeln('final $left = $a.iterator;')
        ..writeln('final $right = $b.iterator;')
        ..writeln('while ($left.moveNext()) {')
        ..writeln('if (!$right.moveNext()) return false;');
      _compare(
        out,
        type.element,
        '$left.current',
        '$right.current',
        depth + 1,
      );
      out
        ..writeln('}')
        ..writeln('if ($right.moveNext()) return false;')
        ..writeln('}');
    }
  }

  static void _compareMap(
    StringBuffer out,
    FieldType value,
    String a,
    String b,
    int depth,
  ) {
    final entry = '\$e$depth';
    final other = '\$o$depth';
    final valueType = FieldCodec.of(value).typeName;
    out
      ..writeln('if ($a.length != $b.length) return false;')
      ..writeln('for (final $entry in $a.entries) {')
      ..writeln('if (!$b.containsKey($entry.key)) return false;')
      ..writeln('final $other = $b[$entry.key] as $valueType;');
    _compare(out, value, '$entry.value', other, depth + 1);
    out.writeln('}');
  }

  /// Statements mixing the hash of [value] into [target].
  static void _mix(
    StringBuffer out,
    FieldType type,
    String value,
    String target,
    int depth,
  ) {
    switch (type) {
      case EnumFieldType():
        _mixValue(out, target, '$value.index');
      case PrimitiveFieldType() ||
          AdapterFieldType() ||
          TypeParameterFieldType():
        _mixValue(out, target, '$value.hashCode');
      case ClassFieldType(:final isImmutable, :final owner):
        _mixValue(
          out,
          target,
          isImmutable ? '$value.hashCode' : '$owner.\$hash($value)',
        );
      case ExtensionFieldType(:final isValue, :final representation):
        if (isValue) {
          _mixValue(out, target, '$value.hashCode');
        } else {
          final cast = FieldCodec.of(representation).typeName;
          _mix(out, representation, '($value as $cast)', target, depth);
        }
      case NullableFieldType(:final isValue, :final inner):
        if (isValue) {
          _mixValue(out, target, '$value.hashCode');
        } else {
          final present = '\$v$depth';
          out.writeln('if ($value case final $present?) {');
          _mix(out, inner, present, target, depth + 1);
          out.writeln('} else {');
          _mixValue(out, target, '1');
          out.writeln('}');
        }
      case IterableFieldType(:final isSet, :final element):
        final item = '\$e$depth';
        if (isSet) {
          _mixUnordered(out, value, target, depth, (itemTarget) {
            _mix(out, element, item, itemTarget, depth + 1);
          });
        } else {
          out.writeln('for (final $item in $value) {');
          _mix(out, element, item, target, depth + 1);
          out.writeln('}');
        }
      case MapFieldType(key: final keyType, value: final valueType):
        final item = '\$e$depth';
        _mixUnordered(out, '$value.entries', target, depth, (itemTarget) {
          _mix(out, keyType, '$item.key', itemTarget, depth + 1);
          _mix(out, valueType, '$item.value', itemTarget, depth + 1);
        });
    }
  }

  static void _mixValue(StringBuffer out, String target, String value) {
    out.writeln('$target = CharcoalHash.mix($target, $value);');
  }

  /// Hashes each item alone and combines them in a way order cannot change.
  static void _mixUnordered(
    StringBuffer out,
    String items,
    String target,
    int depth,
    void Function(String itemTarget) mixItem,
  ) {
    final all = '\$c$depth';
    final one = '\$t$depth';
    out
      ..writeln('{')
      ..writeln('var $all = 0;')
      ..writeln('for (final \$e$depth in $items) {')
      ..writeln('var $one = $_seed;');
    mixItem(one);
    out
      ..writeln('$all ^= CharcoalHash.finish($one);')
      ..writeln('}');
    _mixValue(out, target, all);
    out.writeln('}');
  }
}
