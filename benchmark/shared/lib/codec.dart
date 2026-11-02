/// What each library has to provide for a model, so that every library runs
/// the exact same benchmarks.
///
/// A library lacking a feature leaves it out, and reports nothing for it.
final class Codec<T>({
  required this.toJson,
  required this.fromJson,
  required this.toMap,
  required this.fromMap,
  required this.hasEquality,
  this.copies,
}) {
  final String Function(T) toJson;
  final T Function(String) fromJson;
  final Map<String, Object?> Function(T) toMap;
  final T Function(Map<String, Object?>) fromMap;

  /// Whether `==` and `hashCode` compare by value.
  final bool hasEquality;

  final Copies<T>? copies;
}

/// The ways of calling `copyWith`, on a model with a `title` and `notes`.
final class Copies<T>({
  required this.same,
  required this.replacing,
  required this.clearing,
}) {
  /// Passing nothing.
  final T Function(T) same;

  /// Passing a new `title`.
  final T Function(T) replacing;

  /// Passing a null `notes`.
  final T Function(T) clearing;
}

/// A benchmark only some library can run, comparing it against itself.
final class Extra(this.name, this.action, {this.expected}) {
  final String name;
  final Object? Function() action;

  /// What it has to return, for it to be doing the right work.
  final Object? expected;
}
