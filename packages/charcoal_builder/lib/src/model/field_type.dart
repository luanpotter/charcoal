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

final class const NullableFieldType(this.inner) extends FieldType {
  final FieldType inner;
}
