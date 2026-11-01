/// Thrown by generated decoders, wrapping whatever failed below them.
final class CharcoalException(this.type, this.cause) implements Exception {
  /// The name of the class being decoded.
  final String type;

  /// What failed, such as a [TypeError] or a [FormatException].
  final Object cause;

  @override
  String toString() => 'CharcoalException($type): $cause';
}
