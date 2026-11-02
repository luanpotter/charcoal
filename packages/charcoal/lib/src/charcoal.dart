/// Generates JSON, copy, equality, hash and `toString` for a data class.
final class const Charcoal({this.omit}) {
  /// Which fields JSON drops, defaulting to the `omit` option in `build.yaml`,
  /// or else to [Omit.nulls].
  final Omit? omit;
}

/// Which fields JSON drops.
enum Omit() {
  /// Keeps every field, writing nulls.
  none,

  /// Drops null fields.
  nulls,

  /// Also drops numbers at zero and empty collections, which must then default
  /// to that, so that decoding brings them back. Strings and bools are kept.
  empty,
}
