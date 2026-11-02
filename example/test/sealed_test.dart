import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/edition.dart';
import 'package:test/test.dart';

const _narrator = Author(penName: null, name: 'Luan');
const _hardcover = Hardcover(year: 1965, weightGrams: 900);
const _ebook = Ebook(year: 2005, formats: ['epub']);
const _audiobook = Audiobook(
  year: 2007,
  formats: ['mp3'],
  narrator: _narrator,
);
const List<Edition> _all = [_hardcover, _ebook, _audiobook];
Ebook _newEbook(int year) => Ebook(year: year, formats: ['epub']);

void main() {
  test('writes the tag first, then fields in constructor order', () {
    expect(
      _hardcover.toJsonString(),
      '{"type":"hardcover","year":1965,"weightGrams":900}',
    );
    expect(
      const Hardcover(year: 1965).toJsonString(),
      '{"type":"hardcover","year":1965}',
    );
    expect(
      _ebook.toJsonString(),
      '{"type":"Ebook","year":2005,"formats":["epub"]}',
    );
  });

  test('matches jsonEncode(toMap()), through the family', () {
    for (final edition in _all) {
      expect(edition.toJsonString(), jsonEncode(edition.toMap()));
    }
  });

  test('round trips each leaf through JSON and maps', () {
    for (final edition in _all) {
      final decoded = [
        EditionCharcoal.fromJsonString(edition.toJsonString()),
        EditionCharcoal.fromMap(edition.toMap()),
      ];
      for (final value in decoded) {
        expect(value.runtimeType, edition.runtimeType);
        expect(value.contentEquals(edition), isTrue);
      }
    }
  });

  test('finds the tag wherever it is', () {
    const source = ' {"year" : 1965, "other":[{}], "type" : "hardcover"} ';
    final decoded = EditionCharcoal.fromJsonString(source);

    expect(decoded, const Hardcover(year: 1965));
  });

  test('decodes through a branch', () {
    final digital = DigitalCharcoal.fromJsonString(_audiobook.toJsonString());

    expect(digital.formats, ['mp3']);
  });

  test('a marker only takes its own leaves', () {
    final readable = ReadableCharcoal.fromJsonString(_ebook.toJsonString());

    expect(readable, isA<Ebook>());
    expect(
      () => ReadableCharcoal.fromJsonString(_audiobook.toJsonString()),
      throwsA(isA<CharcoalException>()),
    );
    expect(
      () => ReadableCharcoal.fromMap(_audiobook.toMap()),
      throwsA(
        isA<CharcoalException>()
            .having((e) => e.type, 'type', 'Readable')
            .having((e) => e.cause, 'cause', isA<ArgumentError>()),
      ),
    );
  });

  test('wraps an unknown or missing tag', () {
    for (final source in [
      '{"type":"klingon","year":1}',
      '{"year":1}',
      '{"type":1,"year":1}',
      '{',
      '[]',
    ]) {
      expect(
        () => EditionCharcoal.fromJsonString(source),
        throwsA(isA<CharcoalException>()),
      );
    }
    expect(
      () => EditionCharcoal.fromMap(const {'year': 1}),
      throwsA(isA<CharcoalException>()),
    );
  });

  test('works from a leaf, ignoring the tag', () {
    final hardcover = HardcoverCharcoal.fromJsonString(
      _hardcover.toJsonString(),
    );

    expect(hardcover, _hardcover);
  });

  group('equality', () {
    test('an immutable leaf compares by value', () {
      expect(const Hardcover(year: 1), const Hardcover(year: 1));
      expect(const Hardcover(year: 1), isNot(const Hardcover(year: 2)));
    });

    test('a mutable leaf keeps identity, with its inherited fields', () {
      final ebook = _newEbook(2005);
      final same = _newEbook(2005);

      expect(ebook == same, isFalse);
      expect(ebook.contentEquals(same), isTrue);
      expect(ebook.contentHash, same.contentHash);
      expect(ebook.contentEquals(_newEbook(2006)), isFalse);
    });

    test('compares through the family, telling leaves apart', () {
      const Edition ebook = Ebook(year: 2007, formats: ['mp3']);
      const Edition audiobook = _audiobook;
      const Edition hardcover = _hardcover;
      final again = EditionCharcoal.fromJsonString(_audiobook.toJsonString());

      expect(identical(again, audiobook), isFalse);
      expect(audiobook.contentEquals(again), isTrue);
      expect(audiobook.contentHash, again.contentHash);
      expect(audiobook.contentEquals(ebook), isFalse);
      expect(hardcover.contentEquals(ebook), isFalse);
    });
  });

  group('copy', () {
    test('rebuilds a mutable leaf, including what it inherits', () {
      final ebook = _newEbook(2005);
      final Edition edition = ebook;
      final copy = edition.copy() as Ebook;

      copy.formats.add('pdf');

      expect(ebook.formats, ['epub']);
    });

    test('shares an immutable leaf', () {
      const Edition edition = _hardcover;

      expect(edition.copy(), same(edition));
    });

    test('copyWith reaches an inherited field', () {
      final copy = _hardcover.copyWith(year: 2000);

      expect(copy.year, 2000);
      expect(copy.weightGrams, 900);
      expect(_hardcover.copyWith(weightGrams: null).weightGrams, isNull);
    });
  });

  test('toString names inherited fields too', () {
    expect(_hardcover.toString(), 'Hardcover(year: 1965, weightGrams: 900)');
  });

  test('works as a field, at any depth', () {
    final details = BookDetails(
      partTitles: const [],
      chapterTitles: const [],
      otherAuthors: const [],
      relatedGenres: const {},
      tags: SplayTreeSet(),
      pageCountByChapter: SplayTreeMap(),
      relatedBookIds: const [],
      editions: _all,
    );
    final decoded = [
      BookDetailsCharcoal.fromJsonString(details.toJsonString()),
      BookDetailsCharcoal.fromMap(details.toMap()),
    ];

    expect(details.toJsonString(), jsonEncode(details.toMap()));
    for (final value in decoded) {
      expect(value.editions[1], isA<Ebook>());
      expect(value.contentEquals(details), isTrue);
    }
    expect(details.copy().contentEquals(details), isTrue);
  });
}
