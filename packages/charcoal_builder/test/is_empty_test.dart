import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const size = '''
    @Charcoal(omit: Omit.empty)
    final class const Size({this.width, this.pages = 0, this.tags = const []})
        with SizeCharcoal {
      final double? width;
      final int pages;
      final List<String> tags;
    }
  ''';

  group('isEmpty', () {
    test('is generated if every field can be dropped', () async {
      final result = await build(
        '''
        $header
        $size
        ''',
        outputs: {
          output: decodedMatches(
            contains(
              r'return $it.width == null && $it.pages == 0 && '
              r'$it.tags.isEmpty;',
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is generated for a class with no fields', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        final class Size() with SizeCharcoal;
        ''',
        outputs: {output: decodedMatches(contains('return true;'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('goes through a class it holds, if it can be empty too', () async {
      final result = await build(
        '''
        $header
        $size
        @Charcoal(omit: Omit.empty)
        final class Book({this.size = const Size()}) with BookCharcoal {
          final Size size;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'return $it.size.isEmpty;'),
              contains(r"if (!$it.size.isEmpty) 'size': SizeCharcoal"),
              contains(r'if (!$it.size.isEmpty) {'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is left to what a class writes itself', () async {
      final result = await build(
        '''
        $header
        @Charcoal(omit: Omit.empty)
        final class const Size(this.label) with SizeCharcoal {
          final String label;

          bool get isEmpty => label.isEmpty;
        }
        @Charcoal(omit: Omit.empty)
        final class Book({this.size = const Size('')}) with BookCharcoal {
          final Size size;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              isNot(contains(r'$it.label.isEmpty')),
              contains(r"if (!$it.size.isEmpty) 'size'"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    for (final (name, source) in const [
      (
        'a field that is always kept',
        '''
        @Charcoal(omit: Omit.empty)
        final class Book({this.title = ''}) with BookCharcoal {
          final String title;
        }
        ''',
      ),
      (
        'another omit mode',
        '''
        @Charcoal()
        final class Book({this.title}) with BookCharcoal {
          final String? title;
        }
        ''',
      ),
      (
        'a generic class',
        '''
        @Charcoal(omit: Omit.empty)
        final class Book<T>({this.title}) with BookCharcoal<T> {
          final String? title;
        }
        ''',
      ),
      (
        'a class in a sealed family, as it has its tag to keep',
        '''
        @Charcoal(omit: Omit.empty)
        sealed class Edition() with EditionCharcoal;
        final class Book() extends Edition with BookCharcoal;
        ''',
      ),
    ]) {
      test('is not generated for $name', () async {
        final result = await build(
          '''
          $header
          $source
          ''',
          outputs: {output: decodedMatches(isNot(contains('get isEmpty')))},
        );

        expect(result.succeeded, isTrue);
      });
    }
  });

  group('a holder', () {
    test('keeps a class using another omit mode', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class const Size({this.width}) with SizeCharcoal {
          final double? width;
        }
        @Charcoal(omit: Omit.empty)
        final class Book({required this.size}) with BookCharcoal {
          final Size size;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'size': SizeCharcoal.$encode($it.size)"),
              isNot(contains(r'$it.size.isEmpty')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('only drops a nullable class at null', () async {
      final result = await build(
        '''
        $header
        $size
        @Charcoal(omit: Omit.empty)
        final class Book({this.size}) with BookCharcoal {
          final Size? size;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'return $it.size == null;'),
              isNot(contains(r'$it.size.isEmpty')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('with its other mode keeps it, empty or not', () async {
      final result = await build(
        '''
        $header
        $size
        @Charcoal()
        final class Book(this.size) with BookCharcoal {
          final Size size;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'size': SizeCharcoal.$encode($it.size)"),
              isNot(contains(r'!$it.size.isEmpty')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fails the build if a dropped class is required', () async {
      await expectBuildError(
        '''
        $header
        $size
        @Charcoal(omit: Omit.empty)
        final class Book({required this.size}) with BookCharcoal {
          final Size size;
        }
        ''',
        'Book.size can be dropped by Omit.empty',
      );
    });

    test('fails the build if the default is not empty', () async {
      await expectBuildError(
        '''
        $header
        $size
        @Charcoal(omit: Omit.empty)
        final class Book({this.size = const Size(pages: 1)}) with BookCharcoal {
          final Size size;
        }
        ''',
        'Book.size can be dropped by Omit.empty',
      );
    });
  });
}
