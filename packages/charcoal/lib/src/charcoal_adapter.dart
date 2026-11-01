/// Converts a type charcoal cannot serialize, [T], to one it can, [W].
///
/// A class implementing this is used by any annotated class in a library that
/// can see it, even inside of nullables and collections, and over how charcoal
/// would handle [T] otherwise. So keep it next to [T] if you own it, or else
/// export it along with charcoal, using `hide` to pick between two adapters.
///
/// It must have a `const` constructor with no arguments, as generated code
/// calls it directly, with no lookup at runtime.
abstract interface class CharcoalAdapter<T, W>() {
  W encode(T value);
  T decode(W json);
}
