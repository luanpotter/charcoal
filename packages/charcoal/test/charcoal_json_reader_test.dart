// cspell:ignore udcd Etrufalsn
import 'dart:convert';
import 'dart:math';

import 'package:charcoal/charcoal.dart';
import 'package:test/test.dart';

const _b = r'\';

const _valid = [
  '{}',
  '[]',
  '"a"',
  '""',
  '0',
  '-0',
  '1',
  '-1',
  '1.5',
  '-1.5',
  '0.0',
  '1e2',
  '1E2',
  '1e+2',
  '1e-2',
  '1.5e300',
  '1e999',
  '-1e999',
  '999999999999999999',
  '9223372036854775807',
  '9223372036854775808',
  '-9223372036854775808',
  '123456789012345678901234567890',
  'true',
  'false',
  'null',
  ' \t\r\n{ "a" : [ 1 , 2 ] } \t\r\n',
  '{"a":{"b":[{"c":null}]},"d":"e","a":1}',
  r'"\"\\\/\b\f\n\r\t"',
  '"${_b}u00e9${_b}u00E9"',
  '"${_b}ud83d${_b}udcd6"',
  r'"\ud83d"',
  '"\u{1F4D6}é"',
  '"\u007f"',
];

const _invalid = [
  '',
  ' ',
  '{',
  '}',
  '[',
  ']',
  '"',
  '"a',
  r'"\',
  r'"\x"',
  r'"\u12"',
  r'"\u123g"',
  '"\n"',
  '"\u0000"',
  '01',
  '-',
  '-01',
  '+1',
  '.5',
  '1.',
  '1.e2',
  '1e',
  '1e+',
  'NaN',
  'Infinity',
  'tru',
  'nul',
  'True',
  '{,}',
  '[,]',
  '[1,]',
  '{"a":1,}',
  '{"a"}',
  '{"a":}',
  '{a:1}',
  '{1:1}',
  '[1 2]',
  '{"a":1 "b":2}',
  '1 2',
  '{}{}',
  '[]]',
  '\u{a0}{}',
  ' {}',
];

bool _jsonDecodeAccepts(String source) {
  try {
    jsonDecode(source);
    return true;
  } on FormatException {
    return false;
  }
}

bool _readerAccepts(String source) {
  try {
    CharcoalJsonReader(source)
      ..skipValue()
      ..finish();
    return true;
  } on FormatException {
    return false;
  }
}

void main() {
  group('accepts exactly what jsonDecode does for', () {
    for (final source in [..._valid, ..._invalid]) {
      test(jsonEncode(source), () {
        expect(_readerAccepts(source), _jsonDecodeAccepts(source));
      });
    }

    test('mutations of valid JSON', () {
      final random = Random(1);
      const alphabet = '{}[]",:\\/ \n0123456789-+.eEtrufalsn';
      for (var run = 0; run < 50000; run++) {
        final base = _valid[random.nextInt(_valid.length)];
        final at = random.nextInt(base.length + 1);
        final unit = alphabet[random.nextInt(alphabet.length)];
        final source = random.nextBool()
            ? base.replaceRange(at, at, unit)
            : base.replaceRange(at, min(at + 1, base.length), unit);
        expect(
          _readerAccepts(source),
          _jsonDecodeAccepts(source),
          reason: source,
        );
      }
    });
  });

  group('reads the same value as jsonDecode for', () {
    test('every number', () {
      for (final source in _valid) {
        final expected = jsonDecode(source);
        if (expected is num) {
          final actual = CharcoalJsonReader(source).readNum();
          expect(actual, expected, reason: source);
          expect(actual.runtimeType, expected.runtimeType, reason: source);
          expect(actual.isNegative, expected.isNegative, reason: source);
        }
      }
    });

    test('every string', () {
      for (final source in _valid) {
        final expected = jsonDecode(source);
        if (expected is String) {
          expect(CharcoalJsonReader(source).readString(), expected);
        }
      }
    });

    test('random strings around the escaped ranges', () {
      const units = [
        0x08,
        0x09,
        0x0a,
        0x1f,
        0x20,
        0x22,
        0x41,
        0x5c,
        0xe9,
        0xd83d,
        0xdcd6,
      ];
      final random = Random(1);
      for (var run = 0; run < 20000; run++) {
        final value = String.fromCharCodes([
          for (var i = random.nextInt(8); i > 0; i--)
            units[random.nextInt(units.length)],
        ]);
        expect(CharcoalJsonReader(jsonEncode(value)).readString(), value);
      }
    });
  });

  group('readInt', () {
    test('refuses what is not an integer', () {
      for (final source in ['1.0', '1e2', '9223372036854775808', '"1"']) {
        expect(
          () => CharcoalJsonReader(source).readInt(),
          throwsFormatException,
          reason: source,
        );
      }
    });
  });

  group('readDouble', () {
    test('accepts an integer', () {
      expect(CharcoalJsonReader('4').readDouble(), 4.0);
    });
  });

  group('readBool', () {
    test('refuses anything else', () {
      expect(() => CharcoalJsonReader('1').readBool(), throwsFormatException);
    });
  });

  group('readField', () {
    const keys = ['title', 'pageCount'];

    int read(String source, int expected) {
      return (CharcoalJsonReader(source)..enterObject()).readField(
        keys,
        expected,
      );
    }

    test('finds the expected key', () {
      expect(read('{"title":1}', 0), 0);
    });

    test('finds a key that was not expected', () {
      expect(read('{"title":1}', 1), 0);
      expect(read('{"title":1}', 2), 0);
    });

    test('finds an escaped key', () {
      expect(read('{"ti${_b}u0074le":1}', 0), 0);
    });

    test('does not stop at a key that only starts the same', () {
      expect(read('{"titles":1}', 0), -1);
    });

    test('returns -1 for an unknown key', () {
      expect(read('{"other":1}', 0), -1);
    });

    test('allows whitespace around the colon', () {
      expect(read('{ "title" : 1}', 0), 0);
    });

    test('refuses a missing colon', () {
      expect(() => read('{"title" 1}', 0), throwsFormatException);
    });
  });
}
