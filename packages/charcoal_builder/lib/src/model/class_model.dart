import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

/// Everything a library generates.
final class const LibraryModel({
  this.classes = const [],
  this.families = const [],
  this.instantiatedClasses = const [],
  this.instantiatedFamilies = const [],
}) {
  final List<ClassModel> classes;
  final List<FamilyModel> families;

  /// What each use of a generic class needs, such as `Link<Genre>`, as JSON
  /// depends on the type arguments.
  final List<ClassModel> instantiatedClasses;
  final List<FamilyModel> instantiatedFamilies;

  bool get isEmpty => classes.isEmpty && families.isEmpty;
}

final class const ClassModel({
  required this.name,
  required this.baseName,
  required this.constructor,
  required this.owner,
  required this.omit,
  required this.fields,
  this.typeParameters = '',
  this.isImmutable = false,
  this.familyTag,
  this.handWritten = const {},
}) {
  /// How generated code declares it: `Book` or `Link<T>`.
  final String name;

  /// Its name alone: `Book` or `Link`.
  final String baseName;

  /// How generated code calls the wire constructor: `Book` or `Link<T>.of`.
  final String constructor;

  /// What holds its generated code: `BookCharcoal` or `_$Link0`.
  final String owner;
  final Omit omit;
  final List<FieldModel> fields;

  /// Its type parameters as declared: `<T extends num>`, if it has any.
  final String typeParameters;

  /// Whether it is marked `@immutable`, so it compares by value.
  final bool isImmutable;

  /// What it writes first, if it is in a sealed family.
  final FamilyTag? familyTag;

  /// What it or a superclass defines, which is not to be generated.
  final Set<String> handWritten;

  /// Whether JSON has to wait for the type arguments of each use.
  bool get isGeneric => typeParameters.isNotEmpty;
}

final class const FamilyTag({required this.key, required this.value}) {
  final String key;
  final String value;
}

/// A sealed class, which decides by its tag which leaf a value is.
final class const FamilyModel({
  required this.name,
  required this.baseName,
  required this.owner,
  required this.discriminator,
  required this.isImmutable,
  required this.leaves,
  this.typeParameters = '',
}) {
  /// How generated code declares it: `Edition` or `Lookup<T>`.
  final String name;

  /// Its name alone: `Edition` or `Lookup`.
  final String baseName;

  /// What holds its generated code: `EditionCharcoal` or `_$Lookup0`.
  final String owner;
  final String discriminator;
  final bool isImmutable;
  final List<LeafModel> leaves;

  /// Its type parameters as declared: `<T extends num>`, if it has any.
  final String typeParameters;

  /// Whether JSON has to wait for the type arguments of each use.
  bool get isGeneric => typeParameters.isNotEmpty;
}

final class const LeafModel({
  required this.pattern,
  required this.owner,
  required this.tag,
  required this.isImmutable,
}) {
  /// How a switch matches it: `Hardcover` or `Known<String>`.
  final String pattern;

  /// What holds its generated code: `HardcoverCharcoal` or `_$Known0`.
  final String owner;
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
