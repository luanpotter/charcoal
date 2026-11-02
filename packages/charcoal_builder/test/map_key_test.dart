import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('an adapted map key', () {
    test('goes through its adapter, escaped as any string', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.runs) with BookCharcoal {
          final Map<DateTime, int> runs;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'const DateTimeAdapter().encode($e0.key): $e0.value'),
              contains(r'const DateTimeAdapter().decode($e0.key):'),
              contains(r'const DateTimeAdapter().decode($r.readKey())'),
              contains(
                r'CharcoalJson.writeString($sink, '
                r'const DateTimeAdapter().encode($e0.key));',
              ),
              contains('<DateTime, int>{};'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('takes precedence over what the type would do', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        final class const GenreAdapter()
            implements CharcoalAdapter<Genre, String> {
          @override
          String encode(Genre value) => 'genre';

          @override
          Genre decode(String json) => Genre.fantasy;
        }
        @Charcoal()
        final class Book(this.counts) with BookCharcoal {
          final Map<Genre, int> counts;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('const GenreAdapter().encode'),
              isNot(contains('EnumName')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fails the build if its adapter does not write a string', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book(this.runs) with BookCharcoal {
          final Map<Duration, int> runs;
        }
        ''',
        'A Duration cannot be a map key, as const DurationAdapter() does not '
            'write a String',
      );
    });

    test('fails the build without an adapter', () async {
      await expectBuildError(
        '''
        import 'package:charcoal/charcoal.dart' hide DateTimeAdapter;
        part 'book.charcoal.g.dart';
        @Charcoal()
        final class Book(this.runs) with BookCharcoal {
          final Map<DateTime, int> runs;
        }
        ''',
        'Book.runs is a Map<DateTime, int>',
      );
    });
  });
}
