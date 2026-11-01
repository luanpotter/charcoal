/// What each library has to provide for a model, so that every library runs
/// the exact same benchmarks.
final class Codec<T>({
  required this.toJson,
  required this.fromJson,
  required this.toMap,
  required this.fromMap,
}) {
  final String Function(T) toJson;
  final T Function(String) fromJson;
  final Map<String, Object?> Function(T) toMap;
  final T Function(Map<String, Object?>) fromMap;
}
