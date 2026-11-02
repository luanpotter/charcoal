import 'package:charcoal/src/charcoal_adapter.dart';

/// Writes a [BigInt] as a string, as a JSON number could not hold it.
///
/// To use your own, export `charcoal` with `hide BigIntAdapter`.
final class const BigIntAdapter() implements CharcoalAdapter<BigInt, String> {
  @override
  String encode(BigInt value) => value.toString();

  @override
  BigInt decode(String json) => BigInt.parse(json);
}
