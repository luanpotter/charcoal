import 'package:charcoal/src/charcoal_adapter.dart';

/// Writes a [DateTime] as an ISO 8601 string.
///
/// To use your own, export `charcoal` with `hide DateTimeAdapter`.
final class const DateTimeAdapter()
    implements CharcoalAdapter<DateTime, String> {
  @override
  String encode(DateTime value) => value.toIso8601String();

  @override
  DateTime decode(String json) => DateTime.parse(json);
}
