import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('copy', () {
    test('on an immutable class is the same instance', () async {
      final result = await build(
        '''
        $header
        @immutable
        @Charcoal()
        class Book(this.tags) with BookCharcoal {
          final List<String> tags;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('Book copy() => this as Book;'),
              isNot(contains(r'$copy(')),
              contains(r'Book(tags ?? _$it.tags)'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('rebuilds what it holds by its kind', () async {
      final result = await build(
        '''
        import 'dart:collection';
        $header
        enum Genre { fantasy }
        @immutable
        @Charcoal()
        class Author() with AuthorCharcoal;
        @Charcoal()
        class Details() with DetailsCharcoal;
        extension type Shelf(List<Details> books) {}
        extension type Id(int value) {}
        @Charcoal()
        class Book(
          this.id,
          this.genre,
          this.author,
          this.details,
          this.maybe,
          this.shelf,
          this.titles,
          this.quotes,
          this.genres,
          this.tags,
          this.parts,
          this.prizes,
          this.sorted,
        ) with BookCharcoal {
          final Id id;
          final Genre genre;
          final Author author;
          final Details details;
          final Details? maybe;
          final Shelf shelf;
          final List<String> titles;
          final Iterable<String> quotes;
          final Set<Genre> genres;
          final SplayTreeSet<String> tags;
          final List<Details> parts;
          final Map<String, Details> prizes;
          final SplayTreeMap<String, int> sorted;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'$it.id,'),
              contains(r'$it.genre,'),
              contains(r'$it.author,'),
              contains(r'DetailsCharcoal.$copy($it.details)'),
              contains(r'final $v0 => DetailsCharcoal.$copy($v0)'),
              contains(r'($it.shelf as List<Details>)'),
              contains(r'<String>[...$it.titles]'),
              contains(r'<String>[...$it.quotes]'),
              contains(r'<Genre>{...$it.genres}'),
              contains(r'SplayTreeSet<String>.of($it.tags)'),
              contains(
                r'<Details>[for (final $e0 in $it.parts) '
                r'DetailsCharcoal.$copy($e0)]',
              ),
              contains(
                r'for (final $e0 in $it.prizes.entries) '
                r'$e0.key: DetailsCharcoal.$copy($e0.value)',
              ),
              contains(r'SplayTreeMap<String, int>.of($it.sorted)'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('copyWith', () {
    const book =
        '''
      $header
      @immutable
      @Charcoal()
      class Book(this.title, {this.notes, this.quotes = const []})
          with BookCharcoal {
        final String title;
        final String? notes;
        final Iterable<String> quotes;
      }
    ''';

    test('is typed exactly as the fields', () async {
      final result = await build(
        book,
        outputs: {
          output: decodedMatches(
            allOf([
              contains(
                'Book Function({String title, String? notes, '
                'Iterable<String> quotes}) get copyWith',
              ),
              contains(r'String? title, Object? notes = _$keep'),
              contains(r'title ?? _$it.title'),
              contains(r'notes is _$Keep ? _$it.notes : notes as String?'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('declares the sentinel once, only if needed', () async {
      final needed = await build(
        '''
        $header
        @Charcoal()
        class Book(this.notes) with BookCharcoal {
          final String? notes;
        }
        @Charcoal()
        class Author(this.notes) with AuthorCharcoal {
          final String? notes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'const Object _$keep = _$Keep();'),
              isNot(
                matches(RegExp(r'const Object _\$keep[\s\S]*const Object')),
              ),
            ]),
          ),
        },
      );
      final unneeded = await build(
        '''
        $header
        @Charcoal()
        class Book(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {output: decodedMatches(isNot(contains(r'_$keep')))},
      );

      expect(needed.succeeded, isTrue);
      expect(unneeded.succeeded, isTrue);
    });

    test('takes no parameters on a class with no fields', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book() with BookCharcoal;
        ''',
        outputs: {
          output: decodedMatches(contains('Book Function() get copyWith')),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('allows a field named as what it could have shadowed', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book(this.identical) with BookCharcoal {
          final String? identical;
        }
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isTrue);
    });

    for (final (name, call) in const [
      ('null on a non-nullable field', 'book.copyWith(title: null)'),
      ('a wrong type', 'book.copyWith(title: 1)'),
      ('a wrong type on a nullable field', 'book.copyWith(notes: 1)'),
      ('an unknown name', 'book.copyWith(other: 1)'),
    ]) {
      test('refuses $name', () async {
        final result = await build(
          '''
          $book
          void use(Book book) => $call;
          ''',
          outputs: {output: anything},
        );

        expect(result.succeeded, isFalse);
        expect(
          result.errors.join('\n'),
          contains('Generated code fails to compile'),
        );
      });
    }
  });

  test('hand-written members win over the generated ones', () async {
    final result = await build(
      '''
      $header
      @Charcoal()
      class Book(this.title) with BookCharcoal {
        final String title;

        @override
        Book copy() => this;
      }
      void use(Book book) => book.copy();
      ''',
      outputs: {output: anything},
    );

    expect(result.succeeded, isTrue);
  });
}
