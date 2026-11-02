import 'dart:convert';

const int _quote = 0x22;
const int _backslash = 0x5c;
const int _space = 0x20;
const int _surrogateMin = 0xd800;
const int _surrogateMask = 0xfc00;
const int _surrogateLead = 0xd800;
const int _surrogateTrail = 0xdc00;

/// What generated JSON code needs and cannot import from a part.
abstract final class CharcoalJson() {
  /// Writes a number exactly as `jsonEncode` does, refusing NaN and infinities.
  static void writeNumber(StringBuffer sink, num value) {
    if (!value.isFinite) {
      throw JsonUnsupportedObjectError(value);
    }
    sink.write(value);
  }

  /// Writes a quoted string, escaped exactly as `jsonEncode` does.
  static void writeString(StringBuffer sink, String value) {
    jsonEncode(value);
    sink.writeCharCode(_quote);
    var start = 0;
    for (var i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      final isEscaped = unit > _backslash
          ? unit >= _surrogateMin && _isLoneSurrogate(value, i, unit)
          : unit < _space || unit == _quote || unit == _backslash;
      if (isEscaped) {
        if (i > start) {
          sink.write(value.substring(start, i));
        }
        _writeEscaped(sink, unit);
        start = i + 1;
      }
    }
    if (start == 0) {
      sink.write(value);
    } else if (start < value.length) {
      sink.write(value.substring(start));
    }
    sink.writeCharCode(_quote);
  }

  static bool _isLoneSurrogate(String value, int index, int unit) {
    return switch (unit & _surrogateMask) {
      _surrogateLead =>
        index + 1 >= value.length ||
            value.codeUnitAt(index + 1) & _surrogateMask != _surrogateTrail,
      _surrogateTrail =>
        index == 0 ||
            value.codeUnitAt(index - 1) & _surrogateMask != _surrogateLead,
      _ => false,
    };
  }

  static void _writeEscaped(StringBuffer sink, int unit) {
    sink.write(switch (unit) {
      0x08 => r'\b',
      0x09 => r'\t',
      0x0a => r'\n',
      0x0c => r'\f',
      0x0d => r'\r',
      _quote => r'\"',
      _backslash => r'\\',
      _ => '\\u${unit.toRadixString(16).padLeft(4, '0')}',
    });
  }
}
