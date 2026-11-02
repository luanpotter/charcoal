import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('collections', () {
    test('pass through what JSON holds, using an index for lists', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.parts, this.titles) with BookCharcoal {
          final List<String?> parts;
          final Map<String, String> titles;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'parts': $it.parts"),
              contains(r"'titles': $it.titles"),
              contains(r'for (var $i0 = 0; $i0 < $it.parts.length; $i0++)'),
              contains(r'$json['),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('convert sets and anything holding enums or classes', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        @Charcoal()
        final class Book(this.tags, this.genres, this.sequels) with BookCharcoal {
          final Set<String> tags;
          final List<Genre> genres;
          final Map<String, Book> sequels;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'tags': [for (final $e0 in $it.tags) $e0]"),
              contains(r'[for (final $e0 in $it.genres) EnumName($e0).name]'),
              contains(r'$e0.key: BookCharcoal.$encode($e0.value)'),
              contains(r'for (final $e0 in $it.sequels.entries) {'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('use a new name at each depth', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        @Charcoal()
        final class Book(this.shelves) with BookCharcoal {
          final List<List<Genre>> shelves;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'[for (final $e1 in $e0) EnumName($e1).name]'),
              contains(r'EnumName($it.shelves[$i0][$i1]).name'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('build anything else through its of constructor', () async {
      final result = await build(
        '''
        import 'dart:collection';
        $header
        @Charcoal()
        final class Book(this.tags, this.pages, this.awards) with BookCharcoal {
          final SplayTreeSet<String> tags;
          final SplayTreeMap<String, int> pages;
          final Iterable<String> awards;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('SplayTreeSet.of([for'),
              contains('SplayTreeMap.of({for'),
              contains(r"[for (final $e0 in $json['awards'] as List<Object?>)"),
              contains(r"'tags': [for (final $e0 in $it.tags) $e0]"),
              contains(r"'pages': $it.pages"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('allow enum map keys', () async {
      final result = await build(
        '''
        $header
        enum Language { english }
        @Charcoal()
        final class Book(this.titles) with BookCharcoal {
          final Map<Language, String> titles;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'EnumName($e0.key).name: $e0.value'),
              contains(r'Language.values.byName($e0.key):'),
              contains(r'$sink.write(EnumName($e0.key).name);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('allow int map keys, as strings in JSON', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.awards) with BookCharcoal {
          final Map<int, String> awards;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'$e0.key.toString(): $e0.value'),
              contains(r'int.parse($e0.key):'),
              contains(r'int.parse($r.readKey())'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('allow map keys of extension types over those', () async {
      final result = await build(
        '''
        $header
        extension type Id(int value) {}
        extension type Isbn(String value) {}
        @Charcoal()
        final class Book(this.byId, this.byIsbn) with BookCharcoal {
          final Map<Id, String> byId;
          final Map<Isbn, String> byIsbn;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'($e0.key as int).toString(): $e0.value'),
              contains(r'(int.parse($e0.key)) as Id:'),
              contains(r"'byIsbn': $it.byIsbn"),
              contains(r'($e0.key) as Isbn:'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fail the build without a usable of constructor', () async {
      final result = await build('''
        import 'dart:collection' show UnmodifiableListView;
        import 'dart:collection' as c;
        $header
        @Charcoal()
        final class Book(this.a, this.b) with BookCharcoal {
          final UnmodifiableListView<String> a;
          final c.SplayTreeSet<String> b;
        }
        ''');

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      expect(errors, contains('Book.a is a'));
      expect(errors, contains('Book.b is a'));
    });

    test('fail the build on anything unsupported inside', () async {
      final result = await build('''
        $header
        class Publisher {}
        @Charcoal()
        final class Book(
          this.a, this.b, this.c, this.d, this.e, this.f,
        ) with BookCharcoal {
          final List a;
          final List<Object> b;
          final Set<Publisher> c;
          final Map<double, String> d;
          final Map<String?, String> e;
          final List<List<Publisher>> f;
        }
        ''');

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      for (final field in 'abcdef'.split('')) {
        expect(errors, contains('Book.$field is a'));
      }
    });
  });
}
