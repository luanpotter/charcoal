sealed class const FieldType() {
  /// Whether `Omit.empty` can drop it: a number at zero or an empty collection.
  bool get canBeEmpty;

  /// Whether its own `==` compares it by value, and a copy can share it.
  bool get isValue;

  /// The name of a mutable class it holds, at any depth.
  String? get mutableClass;

  /// Whether it holds a set whose elements do not compare by value.
  bool get hasSetWithoutValues;
}

enum DartPrimitive(this.typeName) {
  string('String'),
  int('int'),
  double('double'),
  num('num'),
  bool('bool');

  final String typeName;
}

final class const PrimitiveFieldType(this.primitive) extends FieldType {
  final DartPrimitive primitive;

  bool get isNumber {
    return switch (primitive) {
      DartPrimitive.int || DartPrimitive.double || DartPrimitive.num => true,
      DartPrimitive.string || DartPrimitive.bool => false,
    };
  }

  @override
  bool get canBeEmpty => isNumber;

  @override
  bool get isValue => true;

  @override
  String? get mutableClass => null;

  @override
  bool get hasSetWithoutValues => false;
}

final class const EnumFieldType(this.name) extends FieldType {
  final String name;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => true;

  @override
  String? get mutableClass => null;

  @override
  bool get hasSetWithoutValues => false;
}

final class const ClassFieldType(
  this.name, {
  required this.owner,
  required this.isImmutable,
  required this.mutableClass,
}) extends FieldType {
  /// How generated code declares it: `Book` or `Link<Genre>`.
  final String name;

  /// What holds its generated code: `BookCharcoal` or `_$Link0`.
  final String owner;
  final bool isImmutable;

  @override
  final String? mutableClass;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => isImmutable;

  @override
  bool get hasSetWithoutValues => false;
}

/// A type parameter, inside the generic class declaring it.
///
/// Each use of the class knows the real type, as only that code can write JSON
/// or copy it. Here, it can only be compared with its own `==`, and shared.
final class const TypeParameterFieldType(this.name) extends FieldType {
  final String name;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => true;

  @override
  String? get mutableClass => null;

  @override
  bool get hasSetWithoutValues => false;
}

/// An extension type, which is the same as its representation in JSON.
///
/// Always goes through a cast, never a constructor or a field, as either could
/// be private, and a constructor could refuse a reserved value.
final class const ExtensionFieldType(
  this.typeName,
  this.representation,
) extends FieldType {
  /// How to declare it, such as `Id<Book>`.
  final String typeName;

  final FieldType representation;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => representation.isValue;

  @override
  String? get mutableClass => representation.mutableClass;

  @override
  bool get hasSetWithoutValues => representation.hasSetWithoutValues;
}

/// A type converted by a user's adapter, which is its [wire] type in JSON.
final class const AdapterFieldType({
  required this.typeName,
  required this.adapter,
  required this.wire,
}) extends FieldType {
  final String typeName;

  /// How to refer to the adapter, such as `const DateAdapter()`.
  final String adapter;
  final FieldType wire;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => true;

  @override
  String? get mutableClass => null;

  @override
  bool get hasSetWithoutValues => false;
}

/// Which is the fastest codec an iterable can use.
enum IterableKind() {
  /// Writes with an index and, if its contents allow, is reused by `toMap`.
  list,

  /// Decodes with a set literal, skipping a throwaway list.
  set,

  /// Anything else, which loops with `for` and decodes from a list.
  other,
}

/// A JSON array, built through `ofClass.of` unless it is a core type.
final class const IterableFieldType(
  this.element,
  this.kind, {
  required this.isSet,
  this.ofClass,
}) extends FieldType {
  final FieldType element;
  final IterableKind kind;

  /// Whether it is any kind of set, which compares unordered.
  final bool isSet;
  final String? ofClass;

  @override
  bool get canBeEmpty => true;

  @override
  bool get isValue => false;

  @override
  String? get mutableClass => element.mutableClass;

  @override
  bool get hasSetWithoutValues {
    return (isSet && !element.isValue) || element.hasSetWithoutValues;
  }
}

/// A JSON object, built through `ofClass.of` unless it is a core `Map`.
///
/// The key is a string, an int, an enum or an extension type over a string or
/// an int, all of which can turn into the string JSON needs.
final class const MapFieldType(
  this.key,
  this.value, {
  this.ofClass,
}) extends FieldType {
  final FieldType key;
  final FieldType value;
  final String? ofClass;

  @override
  bool get canBeEmpty => true;

  @override
  bool get isValue => false;

  @override
  String? get mutableClass => value.mutableClass;

  @override
  bool get hasSetWithoutValues => value.hasSetWithoutValues;
}

final class const NullableFieldType(this.inner) extends FieldType {
  final FieldType inner;

  @override
  bool get canBeEmpty => false;

  @override
  bool get isValue => inner.isValue;

  @override
  String? get mutableClass => inner.mutableClass;

  @override
  bool get hasSetWithoutValues => inner.hasSetWithoutValues;
}
