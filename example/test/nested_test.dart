import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/publisher.dart';
import 'package:test/test.dart';

const _author = Author(penName: null, name: 'Frank Herbert');
const _publisher = Publisher(
  name: 'Ace',
  parent: Publisher(name: 'Penguin'),
);

const _dune = Book(
  title: 'Dune',
  pageCount: 420,
  rating: 4.5,
  isHardcover: true,
  genre: Genre.sciFi,
  author: _author,
  publisher: _publisher,
  dimensions: Dimensions(widthCm: 13.5),
);

void main() {
  test('nests each class with its own omit mode', () {
    expect(_dune.toMap()['author'], {'name': 'Frank Herbert'});
    expect(_dune.toMap()['publisher'], {
      'name': 'Ace',
      'website': null,
      'parent': {'name': 'Penguin', 'website': null, 'parent': null},
    });
    expect(
      _dune.toJsonString(),
      allOf(
        contains('"author":{"name":"Frank Herbert"}'),
        contains('"publisher":{"name":"Ace","website":null,"parent":{'),
        contains('{"name":"Penguin","website":null,"parent":null}}'),
      ),
    );
  });

  test('matches jsonEncode(toMap()) for every mix of dropped fields', () {
    const sizes = [
      null,
      Dimensions(),
      Dimensions(heightCm: 20, weightKg: 1),
    ];
    for (final publisher in const [null, Publisher(name: 'Ace'), _publisher]) {
      for (final dimensions in sizes) {
        final book = Book(
          title: 'Dune',
          pageCount: 420,
          rating: 4.5,
          isHardcover: true,
          genre: Genre.sciFi,
          author: _author,
          publisher: publisher,
          dimensions: dimensions,
        );
        expect(book.toJsonString(), jsonEncode(book.toMap()));
      }
    }
  });

  test('round trips through itself', () {
    final decoded = PublisherCharcoal.fromJsonString(
      _publisher.toJsonString(),
    );

    expect(decoded.toMap(), _publisher.toMap());
    expect(decoded.parent?.name, 'Penguin');
    expect(decoded.parent?.parent, isNull);
  });

  test('round trips every nested class', () {
    final decoded = BookCharcoal.fromJsonString(_dune.toJsonString());

    expect(decoded.toMap(), _dune.toMap());
    expect(decoded.publisher?.parent?.name, 'Penguin');
    expect(decoded.dimensions?.widthCm, 13.5);
  });

  test('reads a map holding maps', () {
    final map = _dune.toMap();

    expect(BookCharcoal.fromMap(map).toMap(), map);
  });

  test('wraps a failure inside a nested class in the outer type', () {
    expect(
      () => BookCharcoal.fromMap({
        ..._dune.toMap(),
        'author': {'name': 1},
      }),
      throwsA(
        isA<CharcoalException>()
            .having((e) => e.type, 'type', 'Book')
            .having((e) => e.cause, 'cause', isA<TypeError>()),
      ),
    );
  });

  test('wraps a nested value that is not an object', () {
    expect(
      () => BookCharcoal.fromMap({..._dune.toMap(), 'author': 1}),
      throwsA(isA<CharcoalException>()),
    );
  });

  test('composes into one buffer', () {
    final sink = StringBuffer('[');
    _dune.writeJson(sink);
    sink.write(']');

    expect(sink.toString(), '[${_dune.toJsonString()}]');
  });
}
