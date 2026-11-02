import 'dart:collection';

import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/publisher.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _author = Author(penName: null, name: 'Frank Herbert');

BookDetails _details({
  List<List<String>> chapterTitles = const [
    ['Dune'],
  ],
  Set<Genre> relatedGenres = const {Genre.fantasy, Genre.sciFi},
  Iterable<String> tags = const ['classic', 'desert'],
  Map<int, String> awardsByYear = const {1966: 'Hugo', 1965: 'Nebula'},
  Map<Language, Translation>? translations = const {
    Language.portuguese: Translation(title: 'Duna', translator: _author),
  },
}) {
  return BookDetails(
    partTitles: const ['One', null],
    chapterTitles: chapterTitles,
    otherAuthors: const [_author],
    relatedGenres: relatedGenres,
    tags: SplayTreeSet.of(tags),
    pageCountByChapter: SplayTreeMap.of({'a': 1}),
    relatedBookIds: const [],
    quotes: const ['q'],
    awardsByYear: awardsByYear,
    translations: translations,
    reprintDates: [DateTime.utc(1965, 8)],
  );
}

Book _book({BookDetails? details}) {
  return Book(
    title: 'Dune',
    pageCount: 420,
    rating: 4.5,
    isHardcover: true,
    genre: Genre.sciFi,
    author: _author,
    details: details,
  );
}

void main() {
  group('an immutable class', () {
    test('compares by value', () {
      final name = ['Frank', 'Herbert'].join(' ');
      final other = Author(penName: null, name: name);

      expect(identical(other, _author), isFalse);
      expect(other, _author);
      expect(other.hashCode, _author.hashCode);
    });

    test('tells apart any field', () {
      const author = Author(penName: 'Pen', name: 'Frank Herbert');

      expect(author, isNot(_author));
      expect(author.hashCode, isNot(_author.hashCode));
    });

    test('compares through nested classes and collections', () {
      Translation translation(String name) {
        return Translation(
          title: 'Duna',
          translator: _author,
          reviewers: [Author(penName: null, name: name)],
        );
      }

      expect(translation('a'), translation('a'));
      expect(translation('a').hashCode, translation('a').hashCode);
      expect(translation('a'), isNot(translation('b')));
    });

    test('compares through itself', () {
      Publisher publisher(String parent) {
        return Publisher(
          name: 'Ace',
          parent: Publisher(name: parent),
        );
      }

      expect(publisher('Penguin'), publisher('Penguin'));
      expect(publisher('Penguin'), isNot(publisher('Other')));
    });

    test('is not equal to another type', () {
      expect(_author, isNot(const Publisher(name: 'Frank Herbert')));
    });
  });

  group('any other class', () {
    test('keeps identity', () {
      final book = _book();

      expect(book, same(book));
      expect(_book() == _book(), isFalse);
    });

    test('compares by content when asked', () {
      expect(_book().contentEquals(_book()), isTrue);
      expect(_book().contentHash, _book().contentHash);
      expect(
        _book(details: _details()).contentEquals(_book(details: _details())),
        isTrue,
      );
      expect(_book(details: _details()).contentEquals(_book()), isFalse);
      expect(_book().contentEquals(_book(details: _details())), isFalse);
    });

    test('compares nested lists in order', () {
      final other = _details(
        chapterTitles: const [
          ['Dune'],
          [],
        ],
      );

      expect(_details().contentEquals(other), isFalse);
      expect(
        _details(
          chapterTitles: const [
            ['a', 'b'],
          ],
        ).contentEquals(
          _details(
            chapterTitles: const [
              ['b', 'a'],
            ],
          ),
        ),
        isFalse,
      );
    });

    test('compares sets and maps in any order', () {
      final other = _details(
        relatedGenres: const {Genre.sciFi, Genre.fantasy},
        tags: const ['desert', 'classic'],
        awardsByYear: Map.of(const {1965: 'Nebula', 1966: 'Hugo'}),
      );

      expect(_details().contentEquals(other), isTrue);
      expect(_details().contentHash, other.contentHash);
    });

    test('tells apart sets and maps', () {
      final others = [
        _details(relatedGenres: const {Genre.sciFi}),
        _details(tags: const ['classic', 'other']),
        _details(awardsByYear: const {1966: 'Hugo', 1965: 'Other'}),
        _details(awardsByYear: const {1966: 'Hugo', 1964: 'Nebula'}),
        _details(translations: const {}),
        _details(translations: null),
      ];

      for (final other in others) {
        expect(_details().contentEquals(other), isFalse);
        expect(_details().contentHash, isNot(other.contentHash));
      }
    });
  });

  test('toString names every field', () {
    expect(
      const Publisher(name: 'Ace').toString(),
      'Publisher(name: Ace, website: null, parent: null)',
    );
    expect(_book().toString(), startsWith('Book(title: Dune, pageCount: 420,'));
  });
}
