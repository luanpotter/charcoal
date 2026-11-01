import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/publisher.dart';
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

const String Function(Book) _encode = BookCharcoal.encodeJsonString;
const Book Function(String) _decode = BookCharcoal.fromJsonString;

void main() {
  group('toJsonString matches jsonEncode(toMap()) for', () {
    const titles = ['', 'Dune', 'a"b', r'a\b', 'a\nb', '\u0000', '\u{1F4D6}'];

    test('strings needing escapes', () {
      for (final title in titles) {
        final book = Book(
          title: title,
          pageCount: 1,
          rating: 1,
          isHardcover: false,
          genre: Genre.fantasy,
          author: _author,
          notes: title,
        );
        expect(book.toJsonString(), jsonEncode(book.toMap()));
      }
    });

    test('numbers', () {
      for (final rating in [0.0, 4.0, 4.5, -1.5, 1e21, 1e-7]) {
        final book = Book(
          title: '',
          pageCount: -412,
          rating: rating,
          isHardcover: true,
          genre: Genre.fantasy,
          author: _author,
        );
        expect(book.toJsonString(), jsonEncode(book.toMap()));
      }
    });

    test('every mix of dropped fields', () {
      for (final penName in const [null, 'Pen']) {
        for (final birthYear in const [null, 1920]) {
          for (final isAlive in const [null, false]) {
            final author = Author(
              penName: penName,
              name: 'Frank',
              birthYear: birthYear,
              isAlive: isAlive,
            );
            expect(author.toJsonString(), jsonEncode(author.toMap()));
          }
        }
      }
    });

    test('a class whose every field can be dropped', () {
      for (final widthCm in const [null, 13.5]) {
        for (final heightCm in const [null, 20.0]) {
          for (final weightKg in const <num?>[null, 1, 0.5]) {
            final dimensions = Dimensions(
              widthCm: widthCm,
              heightCm: heightCm,
              weightKg: weightKg,
            );
            expect(dimensions.toJsonString(), jsonEncode(dimensions.toMap()));
          }
        }
      }
      expect(const Dimensions().toJsonString(), '{}');
    });

    test('a class keeping nulls', () {
      for (final website in const [null, 'ace.com']) {
        for (final parent in const [null, Publisher(name: 'Penguin')]) {
          final publisher = Publisher(
            name: 'Ace',
            website: website,
            parent: parent,
          );
          expect(publisher.toJsonString(), jsonEncode(publisher.toMap()));
        }
      }
    });
  });

  group('omit', () {
    test('drops nulls by default', () {
      expect(_dune.toJsonString(), isNot(contains('notes')));
      expect(_dune.toMap().containsKey('notes'), isFalse);
    });

    test('keeps nulls with Omit.none', () {
      const publisher = Publisher(name: 'Ace');

      expect(
        publisher.toJsonString(),
        '{"name":"Ace","website":null,"parent":null}',
      );
      expect(publisher.toMap(), {
        'name': 'Ace',
        'website': null,
        'parent': null,
      });
    });

    test('reads what each mode wrote', () {
      const publisher = Publisher(name: 'Ace');

      expect(
        PublisherCharcoal.fromJsonString(publisher.toJsonString()).toMap(),
        publisher.toMap(),
      );
    });
  });

  group('direct writer', () {
    test('writes fields in constructor order', () {
      expect(
        _dune.toJsonString(),
        '{"title":"Dune","pageCount":420,"rating":4.5,"isHardcover":true,'
        '"genre":"sciFi","author":{"name":"Frank Herbert"}}',
      );
    });

    test('composes several values into one buffer', () {
      final sink = StringBuffer();
      _dune.writeJson(sink);
      sink.write(',');
      const Dimensions(widthCm: 13.5).writeJson(sink);

      expect(sink.toString(), '${_dune.toJsonString()},{"widthCm":13.5}');
    });

    test('refuses non-finite numbers', () {
      const book = Book(
        title: '',
        pageCount: 1,
        rating: double.nan,
        isHardcover: true,
        genre: Genre.fantasy,
        author: _author,
      );

      expect(book.toJsonString, throwsA(isA<JsonUnsupportedObjectError>()));
    });
  });

  group('fromJsonString', () {
    test('round trips', () {
      final book = BookCharcoal.fromJsonString(_dune.toJsonString());

      expect(book.toMap(), _dune.toMap());
    });

    test('wraps malformed JSON', () {
      expect(
        () => BookCharcoal.fromJsonString('{'),
        throwsA(
          isA<CharcoalException>()
              .having((e) => e.type, 'type', 'Book')
              .having((e) => e.cause, 'cause', isA<FormatException>()),
        ),
      );
    });

    test('wraps JSON that is not an object', () {
      expect(
        () => BookCharcoal.fromJsonString('[]'),
        throwsA(isA<CharcoalException>()),
      );
    });

    test('wraps a wrong type', () {
      expect(
        () => BookCharcoal.fromJsonString('{"title":1}'),
        throwsA(isA<CharcoalException>()),
      );
    });
  });

  test('passes as const tear-offs', () {
    expect(_decode(_encode(_dune)).title, 'Dune');
  });

  test('jsonEncode refuses a value, pointing to toJsonString', () {
    expect(() => jsonEncode(_dune), throwsA(isA<JsonUnsupportedObjectError>()));
  });
}
