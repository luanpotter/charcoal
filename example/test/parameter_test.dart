import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/book_loan.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _reviewer = Author(penName: null, name: 'Luan');

BookDetails _details({String subtitle = ''}) {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    relatedBookIds: const [],
    subtitle: subtitle,
  );
}

void main() {
  group('a nullable parameter of a field that is not', () {
    const required = {
      'title': 'Duna',
      'translator': {'name': 'Luan'},
    };

    test('takes what the initializer makes, for a missing key or a null', () {
      const nulled = {...required, 'reviewers': null};

      for (final translation in [
        TranslationCharcoal.fromMap(required),
        TranslationCharcoal.fromMap(nulled),
        TranslationCharcoal.fromJsonString(jsonEncode(required)),
        TranslationCharcoal.fromJsonString(jsonEncode(nulled)),
      ]) {
        expect(translation.reviewers, isEmpty);
      }
    });

    test('writes the field, typed as the field in copyWith', () {
      const translation = Translation(title: 'Duna', translator: _reviewer);
      final reviewed = translation.copyWith(reviewers: const [_reviewer]);

      expect(reviewed.reviewers, [_reviewer]);
      expect(
        reviewed.toJsonString(),
        contains('"reviewers":[{"name":"Luan"}]'),
      );
      expect(reviewed.toJsonString(), jsonEncode(reviewed.toMap()));
      expect(TranslationCharcoal.fromMap(reviewed.toMap()), reviewed);
    });

    test('is what Omit.empty drops, as the initializer brings it back', () {
      const translation = Translation(title: 'Duna', translator: _reviewer);
      final decoded = TranslationCharcoal.fromJsonString(
        translation.toJsonString(),
      );

      expect(translation.toMap().containsKey('reviewers'), isFalse);
      expect(decoded, translation);
    });
  });

  group('a getter over a private field', () {
    test('round trips what it holds', () {
      final details = _details(subtitle: 'Book One');
      final decoded = [
        BookDetailsCharcoal.fromJsonString(details.toJsonString()),
        BookDetailsCharcoal.fromMap(details.toMap()),
      ];

      expect(details.toMap()['subtitle'], 'Book One');
      for (final value in decoded) {
        expect(value.subtitle, 'Book One');
        expect(value.contentEquals(details), isTrue);
      }
    });

    test('follows what the setter did', () {
      final details = _details()..subtitle = '  Book One ';

      expect(details.toMap()['subtitle'], 'Book One');
      expect(details.copy().subtitle, 'Book One');
      expect(details.copyWith().subtitle, 'Book One');
      expect(details.toString(), contains('subtitle: Book One'));
    });

    test('compares by its value', () {
      final details = _details(subtitle: 'a');

      expect(details.contentEquals(_details(subtitle: 'a')), isTrue);
      expect(details.contentHash, _details(subtitle: 'a').contentHash);
      expect(details.contentEquals(_details(subtitle: 'b')), isFalse);
    });

    test('takes the default of its parameter for a missing key', () {
      final map = _details().toMap()..remove('subtitle');

      expect(BookDetailsCharcoal.fromMap(map).subtitle, '');
    });
  });

  group('a validating factory', () {
    test('round trips what it accepts', () {
      final loan = BookLoan('Luan', 7);

      expect(loan.toMap(), {'reader': 'Luan', 'days': 7});
      expect(BookLoanCharcoal.fromJsonString(loan.toJsonString()), loan);
      expect(BookLoanCharcoal.fromMap(loan.toMap()), loan);
    });

    test('refuses what it does not when decoding, wrapping the failure', () {
      const invalid = {'reader': 'Luan', 'days': 0};

      expect(
        () => BookLoanCharcoal.fromMap(invalid),
        throwsA(
          isA<CharcoalException>().having(
            (e) => e.cause,
            'cause',
            isA<ArgumentError>(),
          ),
        ),
      );
      expect(
        () => BookLoanCharcoal.fromJsonString(jsonEncode(invalid)),
        throwsA(isA<CharcoalException>()),
      );
    });

    test('refuses what it does not through copyWith', () {
      expect(
        () => BookLoan('Luan', 7).copyWith(days: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
