import 'package:charcoal/charcoal.dart';

const Omit _defaultOmit = Omit.nulls;

/// The options in `build.yaml`.
final class const CharcoalConfig({this.omit = _defaultOmit}) {
  final Omit omit;

  /// Fails on any unknown option or value.
  factory fromMap(Map<String, dynamic> map) {
    final unknown = map.keys.where((key) => key != 'omit');
    if (unknown.isNotEmpty) {
      throw ArgumentError('Unknown charcoal options: ${unknown.join(', ')}.');
    }

    return CharcoalConfig(
      omit: _parseEnum(Omit.values, map, 'omit') ?? _defaultOmit,
    );
  }

  static T? _parseEnum<T extends Enum>(
    List<T> values,
    Map<String, dynamic> map,
    String option,
  ) {
    final value = map[option];
    if (value == null) {
      return null;
    }
    final parsed = values.asNameMap()[value];
    if (parsed == null) {
      final allowed = values.map((e) => e.name).join(', ');
      throw ArgumentError(
        'The charcoal option $option must be one of: $allowed.',
      );
    }
    return parsed;
  }
}
