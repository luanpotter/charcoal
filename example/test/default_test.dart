import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _translator = Author(penName: null, name: 'Luan');
const _translation = Translation(title: 'Duna', translator: _translator);
const Map<String, Object?> _translationKeys = {
  'title': 'Duna',
  'translator': {'name': 'Luan'},
};

BookDetails _details({
  String subtitle = '',
  Iterable<String> quotes = const [],
  Map<String, int> awards = const {},
}) {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    relatedBookIds: const [],
    subtitle: subtitle,
    quotes: quotes,
    awards: awards,
  );
}

void main() {
  group('decoding uses the default for a missing key', () {
    void expectDefaults(Translation value) {
      expect(value.edition, 1);
      expect(value.originalLanguage, Language.english);
    }

    test('from JSON', () {
      expectDefaults(
        TranslationCharcoal.fromJsonString(jsonEncode(_translationKeys)),
      );
    });

    test('from a map', () {
      expectDefaults(TranslationCharcoal.fromMap(_translationKeys));
    });
  });

  group('decoding keeps a present value', () {
    const other = Translation(
      title: 'Duna',
      translator: _translator,
      edition: 2,
      originalLanguage: Language.portuguese,
    );

    test('from JSON and from a map', () {
      final json = TranslationCharcoal.fromJsonString(other.toJsonString());
      final map = TranslationCharcoal.fromMap(other.toMap());

      expect(json.edition, 2);
      expect(json.originalLanguage, Language.portuguese);
      expect(map.toMap(), other.toMap());
    });

    test('including a null over a non-null default', () {
      const nulled = Translation(
        title: 'Duna',
        translator: _translator,
        originalLanguage: null,
      );

      expect(nulled.toJsonString(), contains('"originalLanguage":null'));
      expect(
        TranslationCharcoal.fromJsonString(
          nulled.toJsonString(),
        ).originalLanguage,
        isNull,
      );
      expect(
        TranslationCharcoal.fromMap(nulled.toMap()).originalLanguage,
        isNull,
      );
    });
  });

  test('keeps writing a default that is not empty', () {
    expect(_translation.toMap(), containsPair('edition', 1));
    expect(_translation.toJsonString(), contains('"edition":1'));
    expect(_translation.toJsonString(), jsonEncode(_translation.toMap()));
  });

  test('refuses a null where the type does not allow it', () {
    final map = {..._translationKeys, 'edition': null};

    expect(
      () => TranslationCharcoal.fromJsonString(jsonEncode(map)),
      throwsA(isA<CharcoalException>()),
    );
    expect(
      () => TranslationCharcoal.fromMap(map),
      throwsA(isA<CharcoalException>()),
    );
  });

  group('Omit.empty', () {
    test('drops empty values with an empty default', () {
      final details = _details();

      expect(details.toMap().containsKey('subtitle'), isFalse);
      expect(details.toMap().containsKey('quotes'), isFalse);
      expect(details.toMap().containsKey('awards'), isFalse);
      expect(details.toJsonString(), isNot(contains('subtitle')));
    });

    test('keeps empty values without a default', () {
      expect(_details().toMap()['partTitles'], isEmpty);
      expect(_details().toJsonString(), contains('"tags":[]'));
    });

    test('keeps what is not empty', () {
      final details = _details(subtitle: 'Book One');

      expect(details.toMap(), containsPair('subtitle', 'Book One'));
      expect(details.toJsonString(), contains('"subtitle":"Book One"'));
    });

    test('matches jsonEncode(toMap()) for every mix', () {
      for (final subtitle in const ['', 'Book One']) {
        for (final quotes in const [
          <String>[],
          ['The spice must flow.'],
        ]) {
          for (final awards in const [
            <String, int>{},
            {'Hugo': 1966},
          ]) {
            final details = _details(
              subtitle: subtitle,
              quotes: quotes,
              awards: awards,
            );
            expect(details.toJsonString(), jsonEncode(details.toMap()));
          }
        }
      }
    });

    test('round trips what it dropped', () {
      final details = _details();
      final json = details.toJsonString();
      final decoded = BookDetailsCharcoal.fromJsonString(json);

      expect(decoded.toMap(), details.toMap());
      expect(decoded.subtitle, '');
      expect(decoded.quotes, isEmpty);
      expect(decoded.awards, isEmpty);
      expect(
        BookDetailsCharcoal.fromMap(details.toMap()).subtitle,
        '',
      );
    });
  });
}
