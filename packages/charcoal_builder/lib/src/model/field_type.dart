sealed class const FieldType() {
  /// Whether `Omit.empty` can drop it: a number at zero or an empty collection.
  bool get canBeEmpty;

  /// Whether its own `==` and `hashCode` compare it by value.
  bool get usesEquals;

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
  bool get usesEquals => true;

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
  bool get usesEquals => true;

  @override
  String? get mutableClass => null;

  @override
  bool get hasSetWithoutValues => false;
}

final class const ClassFieldType(
  this.name, {
  required this.isImmutable,
}) extends FieldType {
  final String name;
  final bool isImmutable;

  @override
  bool get canBeEmpty => false;

  @override
  bool get usesEquals => isImmutable;

  @override
  String? get mutableClass => isImmutable ? null : name;

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
  bool get usesEquals => representation.usesEquals;

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
  bool get usesEquals => true;

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
  bool get usesEquals => false;

  @override
  String? get mutableClass => element.mutableClass;

  @override
  bool get hasSetWithoutValues {
    return (isSet && !element.usesEquals) || element.hasSetWithoutValues;
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
  bool get usesEquals => false;

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
  bool get usesEquals => inner.usesEquals;

  @override
  String? get mutableClass => inner.mutableClass;

  @override
  bool get hasSetWithoutValues => inner.hasSetWithoutValues;
}
