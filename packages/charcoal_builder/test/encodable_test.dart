import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('encodable', () {
    test('is what a class and a leaf are, through their mixins', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class const Book(this.title) with BookCharcoal {
          final String title;
        }
        @Charcoal()
        sealed class const Edition({required this.year}) {
          final int year;
        }
        final class const Hardcover({required super.year})
            extends Edition with HardcoverCharcoal;
        const List<CharcoalEncodable> shelf = [
          Book('Dune'),
          Hardcover(year: 1965),
        ];
        String encode(CharcoalEncodable it) => it.toJsonString();
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('mixin BookCharcoal implements CharcoalEncodable {'),
              contains(
                'mixin HardcoverCharcoal implements CharcoalEncodable {',
              ),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is not what a generic class is', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Ranked<T>(this.item) with RankedCharcoal<T> {
          final T item;
        }
        final CharcoalEncodable ranked = Ranked(1);
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isFalse);
      expect(
        result.errors.join('\n'),
        contains("'Ranked<int>' can't be assigned"),
      );
    });
  });
}
