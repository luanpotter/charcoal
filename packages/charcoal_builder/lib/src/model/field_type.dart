sealed class const FieldType();

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
}

final class const EnumFieldType(this.name) extends FieldType {
  final String name;
}

final class const ClassFieldType(this.name) extends FieldType {
  final String name;
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
}

/// A JSON object, built through `ofClass.of` unless it is a core `Map`.
///
/// The key is a string or an enum, as JSON keys have to be strings.
final class const MapFieldType(
  this.key,
  this.value, {
  this.ofClass,
}) extends FieldType {
  final FieldType key;
  final FieldType value;
  final String? ofClass;
}

final class const NullableFieldType(this.inner) extends FieldType {
  final FieldType inner;
}
