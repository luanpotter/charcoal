import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('a class marked @immutable', () {
    test('compares by value, cheapest first', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        @immutable
        @Charcoal()
        final class Book(this.tags, this.title, this.genre, this.pageCount)
            with BookCharcoal {
          final List<String> tags;
          final String title;
          final Genre genre;
          final int pageCount;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('bool operator ==(Object'),
              contains('int get hashCode'),
              isNot(contains('contentEquals')),
              contains(r'if (!identical($a.genre, $b.genre)) return false;'),
              contains(r'$h = CharcoalHash.mix($h, $it.genre.index);'),
              matches(
                RegExp(
                  r'\$a\.pageCount[\s\S]*\$a\.title[\s\S]*\$a\.tags\.length',
                ),
              ),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can inherit the annotation', () async {
      final result = await build(
        '''
        $header
        @immutable
        class Publication {}
        @Charcoal()
        final class Book() with BookCharcoal implements Publication;
        ''',
        outputs: {output: decodedMatches(contains('operator =='))},
      );

      expect(result.succeeded, isTrue);
    });

    test('fails the build holding a class that is not', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Author() with AuthorCharcoal;
        @immutable
        @Charcoal()
        final class Book(this.authors) with BookCharcoal {
          final List<Author?> authors;
        }
        ''',
        'Book.authors holds a Author, which is not @immutable',
      );
    });
  });

  group('any other class', () {
    test('keeps identity, even with every field final', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'bool contentEquals(Book $other)'),
              contains('int get contentHash'),
              isNot(contains('operator ==')),
              isNot(contains('get hashCode')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('compares what it holds by its kind', () async {
      final result = await build(
        '''
        $header
        @immutable
        @Charcoal()
        final class Author() with AuthorCharcoal;
        @Charcoal()
        final class Details() with DetailsCharcoal;
        extension type Shelf(List<Details> books) {}
        @Charcoal()
        final class Book(
          this.author,
          this.details,
          this.maybe,
          this.shelf,
          this.quotes,
          this.tags,
          this.prizes,
        ) with BookCharcoal {
          final Author author;
          final Details details;
          final Details? maybe;
          final Shelf shelf;
          final Iterable<String> quotes;
          final Set<String> tags;
          final Map<String, Details?> prizes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'if ($a.author != $b.author) return false;'),
              contains(r'DetailsCharcoal.$equals($a.details, $b.details)'),
              contains(r'if ($a.maybe case final $v0?) {'),
              contains(r'($a.shelf as List<Details>)'),
              contains(r'final $x0 = $a.quotes.iterator;'),
              contains(r'if (!$b.tags.contains($e0)) return false;'),
              contains(r'final $o0 = $b.prizes[$e0.key] as Details?;'),
              contains(r'$c0 ^= CharcoalHash.finish($t0);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fails the build on a set of what compares by identity', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Author() with AuthorCharcoal;
        @Charcoal()
        final class Book(this.authors) with BookCharcoal {
          final Set<Author> authors;
        }
        ''',
        'Book.authors has a Set of values that do not compare by value',
      );
    });

    test('fails the build on a set of collections', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book(this.parts) with BookCharcoal {
          final List<Set<List<int>>> parts;
        }
        ''',
        'Book.parts has a Set of values that do not compare by value',
      );
    });
  });

  group('hand-written members', () {
    test('win over the generated ones', () async {
      final result = await build(
        '''
        $header
        @immutable
        @Charcoal()
        final class Book(this.id) with BookCharcoal {
          final int id;

          @override
          bool operator ==(Object other) => other is Book && other.id == id;

          @override
          int get hashCode => id;

          @override
          String toString() => 'Book';
        }
        ''',
        outputs: {output: decodedMatches(contains('mixin BookCharcoal'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('fail the build with == and no hashCode', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal {
          @override
          bool operator ==(Object other) => other is Book;
        }
        ''',
        'Book must define both == and hashCode, or neither.',
      );
    });

    test('fail the build with hashCode and no ==', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal {
          @override
          int get hashCode => 1;
        }
        ''',
        'Book must define both == and hashCode, or neither.',
      );
    });
  });

  test('toString names every field, escaping a dollar', () async {
    final result = await build(
      '''
      $header
      @Charcoal()
      final class Book(this.title, this.\$id) with BookCharcoal {
        final String title;
        final int \$id;
      }
      ''',
      outputs: {
        output: decodedMatches(
          contains(r"'Book(title: ${$it.title}, \$id: ${$it.$id})'"),
        ),
      },
    );

    expect(result.succeeded, isTrue);
  });
}
