import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/translation.dart';
import 'package:test/test.dart';

const _translator = Author(penName: null, name: 'Luan');
const _translation = Translation(title: 'Duna', translator: _translator);
const Map<String, Object?> _required = {
  'title': 'Duna',
  'translator': {'name': 'Luan'},
};

void main() {
  void expectDefaults(Translation value) {
    expect(value.revision, 0);
    expect(value.reviewers, isEmpty);
    expect(value.originalLanguage, Language.english);
    expect(value.notes, '');
  }

  group('decoding uses the default for', () {
    const nulls = {
      ..._required,
      'revision': null,
      'reviewers': null,
      'originalLanguage': null,
      'notes': null,
    };

    test('a missing key', () {
      expectDefaults(TranslationCharcoal.fromMap(_required));
      expectDefaults(
        TranslationCharcoal.fromJsonString(jsonEncode(_required)),
      );
    });

    test('a null', () {
      expectDefaults(TranslationCharcoal.fromMap(nulls));
      expectDefaults(TranslationCharcoal.fromJsonString(jsonEncode(nulls)));
    });
  });

  test('decoding keeps a present value', () {
    const other = Translation(
      title: 'Duna',
      translator: _translator,
      revision: 2,
      reviewers: [_translator],
      originalLanguage: Language.portuguese,
      notes: 'n',
    );

    for (final decoded in [
      TranslationCharcoal.fromJsonString(other.toJsonString()),
      TranslationCharcoal.fromMap(other.toMap()),
    ]) {
      expect(decoded.toMap(), other.toMap());
      expect(decoded.revision, 2);
      expect(decoded.originalLanguage, Language.portuguese);
    }
  });

  group('Omit.empty', () {
    test('drops numbers at zero and empty collections', () {
      expect(_translation.toMap().containsKey('revision'), isFalse);
      expect(_translation.toMap().containsKey('reviewers'), isFalse);
      expect(_translation.toJsonString(), isNot(contains('revision')));
      expect(_translation.toJsonString(), isNot(contains('reviewers')));
    });

    test('keeps strings, even empty', () {
      expect(_translation.toMap(), containsPair('notes', ''));
      expect(_translation.toJsonString(), contains('"notes":""'));
    });

    test('keeps a default that is not empty', () {
      expect(_translation.toMap(), containsPair('originalLanguage', 'english'));
    });

    test('keeps what is not empty', () {
      const other = Translation(
        title: 'Duna',
        translator: _translator,
        revision: 1,
        reviewers: [_translator],
      );

      expect(other.toMap(), containsPair('revision', 1));
      expect(other.toJsonString(), contains('"revision":1'));
      expect(other.toJsonString(), contains('"reviewers":['));
    });

    test('matches jsonEncode(toMap()) for every mix', () {
      for (final revision in const [0, 1]) {
        for (final reviewers in const [
          <Author>[],
          [_translator],
        ]) {
          final translation = Translation(
            title: 'Duna',
            translator: _translator,
            revision: revision,
            reviewers: reviewers,
          );
          expect(translation.toJsonString(), jsonEncode(translation.toMap()));
        }
      }
    });

    test('round trips what it dropped', () {
      final decoded = TranslationCharcoal.fromJsonString(
        _translation.toJsonString(),
      );

      expect(decoded.toMap(), _translation.toMap());
      expectDefaults(decoded);
    });
  });

  test('refuses a wrong type where there is a default', () {
    final map = {..._required, 'revision': 'first'};

    expect(
      () => TranslationCharcoal.fromMap(map),
      throwsA(isA<CharcoalException>()),
    );
    expect(
      () => TranslationCharcoal.fromJsonString(jsonEncode(map)),
      throwsA(isA<CharcoalException>()),
    );
  });
}
