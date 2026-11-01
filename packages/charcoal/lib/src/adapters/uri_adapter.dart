import 'package:charcoal/src/charcoal_adapter.dart';

/// Writes a [Uri] as a string.
///
/// To use your own, export `charcoal` with `hide UriAdapter`.
final class const UriAdapter() implements CharcoalAdapter<Uri, String> {
  @override
  String encode(Uri value) => value.toString();

  @override
  Uri decode(String json) => Uri.parse(json);
}
