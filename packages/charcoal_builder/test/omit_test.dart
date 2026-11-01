import 'package:build_test/build_test.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('omit', () {
    const book =
        '''
      $header
      @Charcoal()
      class Book(this.notes) with BookCharcoal {
        final String? notes;
      }
      ''';
    const keepsNulls = r"'notes': $it.notes";
    const dropsNulls = r"'notes': ?$it.notes";

    test('drops nulls by default', () async {
      final result = await build(
        book,
        outputs: {output: decodedMatches(contains(dropsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the default from the config', () async {
      final result = await build(
        book,
        config: {'omit': 'none'},
        outputs: {output: decodedMatches(contains(keepsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the annotation over the config', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.nulls)
        class Book(this.notes) with BookCharcoal {
          final String? notes;
        }
        ''',
        config: {'omit': 'none'},
        outputs: {output: decodedMatches(contains(dropsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the annotation over the default', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.none)
        class Book(this.notes) with BookCharcoal {
          final String? notes;
        }
        ''',
        outputs: {output: decodedMatches(contains(keepsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('refuses an unknown config value', () {
      expect(
        () => CharcoalConfig.fromMap({'omit': 'everything'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses an unknown config key', () {
      expect(
        () => CharcoalConfig.fromMap({'discriminator': 'type'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
