import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('direct writer', () {
    test('merges adjacent literals', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.title, this.pageCount) with BookCharcoal {
          final String title;
          final int pageCount;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r'''$sink.write('{"title":');'''),
              contains(r'''$sink.write(',"pageCount":');'''),
              isNot(contains(r'$comma')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('writes an empty class as one literal', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal;
        ''',
        outputs: {output: decodedMatches(contains(r"$sink.write('{}');"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('needs no flag when a later field is certain', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.notes, this.title, this.subtitle) with BookCharcoal {
          final String? notes;
          final String title;
          final String? subtitle;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r"$sink.write(',');"),
              contains(r'''$sink.write('"title":');'''),
              contains(r'''$sink.write(',"subtitle":');'''),
              isNot(contains(r'$comma')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('needs no flag for a single droppable field', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.notes) with BookCharcoal {
          final String? notes;
        }
        ''',
        outputs: {output: decodedMatches(isNot(contains(r'$comma')))},
      );

      expect(result.succeeded, isTrue);
    });

    test('uses a flag only when every field may drop', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.notes, this.subtitle) with BookCharcoal {
          final String? notes;
          final String? subtitle;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r'var $comma = false;'),
              contains(r"if ($comma) $sink.write(',');"),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('escapes a dollar in a key', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.\$count) with BookCharcoal {
          final int \$count;
        }
        ''',
        outputs: {output: decodedMatches(contains(r'''{"\$count":'''))},
      );

      expect(result.succeeded, isTrue);
    });
  });
}
