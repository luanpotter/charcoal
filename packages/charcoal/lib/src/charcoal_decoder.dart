/// The decoding statics of a class, as one constant, for code that only knows
/// the class as a type parameter. Encoding needs none: see `CharcoalEncodable`.
///
/// Each class has one as `XCharcoal.decoder`, and so does each sealed class,
/// decoding any leaf by its tag. A generic class has none, as it has no JSON
/// until a use knows the type arguments.
final class const CharcoalDecoder<T>(this.fromJsonString, this.fromMap) {
  /// As `XCharcoal.fromJsonString`.
  final T Function(String json) fromJsonString;

  /// As `XCharcoal.fromMap`.
  final T Function(Map<String, Object?> map) fromMap;
}
