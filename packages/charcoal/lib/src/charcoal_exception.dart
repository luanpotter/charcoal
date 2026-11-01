/// Thrown by generated decoders, wrapping whatever failed below them.
final class const CharcoalException(
  this.type,
  this.cause,
) implements Exception {
  final String type;
  final Object cause;

  @override
  String toString() => 'CharcoalException($type): $cause';
}
