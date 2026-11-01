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
}
