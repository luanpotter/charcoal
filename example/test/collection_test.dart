import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _author = Author(penName: null, name: 'Frank Herbert');
const _translator = Author(penName: null, name: 'Luan');

BookDetails _details() {
  return BookDetails(
    partTitles: const ['Book One', null],
    chapterTitles: const [
      ['Dune', 'Desert'],
      [],
      ['The Prophet'],
    ],
    otherAuthors: const [_translator, _author],
    relatedGenres: const {Genre.fantasy},
    tags: SplayTreeSet.of(['desert', 'classic']),
    pageCountByChapter: SplayTreeMap.of({'b"c': 2, 'a': 1}),
    quotes: const [
      'The spice must flow.',
      'I must not fear. Fear is the mind-killer.',
    ],
    awards: const {'Hugo': 1966, 'Nebula': 1965},
    translations: const {
      Language.portuguese: Translation(title: 'Duna', translator: _translator),
    },
  );
}

BookDetails _empty() {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    quotes: const [],
    awards: const {},
    translations: const {},
  );
}

BookDetails _requiredOnly() {
  return BookDetails(
    partTitles: const [null],
    chapterTitles: const [[]],
    otherAuthors: const [_author],
    relatedGenres: const {Genre.sciFi},
    tags: SplayTreeSet.of(['classic']),
    pageCountByChapter: SplayTreeMap.of({'a': 1}),
  );
}

void main() {
  test('nests lists, keeping nulls inside them', () {
    expect(
      _details().toJsonString(),
      allOf(
        startsWith('{"partTitles":["Book One",null],'),
        contains('"chapterTitles":[["Dune","Desert"],[],["The Prophet"]],'),
      ),
    );
  });

  test('writes any iterable as a list and any map as an object', () {
    final map = _details().toMap();

    expect(map['relatedGenres'], ['fantasy']);
    expect(map['tags'], ['classic', 'desert']);
    expect(map['quotes'], hasLength(2));
    expect(map['pageCountByChapter'], {'a': 1, 'b"c': 2});
    expect(map['awards'], {'Hugo': 1966, 'Nebula': 1965});
  });

  test('writes enum map keys by name', () {
    final details = _details();

    expect(details.toMap()['translations'], {
      'portuguese': {
        'title': 'Duna',
        'translator': {'name': 'Luan'},
      },
    });
    expect(details.toJsonString(), contains('{"portuguese":{"title":"Duna"'));
  });

  test('matches jsonEncode(toMap()), including empty collections', () {
    for (final details in [_details(), _empty(), _requiredOnly()]) {
      expect(details.toJsonString(), jsonEncode(details.toMap()));
    }
    expect(_empty().toJsonString(), contains('"tags":[]'));
    expect(_empty().toJsonString(), contains('"translations":{}'));
  });

  test('round trips through JSON, with the real collection types', () {
    final details = _details();
    final decoded = BookDetailsCharcoal.fromJsonString(details.toJsonString());

    expect(decoded.toMap(), details.toMap());
    expect(decoded.partTitles, isA<List<String?>>());
    expect(decoded.chapterTitles, isA<List<List<String>>>());
    expect(decoded.chapterTitles[1], isEmpty);
    expect(decoded.otherAuthors, isA<List<Author>>());
    expect(decoded.relatedGenres, isA<Set<Genre>>());
    expect(decoded.tags, isA<SplayTreeSet<String>>());
    expect(decoded.pageCountByChapter, isA<SplayTreeMap<String, int>>());
    expect(decoded.quotes, isA<Iterable<String>>());
    expect(decoded.awards, isA<Map<String, int>>());
    expect(decoded.translations, isA<Map<Language, Translation>>());
    expect(
      decoded.translations?[Language.portuguese]?.translator.name,
      'Luan',
    );
  });

  test('round trips through a map', () {
    final map = _details().toMap();

    expect(BookDetailsCharcoal.fromMap(map).toMap(), map);
  });

  test('round trips inside a book', () {
    final book = Book(
      title: 'Dune',
      pageCount: 420,
      rating: 4.5,
      isHardcover: true,
      genre: Genre.sciFi,
      author: _author,
      details: _details(),
    );

    expect(book.toJsonString(), jsonEncode(book.toMap()));
    expect(
      BookCharcoal.fromJsonString(book.toJsonString()).toMap(),
      book.toMap(),
    );
  });

  test('wraps a wrong element type', () {
    final map = _details().toMap();

    for (final broken in [
      {...map, 'tags': 'classic'},
      {
        ...map,
        'tags': [1],
      },
      {
        ...map,
        'relatedGenres': ['klingon'],
      },
      {
        ...map,
        'pageCountByChapter': {'a': 'b'},
      },
      {
        ...map,
        'awards': {'Hugo': 'first'},
      },
      {
        ...map,
        'translations': {'klingon': 1},
      },
      {
        ...map,
        'translations': {'portuguese': 1},
      },
    ]) {
      expect(
        () => BookDetailsCharcoal.fromMap(broken),
        throwsA(isA<CharcoalException>()),
      );
    }
  });
}
