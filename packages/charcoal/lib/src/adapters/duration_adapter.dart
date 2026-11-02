import 'package:charcoal/src/charcoal_adapter.dart';

/// Writes a [Duration] as whole microseconds.
///
/// To use your own, export `charcoal` with `hide DurationAdapter`.
final class const DurationAdapter() implements CharcoalAdapter<Duration, int> {
  @override
  int encode(Duration value) => value.inMicroseconds;

  @override
  Duration decode(int json) => Duration(microseconds: json);
}
