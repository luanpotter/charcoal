import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/field_codec.dart';

/// Writes `copy` and `copyWith`, which share only what is a value.
abstract final class CopyWriter() {
  static const _keep = r'_$keep';
  static const _source = r'_$it';

  /// What marks a `copyWith` parameter as left out, once per part.
  static const sentinel =
      '''
const Object $_keep = _\$Keep();

final class const _\$Keep();
''';

  static bool needsSentinel(Iterable<ClassModel> classes) {
    return classes.any((model) => model.fields.any(_isNullable));
  }

  static String members(ClassModel model) {
    final name = model.name;
    final copy = model.isImmutable
        ? '$name copy() => this as $name;'
        : '''
$name copy() => \$copy(this as $name);

static $name \$copy($name \$it) => ${_construct(model, (field) => _copyOf(field.type, '\$it.${field.name}', 0))};
''';
    return '''
$copy

${name}CopyWith get copyWith => _${name}CopyWith(this as $name);
''';
  }

  /// The public interface, typed exactly as the fields, and its implementation.
  static String declarations(ClassModel model) {
    final name = model.name;
    final copyWith = '${name}CopyWith';
    return '''
abstract interface class $copyWith {
  $name call(${_parameters(model.fields, _publicParameter)});
}

final class const _$copyWith(this.$_source) implements $copyWith {
  final $name $_source;

  @override
  $name call(${_parameters(model.fields, _privateParameter)}) => ${_construct(model, (field) => _replaced(model, field))};
}
''';
  }

  static String _construct(
    ClassModel model,
    String Function(FieldModel field) valueOf,
  ) {
    final arguments = model.fields
        .map((field) {
          final value = valueOf(field);
          return field.isNamedParameter ? '${field.name}: $value' : value;
        })
        .join(', ');
    return '${model.constructor}($arguments)';
  }

  static String _parameters(
    List<FieldModel> fields,
    String Function(FieldModel field) parameterOf,
  ) {
    return fields.isEmpty ? '' : '{${fields.map(parameterOf).join(', ')}}';
  }

  static String _publicParameter(FieldModel field) {
    return '${FieldCodec.of(field.type).typeName} ${field.name}';
  }

  /// Only a nullable field needs a sentinel: in others, null means left out.
  static String _privateParameter(FieldModel field) {
    return _isNullable(field)
        ? 'Object? ${field.name} = $_keep'
        : '${FieldCodec.of(field.type).typeName}? ${field.name}';
  }

  static String _replaced(ClassModel model, FieldModel field) {
    final name = field.name;
    final current = '$_source.$name';
    final kept = model.isImmutable ? current : _copyOf(field.type, current, 0);
    return _isNullable(field)
        ? 'identical($name, $_keep) ? $kept : '
              '$name as ${FieldCodec.of(field.type).typeName}'
        : '$name ?? $kept';
  }

  static bool _isNullable(FieldModel field) {
    return field.type is NullableFieldType;
  }

  /// An expression building anew whatever a later write to [value] could reach.
  static String _copyOf(FieldType type, String value, int depth) {
    return switch (type) {
      PrimitiveFieldType() || EnumFieldType() || AdapterFieldType() => value,
      ClassFieldType(:final isImmutable, :final name) =>
        isImmutable ? value : '${name}Charcoal.\$copy($value)',
      final ExtensionFieldType type =>
        type.isValue ? value : _copyExtension(type, value, depth),
      final NullableFieldType type =>
        type.isValue ? value : _copyNullable(type, value, depth),
      final IterableFieldType type => _copyIterable(type, value, depth),
      final MapFieldType type => _copyMap(type, value, depth),
    };
  }

  static String _copyExtension(
    ExtensionFieldType type,
    String value,
    int depth,
  ) {
    final representation = type.representation;
    final cast = FieldCodec.of(representation).typeName;
    final copied = _copyOf(representation, '($value as $cast)', depth);
    return '($copied) as ${type.typeName}';
  }

  static String _copyNullable(
    NullableFieldType type,
    String value,
    int depth,
  ) {
    final present = '\$v$depth';
    final copied = _copyOf(type.inner, present, depth + 1);
    return 'switch ($value) { null => null, final $present => $copied }';
  }

  static String _copyIterable(
    IterableFieldType type,
    String value,
    int depth,
  ) {
    final element = FieldCodec.of(type.element).typeName;
    final item = '\$e$depth';
    final copied = _copyOf(type.element, item, depth + 1);
    final items = type.element.isValue
        ? '...$value'
        : 'for (final $item in $value) $copied';
    if (type.ofClass case final ofClass?) {
      final source = type.element.isValue ? value : '<$element>[$items]';
      return '$ofClass<$element>.of($source)';
    }
    return type.kind == IterableKind.set
        ? '<$element>{$items}'
        : '<$element>[$items]';
  }

  static String _copyMap(MapFieldType type, String value, int depth) {
    final arguments =
        '${FieldCodec.of(type.key).typeName}, '
        '${FieldCodec.of(type.value).typeName}';
    final entry = '\$e$depth';
    final entries = type.value.isValue
        ? '...$value'
        : 'for (final $entry in $value.entries) '
              '$entry.key: ${_copyOf(type.value, '$entry.value', depth + 1)}';
    if (type.ofClass case final ofClass?) {
      final source = type.value.isValue ? value : '<$arguments>{$entries}';
      return '$ofClass<$arguments>.of($source)';
    }
    return '<$arguments>{$entries}';
  }
}
