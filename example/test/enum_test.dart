import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/language.dart';
import 'package:test/test.dart';

const _author = Author(penName: null, name: 'Frank Herbert');

const _dune = Book(
  title: 'Dune',
  pageCount: 420,
  rating: 4.5,
  isHardcover: true,
  genre: Genre.sciFi,
  author: _author,
);

const _english = Book(
  title: 'Dune',
  pageCount: 420,
  rating: 4.5,
  isHardcover: true,
  genre: Genre.sciFi,
  author: _author,
  language: Language.english,
);

void main() {
  final map = _dune.toMap();

  test('writes names', () {
    expect(_english.toMap(), containsPair('genre', 'sciFi'));
    expect(_english.toMap(), containsPair('language', 'english'));
    expect(_english.toJsonString(), jsonEncode(_english.toMap()));
    expect(_english.toJsonString(), contains('"language":"english"'));
  });

  test('drops a null enum', () {
    expect(map.containsKey('language'), isFalse);
    expect(_dune.toJsonString(), jsonEncode(map));
  });

  test('round trips', () {
    final decoded = BookCharcoal.fromJsonString(_english.toJsonString());

    expect(decoded.genre, Genre.sciFi);
    expect(decoded.language, Language.english);
    expect(BookCharcoal.fromMap(map).language, isNull);
  });

  test('wraps an unknown name', () {
    expect(
      () => BookCharcoal.fromMap({...map, 'genre': 'horror'}),
      throwsA(
        isA<CharcoalException>()
            .having((e) => e.type, 'type', 'Book')
            .having((e) => e.cause, 'cause', isA<ArgumentError>()),
      ),
    );
  });

  test('wraps a wrong type', () {
    expect(
      () => BookCharcoal.fromMap({...map, 'genre': 1}),
      throwsA(isA<CharcoalException>()),
    );
  });
}
