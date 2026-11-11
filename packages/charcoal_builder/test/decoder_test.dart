import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('decoder', () {
    const family =
        '''
      $header
      @Charcoal()
      sealed class const Edition({required this.year}) with EditionCharcoal {
        final int year;
      }
      sealed class const Digital({required super.year})
          extends Edition with DigitalCharcoal;
      sealed class const Readable() with ReadableCharcoal implements Edition;
      final class const Hardcover({required super.year})
          extends Edition with HardcoverCharcoal implements Readable;
      final class const Ebook({required super.year})
          extends Digital with EbookCharcoal;
    ''';

    test('is a constant of each class, over its statics', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {
          output: decodedMatches(
            contains(
              'static const decoder = '
              'CharcoalDecoder<Book>(fromJsonString, fromMap);',
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is on each sealed class, and each leaf', () async {
      final result = await build(
        family,
        outputs: {
          output: decodedMatches(
            allOf([
              for (final name in [
                'Edition',
                'Digital',
                'Readable',
                'Hardcover',
                'Ebook',
              ])
                contains('CharcoalDecoder<$name>('),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is not on a generic class, nor on a use of one', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Ranked<T>(this.item) with RankedCharcoal<T> {
          final T item;
        }
        @Charcoal()
        sealed class Lookup<T>() with LookupCharcoal<T>;
        final class Known<T>(this.value)
            extends Lookup<T> with KnownCharcoal<T> {
          final T value;
        }
        @Charcoal()
        final class Book(this.ranked, this.sold) with BookCharcoal {
          final Ranked<int> ranked;
          final Lookup<int> sold;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('CharcoalDecoder<Book>('),
              isNot(contains('CharcoalDecoder<Ranked')),
              isNot(contains('CharcoalDecoder<Lookup')),
              isNot(contains('CharcoalDecoder<Known')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is const, and gives a generic consumer its types', () async {
      final result = await build(
        '''
        $family
        final class const Route<
          Request extends CharcoalEncodable,
          Response extends CharcoalEncodable
        >(this.request, this.response) {
          final CharcoalDecoder<Request> request;
          final CharcoalDecoder<Response> response;
        }
        const reprint = Route(HardcoverCharcoal.decoder, EditionCharcoal.decoder);
        const Route<Hardcover, Edition> typed = reprint;
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isTrue);
    });

    test('refuses a consumer of a narrower type', () async {
      final result = await build(
        '''
        $family
        final class const Route<Response>(this.response) {
          final CharcoalDecoder<Response> response;
        }
        const Route<Hardcover> hardcover = Route(EditionCharcoal.decoder);
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isFalse);
      expect(
        result.errors.join('\n'),
        contains("'CharcoalDecoder<Edition>' can't be assigned"),
      );
    });

    test('leaves an instance member of the same name alone', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(this.decoder) with BookCharcoal {
          final String decoder;
        }
        Book use(Book book) => BookCharcoal.decoder.fromJsonString(book.decoder);
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isTrue);
    });
  });
}
