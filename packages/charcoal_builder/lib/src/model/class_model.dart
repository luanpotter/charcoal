import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

/// Everything a library generates.
final class const LibraryModel({
  this.classes = const [],
  this.families = const [],
}) {
  final List<ClassModel> classes;
  final List<FamilyModel> families;

  bool get isEmpty => classes.isEmpty && families.isEmpty;
}

final class const ClassModel({
  required this.name,
  required this.constructor,
  required this.omit,
  required this.fields,
  this.isImmutable = false,
  this.familyTag,
  this.inherited = const {},
}) {
  final String name;

  /// How generated code calls the wire constructor: `Book` or `Book.of`.
  final String constructor;
  final Omit omit;
  final List<FieldModel> fields;

  /// Whether it is marked `@immutable`, so it compares by value.
  final bool isImmutable;

  /// What it writes first, if it is in a sealed family.
  final FamilyTag? familyTag;

  /// What a superclass defines, which a generated mixin would silently replace.
  final Set<String> inherited;
}

final class const FamilyTag({required this.key, required this.value}) {
  final String key;
  final String value;
}

/// A sealed class, which decides by its tag which leaf a value is.
final class const FamilyModel({
  required this.name,
  required this.discriminator,
  required this.isImmutable,
  required this.leaves,
}) {
  final String name;
  final String discriminator;
  final bool isImmutable;
  final List<LeafModel> leaves;
}

final class const LeafModel({
  required this.name,
  required this.tag,
  required this.isImmutable,
}) {
  final String name;
  final String tag;
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
