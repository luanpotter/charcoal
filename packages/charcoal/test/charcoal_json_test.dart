import 'dart:convert';
import 'dart:math';

import 'package:charcoal/charcoal.dart';
import 'package:test/test.dart';

String _written(String value) {
  final sink = StringBuffer();
  CharcoalJson.writeString(sink, value);
  return sink.toString();
}

void main() {
  group('writeString matches jsonEncode for', () {
    test('every code unit alone', () {
      for (var unit = 0; unit <= 0xffff; unit++) {
        final value = String.fromCharCode(unit);
        expect(_written(value), jsonEncode(value), reason: 'unit $unit');
      }
    });

    test('every code unit between plain text', () {
      for (var unit = 0; unit <= 0xffff; unit++) {
        final value = 'a${String.fromCharCode(unit)}b';
        expect(_written(value), jsonEncode(value), reason: 'unit $unit');
      }
    });

    test('surrogate pairs and lone surrogates', () {
      const values = [
        '\u{1F4D6}',
        'a\u{1F4D6}b',
        '\uD83D',
        '\uDCD6',
        '\uDCD6\uD83D',
        '\uD83D📖',
        '📖\uDCD6',
      ];
      for (final value in values) {
        expect(_written(value), jsonEncode(value));
      }
    });

    test('random strings around the escaped ranges', () {
      const units = [
        0x00, 0x08, 0x09, 0x0a, 0x0c, 0x0d, 0x1f, 0x20, 0x22, 0x27, 0x41, //
        0x5c, 0x5d, 0x7f, 0xe9, 0xd7ff, 0xd800, 0xdbff, 0xdc00, 0xdfff, 0xe000,
      ];
      final random = Random(1);
      for (var i = 0; i < 20000; i++) {
        final value = String.fromCharCodes([
          for (var j = random.nextInt(8); j > 0; j--)
            units[random.nextInt(units.length)],
        ]);
        expect(_written(value), jsonEncode(value), reason: 'run $i');
      }
    });
  });

  group('writeNumber', () {
    test('matches jsonEncode for finite numbers', () {
      for (final value in <num>[0, -1, 412, 4.5, 4.0, 1e21, 1e-7, 2.5e300]) {
        final sink = StringBuffer();
        CharcoalJson.writeNumber(sink, value);
        expect(sink.toString(), jsonEncode(value));
      }
    });

    test('refuses what jsonEncode refuses', () {
      for (final value in [double.nan, double.infinity, -double.infinity]) {
        expect(
          () => CharcoalJson.writeNumber(StringBuffer(), value),
          throwsA(isA<JsonUnsupportedObjectError>()),
        );
        expect(
          () => jsonEncode(value),
          throwsA(isA<JsonUnsupportedObjectError>()),
        );
      }
    });
  });

  group('decodeObject', () {
    test('decodes an object', () {
      expect(CharcoalJson.decodeObject('{"pages":1}'), {'pages': 1});
    });

    test('refuses anything else', () {
      expect(() => CharcoalJson.decodeObject('[1]'), throwsA(isA<TypeError>()));
    });
  });
}
