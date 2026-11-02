/// Generates JSON, copy, equality, hash and `toString` for a data class.
///
/// A class marked `@immutable` gets `==` and `hashCode` by value. Any other
/// keeps them by identity, and gets `contentEquals` and `contentHash` instead.
///
/// On a sealed root, it covers all children, so they can skip the annotation
/// unless they specify [omit] or [tag]. Concrete children still need the mixin.
final class const Charcoal({this.omit, this.discriminator, this.tag}) {
  /// Which fields JSON drops, defaulting to what a sealed class above it says,
  /// then to the `omit` option in `build.yaml`, or else to [Omit.nulls].
  final Omit? omit;

  /// On a sealed root, the JSON key holding the tag, defaulting to the
  /// `discriminator` option in `build.yaml`, or else to `type`.
  final String? discriminator;

  /// On a class below a sealed root, its value in JSON, defaulting to its name.
  final String? tag;
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
