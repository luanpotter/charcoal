/// Shared shape of the generated mixins for concrete classes.
abstract interface class CharcoalEncodable() {
  /// Its JSON as a map, as `jsonDecode` would give it.
  Map<String, Object?> toMap();

  /// Writes its JSON to [sink].
  void writeJson(StringBuffer sink);

  /// Its JSON as a string.
  String toJsonString();
}
