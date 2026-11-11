import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('a plain parameter', () {
    test('decodes as the parameter, and encodes as the field', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book({List<String>? tags}) with BookCharcoal {
          final List<String> tags = tags ?? [];
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'tags': $it.tags"),
              isNot(contains(r"'tags': ?$it.tags")),
              contains(r'final $v => ['),
              contains(r'List<String>? $f0;'),
              contains(r'Book(tags: $s.$f0)'),
              contains('Book Function({List<String> tags}) get copyWith'),
              contains('({List<String>? tags}) =>'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('reads a getter over a private field', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(int pageCount) with BookCharcoal {
          int _pageCount = pageCount;
          int get pageCount => _pageCount;
          set pageCount(int value) => _pageCount = value;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'pageCount': $it.pageCount"),
              contains(r"Book($json['pageCount'] as int)"),
              isNot(contains('_pageCount')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('of a factory goes through it, on decode and copy', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book._(this.title) with BookCharcoal {
          final String title;
          factory Book(String title) => Book._(title.trim());
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"Book($json['title'] as String)"),
              contains(r'Book($it.title)'),
              isNot(contains('Book._')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can read a field up the chain', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        sealed class Edition(this.year) with EditionCharcoal {
          final int year;
        }
        final class Ebook._(super.year) extends Edition with EbookCharcoal {
          factory Ebook(int year) => Ebook._(year);
        }
        ''',
        outputs: {
          output: decodedMatches(contains(r"'year': $it.year")),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the type of each use in a generic class', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        @Charcoal()
        final class Box<T>({List<T>? items}) with BoxCharcoal<T> {
          final List<T> items = items ?? [];
        }
        @Charcoal()
        final class Book(this.box) with BookCharcoal {
          final Box<Genre> box;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'static Box<Genre> $decode('),
              contains(r'EnumName($e0).name'),
              contains(r'List<Genre>? $f0;'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can skip the Omit.empty check, made in an initializer', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        final class Book({List<String>? tags}) with BookCharcoal {
          final List<String> tags = tags ?? [];
        }
        ''',
        outputs: {
          output: decodedMatches(
            contains(r"if ($it.tags.isNotEmpty) 'tags': $it.tags"),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('fails the build on', () {
    test('a member a copy could not pass back', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book(int pageCount) with BookCharcoal {
          String get pageCount => '';
        }
        ''',
        'Book.pageCount is a int, but reading it back gives a String',
      );
    });

    test('a private field with no getter over it', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book(this.title) with BookCharcoal {
          final String title;
          final int _other = 0;
        }
        ''',
        'Book._other is not a constructor parameter of Book',
      );
    });

    test('a private field whose getter has no parameter', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal {
          final int _other = 0;
          int get other => _other;
        }
        ''',
        'Book._other is not a constructor parameter of Book',
      );
    });

    test('a parameter of a type it cannot serialize', () async {
      await expectBuildError(
        '''
        $header
        class Publisher {}
        @Charcoal()
        final class Book(Publisher? publisher) with BookCharcoal {
          final Publisher publisher = publisher ?? Publisher();
        }
        ''',
        'Book.publisher is a Publisher',
      );
    });
  });
}
