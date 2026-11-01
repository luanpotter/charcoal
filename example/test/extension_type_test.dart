import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/id.dart';
import 'package:charcoal_example/isbn.dart';
import 'package:test/test.dart';

const _dune = Book(
  title: 'Dune',
  pageCount: 420,
  rating: 4.5,
  isHardcover: true,
  genre: Genre.sciFi,
  author: Author(penName: null, name: 'Frank Herbert'),
  isbn: Isbn('978-0441013593'),
);

BookDetails _details() {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    relatedBookIds: const [Id(1), Id(2)],
  );
}

void main() {
  test('writes the representation', () {
    expect(_dune.toMap()['isbn'], '978-0441013593');
    expect(_dune.toJsonString(), contains('"isbn":"978-0441013593"'));
    expect(_details().toMap()['relatedBookIds'], [1, 2]);
    expect(_details().toJsonString(), contains('"relatedBookIds":[1,2]'));
  });

  test('matches jsonEncode(toMap())', () {
    expect(_dune.toJsonString(), jsonEncode(_dune.toMap()));
    expect(_details().toJsonString(), jsonEncode(_details().toMap()));
  });

  test('drops a null extension type', () {
    const book = Book(
      title: 'Dune',
      pageCount: 420,
      rating: 4.5,
      isHardcover: true,
      genre: Genre.sciFi,
      author: Author(penName: null, name: 'Frank Herbert'),
    );

    expect(book.toMap().containsKey('isbn'), isFalse);
    expect(book.toJsonString(), isNot(contains('isbn')));
  });

  test('round trips through JSON and maps', () {
    final json = BookCharcoal.fromJsonString(_dune.toJsonString());
    final map = BookCharcoal.fromMap(_dune.toMap());
    final details = BookDetailsCharcoal.fromJsonString(
      _details().toJsonString(),
    );

    expect(json.isbn, const Isbn('978-0441013593'));
    expect(map.isbn, const Isbn('978-0441013593'));
    expect(details.relatedBookIds, const [Id<Book>(1), Id<Book>(2)]);
    expect(
      BookDetailsCharcoal.fromMap(_details().toMap()).relatedBookIds,
      const [Id<Book>(1), Id<Book>(2)],
    );
  });

  test('wraps a wrong representation type', () {
    final map = _dune.toMap();

    expect(
      () => BookCharcoal.fromMap({...map, 'isbn': 1}),
      throwsA(isA<CharcoalException>()),
    );
    expect(
      () => BookCharcoal.fromJsonString(jsonEncode({...map, 'isbn': 1})),
      throwsA(isA<CharcoalException>()),
    );
  });
}
