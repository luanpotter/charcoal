import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/publisher.dart';
import 'package:charcoal_example/series.dart';
import 'package:test/test.dart';

const _dune = Book(title: 'Dune', pages: 420, rating: 4.5, isHardcover: true);

const String Function(Book) _encode = BookCharcoal.encodeJsonString;
const Book Function(String) _decode = BookCharcoal.fromJsonString;

void main() {
  group('toJsonString matches jsonEncode(toMap()) for', () {
    const titles = ['', 'Dune', 'a"b', r'a\b', 'a\nb', '\u0000', '\u{1F4D6}'];

    test('strings needing escapes', () {
      for (final title in titles) {
        final book = Book(
          title: title,
          pages: 1,
          rating: 1,
          isHardcover: false,
          note: title,
        );
        expect(book.toJsonString(), jsonEncode(book.toMap()));
      }
    });

    test('numbers', () {
      for (final rating in [0.0, 4.0, 4.5, -1.5, 1e21, 1e-7]) {
        final book = Book(
          title: '',
          pages: -412,
          rating: rating,
          isHardcover: true,
        );
        expect(book.toJsonString(), jsonEncode(book.toMap()));
      }
    });

    test('every mix of dropped fields', () {
      for (final penName in const [null, 'Pen']) {
        for (final born in const [null, 1920]) {
          for (final isAlive in const [null, false]) {
            final author = Author(
              penName: penName,
              name: 'Frank',
              born: born,
              isAlive: isAlive,
            );
            expect(author.toJsonString(), jsonEncode(author.toMap()));
          }
        }
      }
    });

    test('a class whose every field can be dropped', () {
      for (final name in const [null, 'Dune']) {
        for (final position in const [null, 2]) {
          for (final score in const [null, 4.5]) {
            final series = Series(name: name, position: position, score: score);
            expect(series.toJsonString(), jsonEncode(series.toMap()));
          }
        }
      }
      expect(const Series().toJsonString(), '{}');
    });

    test('a class keeping nulls', () {
      for (final website in const [null, 'ace.com']) {
        for (final founded in const [null, 1953]) {
          for (final revenue in const <num>[1, 1.5]) {
            final publisher = Publisher(
              website: website,
              name: 'Ace',
              revenue: revenue,
              founded: founded,
            );
            expect(publisher.toJsonString(), jsonEncode(publisher.toMap()));
          }
        }
      }
    });
  });

  group('omit', () {
    test('drops nulls by default', () {
      expect(_dune.toJsonString(), isNot(contains('note')));
      expect(_dune.toMap().containsKey('note'), isFalse);
    });

    test('keeps nulls with Omit.none', () {
      const publisher = Publisher(website: null, name: 'Ace', revenue: 1);

      expect(
        publisher.toJsonString(),
        '{"website":null,"name":"Ace","revenue":1,"founded":null}',
      );
      expect(publisher.toMap(), {
        'website': null,
        'name': 'Ace',
        'revenue': 1,
        'founded': null,
      });
    });

    test('reads what each mode wrote', () {
      const publisher = Publisher(website: null, name: 'Ace', revenue: 1);

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
        '{"title":"Dune","pages":420,"rating":4.5,"isHardcover":true}',
      );
    });

    test('composes several values into one buffer', () {
      final sink = StringBuffer();
      _dune.writeJson(sink);
      sink.write(',');
      const Series(position: 1).writeJson(sink);

      expect(sink.toString(), '${_dune.toJsonString()},{"position":1}');
    });

    test('refuses non-finite numbers', () {
      const book = Book(
        title: '',
        pages: 1,
        rating: double.nan,
        isHardcover: true,
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
