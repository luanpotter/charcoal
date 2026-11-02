const int _quote = 0x22;
const int _backslash = 0x5c;
const int _comma = 0x2c;
const int _colon = 0x3a;
const int _minus = 0x2d;
const int _plus = 0x2b;
const int _dot = 0x2e;
const int _zero = 0x30;
const int _nine = 0x39;
const int _space = 0x20;
const int _openBrace = 0x7b;
const int _closeBrace = 0x7d;
const int _openBracket = 0x5b;
const int _closeBracket = 0x5d;
const int _maxSafeDigits = 18;

/// Reads JSON directly into generated classes, building no intermediate map.
///
/// It accepts and refuses exactly what `jsonDecode` does.
final class CharcoalJsonReader(this._source) {
  final String _source;
  int _index = 0;

  /// Starts an object, returning whether it has any field.
  bool enterObject() => _enter(_openBrace, _closeBrace);

  /// Reads a key and its colon, returning its index in [keys], or -1.
  ///
  /// Checks first for [expected], as keys usually come in the same order.
  int readField(List<String> keys, int expected) {
    _skipWhitespace();
    if (expected < keys.length) {
      final key = keys[expected];
      final end = _index + key.length + 1;
      if (_isQuoteAt(_index) &&
          _source.startsWith(key, _index + 1) &&
          _isQuoteAt(end)) {
        _index = end + 1;
        _expect(_colon);
        return expected;
      }
    }
    return keys.indexOf(readKey());
  }

  /// Reads a key and its colon.
  String readKey() {
    final key = readString();
    _expect(_colon);
    return key;
  }

  /// Finds a string field of the object ahead, leaving the reader where it was.
  ///
  /// It is the first field in what charcoal writes, so nothing else gets read.
  String peekStringField(String key) {
    final start = _index;
    if (enterObject()) {
      do {
        if (readKey() == key) {
          final value = readString();
          _index = start;
          return value;
        }
        skipValue();
      } while (nextInObject());
    }
    _fail();
  }

  /// Moves past a comma, or the end of the object, returning if it continues.
  bool nextInObject() => _next(_closeBrace);

  /// Starts an array, returning whether it has any element.
  bool enterArray() => _enter(_openBracket, _closeBracket);

  /// Moves past a comma, or the end of the array, returning if it continues.
  bool nextInArray() => _next(_closeBracket);

  /// Reads a string, without copying more than its own content.
  String readString() {
    _expect(_quote);
    final start = _index;
    while (_index < _source.length) {
      final unit = _source.codeUnitAt(_index);
      if (unit == _quote) {
        return _source.substring(start, _index++);
      }
      if (unit == _backslash) {
        return _readEscapedString(start);
      }
      if (unit < _space) {
        _fail();
      }
      _index++;
    }
    _fail();
  }

  /// Reads an integer, refusing a double even if it has no decimal part.
  int readInt() {
    final value = readNum();
    return value is int ? value : _fail();
  }

  /// Reads a number, turning it into a double if it is written as an integer.
  double readDouble() => readNum().toDouble();

  /// Reads a number as `jsonDecode` would, as an `int` or as a `double`.
  num readNum() {
    _skipWhitespace();
    final start = _index;
    final isNegative = _isAt(_minus);
    if (isNegative) {
      _index++;
    }

    final digitsStart = _index;
    var integer = 0;
    while (_isDigitAt(_index)) {
      integer = integer * 10 + _source.codeUnitAt(_index) - _zero;
      _index++;
    }
    final digits = _index - digitsStart;
    final hasLeadingZero =
        digits > 1 && _source.codeUnitAt(digitsStart) == _zero;
    if (digits == 0 || hasLeadingZero) {
      _fail();
    }

    final isInteger = !_readFraction() & !_readExponent();
    if (!isInteger) {
      return double.parse(_source.substring(start, _index));
    }
    if (digits > _maxSafeDigits) {
      return num.parse(_source.substring(start, _index));
    }
    return isNegative ? -integer : integer;
  }

  /// Reads `true` or `false`.
  bool readBool() {
    if (_skipLiteral('true')) {
      return true;
    }
    return _skipLiteral('false') ? false : _fail();
  }

  /// Moves past a `null`, returning whether there was one.
  bool tryReadNull() => _skipLiteral('null');

  /// Moves past any value, refusing it if it is malformed.
  void skipValue() {
    _skipWhitespace();
    if (_index >= _source.length) {
      _fail();
    }
    switch (_source.codeUnitAt(_index)) {
      case _openBrace:
        if (enterObject()) {
          do {
            readKey();
            skipValue();
          } while (nextInObject());
        }
      case _openBracket:
        if (enterArray()) {
          do {
            skipValue();
          } while (nextInArray());
        }
      case _quote:
        readString();
      default:
        if (!_skipLiteral('true') &&
            !_skipLiteral('false') &&
            !_skipLiteral('null')) {
          readNum();
        }
    }
  }

  /// Refuses anything left after the value.
  void finish() {
    _skipWhitespace();
    if (_index < _source.length) {
      _fail();
    }
  }

  /// Refuses a value that has the wrong shape for its field.
  Never _fail() {
    throw FormatException('Unexpected character', _source, _index);
  }

  void _skipWhitespace() {
    while (_index < _source.length) {
      final unit = _source.codeUnitAt(_index);
      if (unit != _space && unit != 0x0a && unit != 0x0d && unit != 0x09) {
        return;
      }
      _index++;
    }
  }

  bool _isAt(int unit) => _isUnitAt(_index, unit);

  bool _isQuoteAt(int index) => _isUnitAt(index, _quote);

  bool _isUnitAt(int index, int unit) {
    return index < _source.length && _source.codeUnitAt(index) == unit;
  }

  bool _isDigitAt(int index) {
    if (index >= _source.length) {
      return false;
    }
    final unit = _source.codeUnitAt(index);
    return unit >= _zero && unit <= _nine;
  }

  void _expect(int unit) {
    _skipWhitespace();
    if (!_isAt(unit)) {
      _fail();
    }
    _index++;
  }

  bool _enter(int open, int close) {
    _expect(open);
    _skipWhitespace();
    if (_isAt(close)) {
      _index++;
      return false;
    }
    return true;
  }

  bool _next(int close) {
    _skipWhitespace();
    if (_isAt(_comma)) {
      _index++;
      return true;
    }
    if (_isAt(close)) {
      _index++;
      return false;
    }
    _fail();
  }

  bool _skipLiteral(String literal) {
    _skipWhitespace();
    if (!_source.startsWith(literal, _index)) {
      return false;
    }
    _index += literal.length;
    return true;
  }

  bool _readFraction() {
    if (!_isAt(_dot)) {
      return false;
    }
    _index++;
    _readDigits();
    return true;
  }

  bool _readExponent() {
    if (_index >= _source.length || _source.codeUnitAt(_index) | 0x20 != 0x65) {
      return false;
    }
    _index++;
    if (_isAt(_plus) || _isAt(_minus)) {
      _index++;
    }
    _readDigits();
    return true;
  }

  void _readDigits() {
    if (!_isDigitAt(_index)) {
      _fail();
    }
    while (_isDigitAt(_index)) {
      _index++;
    }
  }

  String _readEscapedString(int start) {
    final buffer = StringBuffer(_source.substring(start, _index));
    while (_index < _source.length) {
      final unit = _source.codeUnitAt(_index++);
      if (unit == _quote) {
        return buffer.toString();
      }
      if (unit < _space) {
        _fail();
      }
      buffer.writeCharCode(unit == _backslash ? _readEscape() : unit);
    }
    _fail();
  }

  int _readEscape() {
    if (_index >= _source.length) {
      _fail();
    }
    return switch (_source.codeUnitAt(_index++)) {
      _quote => _quote,
      _backslash => _backslash,
      0x2f => 0x2f,
      0x62 => 0x08,
      0x66 => 0x0c,
      0x6e => 0x0a,
      0x72 => 0x0d,
      0x74 => 0x09,
      0x75 => _readUnicodeEscape(),
      _ => _fail(),
    };
  }

  int _readUnicodeEscape() {
    var unit = 0;
    for (var i = 0; i < 4; i++) {
      if (_index >= _source.length) {
        _fail();
      }
      final digit = _hexValue(_source.codeUnitAt(_index++));
      unit = unit * 16 + digit;
    }
    return unit;
  }

  int _hexValue(int unit) {
    if (unit >= _zero && unit <= _nine) {
      return unit - _zero;
    }
    final lower = unit | 0x20;
    return lower >= 0x61 && lower <= 0x66 ? lower - 0x61 + 10 : _fail();
  }
}
