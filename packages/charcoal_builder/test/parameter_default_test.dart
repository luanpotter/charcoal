import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('parameter defaults', () {
    test('come from a typed constant', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book({
          this.pageCount = 1,
          this.tags = const [],
        }) with BookCharcoal {
          final int pageCount;
          final List<String> tags;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'static const int $d0 = 1;'),
              contains(r'static const List<String> $d1 = const [];'),
              contains(r"$json.containsKey('pageCount') ?"),
              contains(r'int? $f0 = $d0;'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('qualify static members of the class', () async {
      final result = await build(
        '''
        $header
        class Other {
          static const first = 'other';
        }
        @Charcoal()
        class Book({
          this.a = first,
          this.b = Book.first,
          this.c = const [first, Other.first],
          this.d = 'first \$first \${first}',
          this.e = first == 'x',
          this.f = first.length,
        }) with BookCharcoal {
          static const first = 'book';
          final String a;
          final String b;
          final List<String> c;
          final String d;
          final bool e;
          final int f;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'static const String $d0 = Book.first;'),
              contains(r'static const String $d1 = Book.first;'),
              contains(
                r'static const List<String> $d2 = '
                'const [Book.first, Other.first];',
              ),
              contains(
                r'static const String $d3 = '
                r"'first ${Book.first} ${Book.first}';",
              ),
              contains(r"static const bool $d4 = Book.first == 'x';"),
              contains(r'static const int $d5 = Book.first.length;'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('keep a null when the default is not null', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book({
          this.notes = 'none',
          this.title = null,
        }) with BookCharcoal {
          final String? notes;
          final String? title;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'notes': $it.notes"),
              contains(r"'title': ?$it.title"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('allow dropping only an empty default with Omit.empty', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        class Book({
          this.title = '',
          this.tags = const [],
          this.subtitle = 'none',
          this.pageCount = 0,
          required this.notes,
        }) with BookCharcoal {
          final String title;
          final List<String> tags;
          final String subtitle;
          final int pageCount;
          final String notes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"if ($it.title.isNotEmpty) 'title': $it.title"),
              contains(r"if ($it.tags.isNotEmpty) 'tags': $it.tags"),
              contains(r"'subtitle': $it.subtitle"),
              contains(r"'pageCount': $it.pageCount"),
              contains(r"'notes': $it.notes"),
              contains(r'if ($it.title.isNotEmpty) {'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });
}
