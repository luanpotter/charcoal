import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/edition.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/lookup.dart';
import 'package:charcoal_example/ranked.dart';
import 'package:test/test.dart';

BookDetails _details({
  Ranked<Genre>? topGenre,
  Ranked<Edition>? topEdition,
  Lookup<int>? copiesSold,
  Lookup<String>? seriesName,
}) {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    relatedBookIds: const [],
    topGenre: topGenre,
    topEdition: topEdition,
    copiesSold: copiesSold,
    seriesName: seriesName,
  );
}

void main() {
  group('a generic class', () {
    const genre = Ranked<Genre>(
      item: Genre.sciFi,
      rank: 1,
      runnerUp: Ranked(item: Genre.fantasy, rank: 2),
    );

    test('writes what the type argument is', () {
      final details = _details(topGenre: genre);

      expect(details.toMap()['topGenre'], {
        'item': 'sciFi',
        'rank': 1,
        'runnerUp': {'item': 'fantasy', 'rank': 2},
      });
      expect(details.toJsonString(), jsonEncode(details.toMap()));
    });

    test('round trips through JSON and maps, holding itself', () {
      final details = _details(topGenre: genre);
      final decoded = [
        BookDetailsCharcoal.fromJsonString(details.toJsonString()),
        BookDetailsCharcoal.fromMap(details.toMap()),
      ];

      for (final value in decoded) {
        expect(value.topGenre, isA<Ranked<Genre>>());
        expect(value.topGenre, genre);
        expect(value.topGenre?.runnerUp?.item, Genre.fantasy);
      }
    });

    test('holds a sealed family, by its tag', () {
      const edition = Ranked<Edition>(
        item: Ebook(year: 2005, formats: ['epub']),
        rank: 1,
      );
      final details = _details(topEdition: edition);
      final decoded = BookDetailsCharcoal.fromJsonString(
        details.toJsonString(),
      );

      expect(details.toJsonString(), contains('"item":{"type":"Ebook"'));
      expect(decoded.topEdition?.item, isA<Ebook>());
      expect(decoded.contentEquals(details), isTrue);
    });

    test('wraps a wrong type argument', () {
      final map = {
        ..._details().toMap(),
        'topGenre': {'item': 'klingon', 'rank': 1},
      };

      expect(
        () => BookDetailsCharcoal.fromMap(map),
        throwsA(isA<CharcoalException>()),
      );
      expect(
        () => BookDetailsCharcoal.fromJsonString(jsonEncode(map)),
        throwsA(isA<CharcoalException>()),
      );
    });

    test('compares by value through its own ==', () {
      expect(
        const Ranked<int>(item: 1, rank: 1),
        Ranked<int>(item: [1].first, rank: 1),
      );
      expect(
        const Ranked<int>(item: 1, rank: 1).hashCode,
        Ranked<int>(item: [1].first, rank: 1).hashCode,
      );
      expect(
        const Ranked<int>(item: 1, rank: 1),
        isNot(const Ranked<int>(item: 2, rank: 1)),
      );
    });

    test('copyWith reaches a field of the type parameter', () {
      const ranked = Ranked<String?>(item: 'a', rank: 1);

      expect(ranked.copyWith(rank: 2).item, 'a');
      expect(ranked.copyWith(item: 'b').item, 'b');
      expect(ranked.copyWith(item: null).item, isNull);
    });

    test('toString leaves out the type arguments', () {
      expect(
        const Ranked<int>(item: 1, rank: 1).toString(),
        'Ranked(item: 1, rank: 1, runnerUp: null)',
      );
    });

    test('a holder copies what a use of it holds', () {
      final formats = ['epub'];
      final ebook = Ebook(year: 2005, formats: formats);
      final details = _details(
        topEdition: Ranked(item: ebook, rank: 1),
      );
      final copy = details.copy();

      (copy.topEdition?.item as Ebook?)?.formats.add('pdf');

      expect(ebook.formats, ['epub']);
      expect(copy.contentEquals(details), isFalse);
    });
  });

  group('a generic sealed family', () {
    test('writes and reads the leaf that was there', () {
      for (final sold in const <Lookup<int>>[
        Known(10),
        Unknown(),
        Estimated(low: 1, high: 2),
      ]) {
        final details = _details(copiesSold: sold);
        final decoded = [
          BookDetailsCharcoal.fromJsonString(details.toJsonString()),
          BookDetailsCharcoal.fromMap(details.toMap()),
        ];

        expect(details.toJsonString(), jsonEncode(details.toMap()));
        for (final value in decoded) {
          expect(value.copiesSold.runtimeType, sold.runtimeType);
          expect(value.contentEquals(details), isTrue);
        }
      }
    });

    test('writes the tag of each leaf', () {
      final details = _details(copiesSold: const Known(10));

      expect(details.toMap()['copiesSold'], {'type': 'Known', 'value': 10});
    });

    test('refuses a leaf that does not fit the use', () {
      final map = {
        ..._details().toMap(),
        'seriesName': {'type': 'Estimated', 'low': 1, 'high': 2},
      };

      expect(
        () => BookDetailsCharcoal.fromMap(map),
        throwsA(isA<CharcoalException>()),
      );
    });

    test('tells apart the type arguments of a known leaf', () {
      final details = _details(seriesName: const Known('Dune'));
      final decoded = BookDetailsCharcoal.fromJsonString(
        details.toJsonString(),
      );

      expect(decoded.seriesName, isA<Known<String>>());
    });

    test('compares and copies without JSON, from the family', () {
      const Lookup<int> known = Known(1);
      const Lookup<int> estimated = Estimated(low: 1, high: 2);
      final same = Known<int>([1].first);

      expect(known.contentEquals(same), isTrue);
      expect(known.contentHash, same.contentHash);
      expect(known.contentEquals(estimated), isFalse);
      expect(known.copy(), isA<Known<int>>());
      expect(identical(same.copy(), same), isFalse);
    });
  });
}
