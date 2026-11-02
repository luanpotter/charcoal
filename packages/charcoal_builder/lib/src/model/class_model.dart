import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

final class const ClassModel({
  required this.name,
  required this.constructor,
  required this.omit,
  required this.fields,
  this.isImmutable = false,
}) {
  final String name;

  /// How generated code calls the wire constructor: `Book` or `Book.of`.
  final String constructor;
  final Omit omit;
  final List<FieldModel> fields;

  /// Whether it is marked `@immutable`, so it compares by value.
  final bool isImmutable;
}

final class const FieldModel({
  required this.name,
  required this.type,
  required this.isNamedParameter,
  this.defaultValue,
  this.isDefaultNull = false,
  this.isDefaultEmpty = false,
}) {
  final String name;
  final FieldType type;
  final bool isNamedParameter;

  /// The source of the parameter's default, if it has one.
  final String? defaultValue;
  final bool isDefaultNull;

  /// Whether the default is what `Omit.empty` drops: zero or an empty one.
  final bool isDefaultEmpty;
}
