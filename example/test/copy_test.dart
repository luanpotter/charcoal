// A null passed to copyWith clears a field, and leaving it out would not.
// ignore_for_file: avoid_redundant_argument_values

import 'dart:collection';

import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _author = Author(penName: null, name: 'Frank Herbert');

BookDetails _details() {
  return BookDetails(
    partTitles: ['One', null],
    chapterTitles: [
      ['Dune'],
    ],
    otherAuthors: [_author],
    relatedGenres: {Genre.fantasy},
    tags: SplayTreeSet.of(['classic']),
    pageCountByChapter: SplayTreeMap.of({'a': 1}),
    relatedBookIds: const [],
    quotes: const ['q'],
    awardsByYear: {1966: 'Hugo'},
    translations: {
      Language.portuguese: const Translation(
        title: 'Duna',
        translator: _author,
      ),
    },
  );
}

Book _book() {
  return Book(
    title: 'Dune',
    pageCount: 420,
    rating: 4.5,
    isHardcover: true,
    genre: Genre.sciFi,
    author: _author,
    details: _details(),
    notes: 'Reread',
  );
}

void main() {
  group('copy', () {
    test('keeps every value', () {
      final book = _book();

      expect(book.copy().contentEquals(book), isTrue);
    });

    test('makes a new instance of a mutable class, at any depth', () {
      final book = _book();
      final copy = book.copy();

      expect(copy, isNot(same(book)));
      expect(copy.details, isNot(same(book.details)));
    });

    test('shares an immutable class', () {
      final book = _book();

      expect(book.copy().author, same(book.author));
      expect(_author.copy(), same(_author));
    });

    test('rebuilds collections, at any depth', () {
      final details = _details();
      final copy = details.copy();

      copy.partTitles.add('Two');
      copy.chapterTitles.first.add('Desert');
      copy.relatedGenres.add(Genre.sciFi);
      copy.tags.add('desert');
      copy.pageCountByChapter['b'] = 2;
      copy.awardsByYear[1965] = 'Nebula';
      copy.translations?.clear();

      expect(details.contentEquals(_details()), isTrue);
    });

    test('keeps the real collection types', () {
      final copy = _details().copy();

      expect(copy.tags, isA<SplayTreeSet<String>>());
      expect(copy.pageCountByChapter, isA<SplayTreeMap<String, int>>());
      expect(copy.relatedGenres, isA<Set<Genre>>());
      expect(copy.quotes, ['q']);
    });

    test('keeps a null', () {
      const book = Book(
        title: 'Dune',
        pageCount: 420,
        rating: 4.5,
        isHardcover: true,
        genre: Genre.sciFi,
        author: _author,
      );

      expect(book.copy().details, isNull);
    });
  });

  group('copyWith', () {
    test('keeps what is left out', () {
      final book = _book();

      expect(book.copyWith().contentEquals(book), isTrue);
    });

    test('replaces a value', () {
      final copy = _book().copyWith(title: 'Dune Messiah', notes: 'Sequel');

      expect(copy.title, 'Dune Messiah');
      expect(copy.notes, 'Sequel');
      expect(copy.pageCount, 420);
    });

    test('clears with a null', () {
      expect(_book().copyWith(notes: null).notes, isNull);
      expect(_book().copyWith(details: null).details, isNull);
    });

    test('tells a left out null from a passed one', () {
      expect(_book().copyWith().notes, 'Reread');
    });

    test('copies what is left out, and takes as given what is passed', () {
      final book = _book();
      final details = _details();

      expect(book.copyWith().details, isNot(same(book.details)));
      expect(book.copyWith(details: details).details, same(details));
    });

    test('takes any iterable for an iterable field', () {
      final copy = _details().copyWith(quotes: {'a'}.map((quote) => quote));

      expect(copy.quotes, ['a']);
    });

    test('works on an immutable class, sharing what it holds', () {
      const translation = Translation(
        title: 'Duna',
        translator: _author,
        reviewers: [_author],
      );
      final copy = translation.copyWith(title: 'Other');

      expect(copy.title, 'Other');
      expect(copy.reviewers, same(translation.reviewers));
    });

    test('replaces and clears on an immutable class', () {
      const other = Author(penName: 'Pen', name: 'Frank');

      expect(other.copyWith(penName: null).penName, isNull);
      expect(other.copyWith(name: 'Luan').penName, 'Pen');
    });
  });
}
