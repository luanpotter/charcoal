import 'package:charcoal/charcoal.dart';
import 'package:test/test.dart';

void main() {
  group('peekStringField', () {
    test('finds the first field, or any other', () {
      expect(CharcoalJsonReader('{"a":"x"}').peekStringField('a'), 'x');
      expect(
        CharcoalJsonReader(' { "b" : [{}] , "a" : "x" } ').peekStringField('a'),
        'x',
      );
    });

    test('leaves the reader where it was', () {
      final reader = CharcoalJsonReader(' {"b":1,"a":"x"}');

      reader.peekStringField('a');

      expect(reader.enterObject(), isTrue);
      expect(reader.readKey(), 'b');
    });

    test('refuses a missing field, a wrong type or malformed JSON', () {
      for (final source in [
        '{}',
        '{"b":1}',
        '{"a":1}',
        '{"b":01,"a":"x"}',
        '[]',
      ]) {
        expect(
          () => CharcoalJsonReader(source).peekStringField('a'),
          throwsFormatException,
        );
      }
    });
  });
}
