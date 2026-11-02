/// The mixing behind generated hashes, staying within 30 bits.
///
/// Hashes only mean something inside one process, so never persist one.
abstract final class CharcoalHash() {
  @pragma('vm:prefer-inline')
  static int mix(int hash, int value) {
    final sum = 0x1fffffff & (hash + value);
    final spread = 0x1fffffff & (sum + ((0x0007ffff & sum) << 10));
    return spread ^ (spread >> 6);
  }

  @pragma('vm:prefer-inline')
  static int finish(int hash) {
    final spread = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    final shifted = spread ^ (spread >> 11);
    return 0x1fffffff & (shifted + ((0x00003fff & shifted) << 15));
  }
}
