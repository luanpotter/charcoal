import 'package:charcoal/charcoal.dart';

const Omit _defaultOmit = Omit.nulls;
const String _defaultDiscriminator = 'type';
const Set<String> _options = {'omit', 'discriminator'};

/// The options in `build.yaml`.
final class const CharcoalConfig({
  this.omit = _defaultOmit,
  this.discriminator = _defaultDiscriminator,
}) {
  final Omit omit;
  final String discriminator;

  /// Fails on any unknown option or value.
  factory fromMap(Map<String, dynamic> map) {
    final unknown = map.keys.where((key) => !_options.contains(key));
    if (unknown.isNotEmpty) {
      throw ArgumentError('Unknown charcoal options: ${unknown.join(', ')}.');
    }

    final discriminator = map['discriminator'] ?? _defaultDiscriminator;
    if (discriminator is! String) {
      throw ArgumentError(
        'The charcoal option discriminator must be a string.',
      );
    }

    return CharcoalConfig(
      omit: _parseEnum(Omit.values, map, 'omit') ?? _defaultOmit,
      discriminator: discriminator,
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
