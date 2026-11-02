import 'package:charcoal/charcoal.dart';
import 'package:test/test.dart';

void main() {
  group('DateTimeAdapter', () {
    const adapter = DateTimeAdapter();

    test('writes UTC, keeping the same instant from a local time', () {
      final local = DateTime(1965, 8, 1, 12, 30);
      final json = adapter.encode(local);

      expect(json, endsWith('Z'));
      expect(adapter.decode(json).isAtSameMomentAs(local), isTrue);
      expect(adapter.decode(json).isUtc, isTrue);
    });
  });

  test('DurationAdapter round trips whole microseconds', () {
    const adapter = DurationAdapter();
    const duration = Duration(seconds: 1, microseconds: 5);

    expect(adapter.encode(duration), 1000005);
    expect(adapter.decode(1000005), duration);
  });

  test('BigIntAdapter round trips beyond 64 bits', () {
    const adapter = BigIntAdapter();
    final big = BigInt.parse('123456789012345678901234567890');

    expect(adapter.encode(big), '123456789012345678901234567890');
    expect(adapter.decode(adapter.encode(big)), big);
  });

  test('UriAdapter round trips', () {
    const adapter = UriAdapter();
    final uri = Uri.parse('https://ace.com/a?b=c');

    expect(adapter.decode(adapter.encode(uri)), uri);
  });
}
