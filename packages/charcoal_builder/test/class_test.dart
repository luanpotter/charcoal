import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('generates', () {
    const book =
        '''
      $header
      @Charcoal()
      final class Book({required this.title, required this.rating, this.notes})
          with BookCharcoal {
        final String title;
        final double rating;
        final double? notes;
      }
      ''';

    test('a formatted part with a header', () async {
      final result = await build(
        book,
        outputs: {
          output: decodedMatches(
            allOf(
              startsWith('// dart format width=120\n'),
              contains('// GENERATED CODE'),
              contains("part of 'book.dart';"),
              contains('mixin BookCharcoal {'),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('an encoder, dropping nulls', () async {
      final result = await build(
        book,
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r'toMap() => $encode(this as Book);'),
              contains(r"'title': $it.title"),
              contains(r"'notes': ?$it.notes"),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('a decoder, converting doubles', () async {
      final result = await build(
        book,
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r"title: $json['title'] as String"),
              contains(r"rating: ($json['rating'] as num).toDouble()"),
              contains(r'final $v => ($v as num).toDouble()'),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('positional parameters and a named primary constructor', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book.of(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {output: decodedMatches(contains(r"Book.of($json['title']"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('one mixin per annotated class, skipping others', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal;
        class Publisher {}
        @Charcoal()
        final class Author() with AuthorCharcoal;
        ''',
        outputs: {
          output: decodedMatches(
            allOf(
              contains('mixin BookCharcoal'),
              contains('mixin AuthorCharcoal'),
              isNot(contains('PublisherCharcoal')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('only constructor fields, leaving derived ones out', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.title) with BookCharcoal {
          static const shelfLife = 1;
          final String title;
          late final int length = title.length;
          String get upper => title.toUpperCase();
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf(
              contains(r"'title': $it.title"),
              isNot(contains('shelfLife')),
              isNot(contains('length')),
              isNot(contains('upper')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('generates nothing for', () {
    test('a library without annotated classes', () async {
      final result = await build('class Book {}');

      expect(result.succeeded, isTrue);
    });

    test('another annotation named Charcoal', () async {
      final result = await build('''
        class Charcoal {
          const Charcoal();
        }
        @Charcoal()
        final class Book {}
        ''');

      expect(result.succeeded, isTrue);
    });

    test('part files', () async {
      final result = await build(
        "part 'publisher.dart';",
        assets: {'package_name|lib/publisher.dart': "part of 'book.dart';"},
      );

      expect(result.succeeded, isTrue);
    });
  });
}
