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
              contains(r'null => $d0,'),
              contains(r'$f0 = $d0;'),
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

    test('of null still drop a null', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book({this.title = null}) with BookCharcoal {
          final String? title;
        }
        ''',
        outputs: {output: decodedMatches(contains(r"'title': ?$it.title"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('that are not null keep a null with Omit.none', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.none)
        class Book({this.notes = 'none'}) with BookCharcoal {
          final String? notes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'notes': $it.notes"),
              contains(r"$json.containsKey('notes')"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('that are not null fail the build when a null could drop', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        class Book({this.notes = 'none'}) with BookCharcoal {
          final String? notes;
        }
        ''',
        'Book.notes defaults to a value that is not null',
      );
    });
  });

  group('Omit.empty', () {
    test('drops numbers at zero and empty collections', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        class Book({
          required this.title,
          this.pageCount = 0,
          this.rating = 0.0,
          this.tags = const [],
          this.prizes = const {},
          this.notes,
        }) with BookCharcoal {
          final String title;
          final int pageCount;
          final double rating;
          final List<String> tags;
          final Map<String, int> prizes;
          final String? notes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'title': $it.title"),
              contains(r"if ($it.pageCount != 0) 'pageCount': $it.pageCount"),
              contains(r"if ($it.rating != 0) 'rating': $it.rating"),
              contains(r"if ($it.tags.isNotEmpty) 'tags': $it.tags"),
              contains(r"if ($it.prizes.isNotEmpty) 'prizes': $it.prizes"),
              contains(r"'notes': ?$it.notes"),
              contains(r'if ($it.pageCount != 0) {'),
              contains(r'if ($it.tags.isNotEmpty) {'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('keeps strings and bools, whatever their default', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        class Book({
          this.title = '',
          this.isHardcover = false,
        }) with BookCharcoal {
          final String title;
          final bool isHardcover;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'title': $it.title"),
              contains(r"'isHardcover': $it.isHardcover"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fails the build on a required parameter it could drop', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        class Book({required this.tags}) with BookCharcoal {
          final List<String> tags;
        }
        ''',
        'Book.tags can be dropped by Omit.empty',
      );
    });

    test('fails the build on a default it could not bring back', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        class Book({this.pageCount = 1}) with BookCharcoal {
          final int pageCount;
        }
        ''',
        'Book.pageCount can be dropped by Omit.empty',
      );
    });
  });
}
