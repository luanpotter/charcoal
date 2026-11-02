import 'package:charcoal_builder/src/model/field_type.dart';
import 'package:charcoal_builder/src/write/json/adapter_codec.dart';
import 'package:charcoal_builder/src/write/json/class_codec.dart';
import 'package:charcoal_builder/src/write/json/enum_codec.dart';
import 'package:charcoal_builder/src/write/json/extension_codec.dart';
import 'package:charcoal_builder/src/write/json/iterable_codec.dart';
import 'package:charcoal_builder/src/write/json/map_codec.dart';
import 'package:charcoal_builder/src/write/json/nullable_codec.dart';
import 'package:charcoal_builder/src/write/json/primitive_codec.dart';
import 'package:charcoal_builder/src/write/json/statements.dart';
import 'package:charcoal_builder/src/write/json/type_parameter_codec.dart';

/// Writes the code that takes one kind of field to and from JSON.
///
/// The `depth` of each method keeps variables of nested collections apart.
abstract class FieldCodec() {
  static FieldCodec of(FieldType type) {
    return switch (type) {
      final PrimitiveFieldType type => PrimitiveCodec(type),
      final EnumFieldType type => EnumCodec(type),
      final ClassFieldType type => ClassCodec(type),
      final AdapterFieldType type => AdapterCodec(type),
      final ExtensionFieldType type => ExtensionCodec(type),
      final IterableFieldType type => IterableCodec(type),
      final MapFieldType type => MapCodec(type),
      final NullableFieldType type => NullableCodec(type),
      final TypeParameterFieldType type => TypeParameterCodec(type),
    };
  }

  /// How generated code declares a variable of this type.
  String get typeName;

  /// Whether a value already is what JSON holds, so `toMap` can reuse it.
  bool get isPassthrough => false;

  /// An expression turning [value] into what `toMap` holds.
  String encode(String value, int depth) {
    return isPassthrough ? value : convert(value, depth);
  }

  /// An expression for what `toMap` holds, if it differs from [value].
  String convert(String value, int depth);

  /// An expression turning [value], from `fromMap`, into this type.
  String decode(String value, int depth);

  /// Statements for `$read`, assigning to [target].
  void read(StringBuffer out, String target, int depth);

  /// Statements for `$write`, writing [value].
  void write(Statements out, String value, int depth);
}
