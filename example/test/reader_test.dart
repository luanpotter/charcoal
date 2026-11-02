import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/id.dart';
import 'package:charcoal_example/isbn.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/publisher.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _author = Author(penName: 'Pen', name: 'Frank', isAlive: false);

Book _book() {
  return Book(
    title: '"Duné\n"', // cspell:ignore Duné
    pageCount: 420,
    rating: 4,
    isHardcover: true,
    genre: Genre.sciFi,
    author: _author,
    isbn: const Isbn('978-0441013593'),
    language: Language.english,
    publisher: const Publisher(
      name: 'Ace',
      parent: Publisher(name: 'Penguin'),
    ),
    dimensions: const Dimensions(widthCm: 13.5, weightKg: 1),
    details: BookDetails(
      partTitles: const ['One', null],
      chapterTitles: const [
        ['a', 'b'],
        [],
      ],
      otherAuthors: const [_author],
      relatedGenres: const {Genre.fantasy},
      tags: SplayTreeSet.of(['b', 'a']),
      pageCountByChapter: SplayTreeMap.of({'b': 2, 'a': 1}),
      relatedBookIds: const [Id(1)],
      quotes: const ['q'],
      awardsByYear: const {1966: 'Hugo'},
      translations: const {
        Language.portuguese: Translation(title: 'Duna', translator: _author),
      },
    ),
    notes: 'n',
  );
}

/// Reverses the keys of every object, so that none comes where it is expected.
Object? _reversed(Object? value) {
  return switch (value) {
    final Map<String, Object?> map => {
      for (final entry in map.entries.toList().reversed)
        entry.key: _reversed(entry.value),
    },
    final List<Object?> list => [for (final item in list) _reversed(item)],
    _ => value,
  };
}

void main() {
  final book = _book();
  final json = book.toJsonString();
  final map = jsonDecode(json) as Map<String, Object?>;

  test('reads what it wrote', () {
    expect(BookCharcoal.fromJsonString(json).toMap(), book.toMap());
  });

  test('reads the same as fromMap with jsonDecode', () {
    expect(
      BookCharcoal.fromJsonString(json).toMap(),
      BookCharcoal.fromMap(map).toMap(),
    );
  });

  test('reads keys in any order', () {
    final reversed = jsonEncode(_reversed(map));

    expect(BookCharcoal.fromJsonString(reversed).toMap(), book.toMap());
  });

  test('skips unknown keys, at any depth', () {
    final extended = jsonEncode({
      'first': {
        'a': [1, 'b', null],
      },
      ...map,
      'author': {...map['author']! as Map<String, Object?>, 'extra': true},
      'last': 1.5,
    });

    expect(BookCharcoal.fromJsonString(extended).toMap(), book.toMap());
  });

  test('takes the last of duplicate keys, as jsonDecode does', () {
    const source = '{"widthCm":1,"widthCm":2}';

    expect(DimensionsCharcoal.fromJsonString(source).widthCm, 2);
  });

  test('allows whitespace anywhere', () {
    const source = ' { "widthCm" : 1.5 , "heightCm" : null } \n';

    expect(DimensionsCharcoal.fromJsonString(source).widthCm, 1.5);
  });

  test('reads an integer as a double', () {
    expect(DimensionsCharcoal.fromJsonString('{"widthCm":4}').widthCm, 4.0);
  });

  test('reads an int or a double as a num', () {
    expect(DimensionsCharcoal.fromJsonString('{"weightKg":1}').weightKg, 1);
    expect(DimensionsCharcoal.fromJsonString('{"weightKg":1.5}').weightKg, 1.5);
  });

  test('builds real collection types', () {
    final details = BookCharcoal.fromJsonString(json).details!;

    expect(details.partTitles, isA<List<String?>>());
    expect(details.chapterTitles, isA<List<List<String>>>());
    expect(details.relatedGenres, isA<Set<Genre>>());
    expect(details.tags, isA<SplayTreeSet<String>>());
    expect(details.pageCountByChapter, isA<SplayTreeMap<String, int>>());
    expect(details.translations, isA<Map<Language, Translation>>());
  });

  group('wraps', () {
    final failures = {
      'malformed JSON': '{',
      'anything after the value': '{"name":"a"} {}',
      'a value that is not an object': '[]',
      'a missing required field': '{}',
      'a wrong type': '{"name":1}',
      'an unexpected null': '{"name":null}',
      'a malformed unknown value': '{"name":"a","other":01}',
    };
    for (final MapEntry(key: name, value: source) in failures.entries) {
      test(name, () {
        expect(
          () => PublisherCharcoal.fromJsonString(source),
          throwsA(
            isA<CharcoalException>().having((e) => e.type, 'type', 'Publisher'),
          ),
        );
      });
    }

    test('a double where an int is expected', () {
      expect(
        () => AuthorCharcoal.fromJsonString(
          '{"penName":null,"name":"a","birthYear":1.0}',
        ),
        throwsA(isA<CharcoalException>()),
      );
    });

    test('an unknown enum name', () {
      expect(
        () => BookCharcoal.fromJsonString(
          jsonEncode({...map, 'genre': 'horror'}),
        ),
        throwsA(isA<CharcoalException>()),
      );
    });
  });
}
