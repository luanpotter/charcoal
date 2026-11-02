sealed class const FieldType() {
  /// Whether `Omit.empty` can drop it: a number at zero or an empty collection.
  bool get canBeEmpty => false;
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
}

final class const EnumFieldType(this.name) extends FieldType {
  final String name;
}

final class const ClassFieldType(this.name) extends FieldType {
  final String name;
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
  this.ofClass,
}) extends FieldType {
  final FieldType element;
  final IterableKind kind;
  final String? ofClass;

  @override
  bool get canBeEmpty => true;
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
}

final class const NullableFieldType(this.inner) extends FieldType {
  final FieldType inner;
}
