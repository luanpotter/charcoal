import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('a sealed family', () {
    const family =
        '''
      $header
      @Charcoal()
      sealed class Edition({required this.year}) {
        final int year;
      }
      sealed class Digital({required super.year}) extends Edition;
      sealed class Readable() implements Edition;
      final class Hardcover({required super.year, this.notes})
          extends Edition with HardcoverCharcoal implements Readable {
        final String? notes;
      }
      final class Ebook({required super.year})
          extends Digital with EbookCharcoal implements Readable;
      final class Audiobook({required super.year})
          extends Digital with AudiobookCharcoal;
    ''';

    test('writes its tag first, even with nothing else certain', () async {
      final result = await build(
        family,
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"""'type': 'Hardcover', 'year': $it.year"""),
              contains(r'''$sink.write('{"type":"Hardcover","year":');'''),
              contains(r"""$sink.write(',"notes":');"""),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('switches over its leaves, for each sealed type', () async {
      final result = await build(
        family,
        outputs: {
          output: decodedMatches(
            allOf([
              contains('abstract final class EditionCharcoal'),
              contains('extension EditionCharcoalMembers on Edition'),
              contains(r'final Hardcover $l => HardcoverCharcoal.$encode($l)'),
              contains(r"final $tag = $json['type'] as String;"),
              contains(r"final $tag = $r.peekStringField('type');"),
              contains(r"'Ebook' => EbookCharcoal.$read($r)"),
              contains('abstract final class DigitalCharcoal'),
              contains('abstract final class ReadableCharcoal'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can be held as a field, at any depth', () async {
      final result = await build(
        '''
        $family
        @Charcoal()
        class Book(this.main, this.others) with BookCharcoal {
          final Edition? main;
          final List<Readable> others;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'final $v => EditionCharcoal.$encode($v)'),
              contains(r'ReadableCharcoal.$decode($e0'),
              contains(r'EditionCharcoal.$equals($v0, $w0)'),
              contains(r'EditionCharcoal.$copy($v0)'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('shares an immutable leaf when copied', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        @immutable
        final class Hardcover() extends Edition with HardcoverCharcoal;
        final class Ebook() extends Edition with EbookCharcoal;
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'final Hardcover $l => $l,'),
              contains(r'final Ebook $l => EbookCharcoal.$copy($l),'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('is immutable as a whole from the root', () async {
      final result = await build(
        '''
        $header
        @immutable
        @Charcoal()
        sealed class Edition();
        final class Hardcover() extends Edition with HardcoverCharcoal;
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('Edition copy() => this;'),
              contains('bool operator =='),
              isNot(contains('contentEquals')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('takes its options from wherever they are set', () async {
      final result = await build(
        '''
        $header
        @Charcoal(discriminator: 'kind', omit: Omit.none)
        sealed class Edition();
        @Charcoal(tag: "it's \\\$1")
        final class Hardcover(this.notes)
            extends Edition with HardcoverCharcoal {
          final String? notes;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"""'kind': 'it\'s \$1'"""),
              contains(r'''$sink.write('{"kind":"it\'s \$1","notes":');'''),
              contains(r"""'it\'s \$1' => HardcoverCharcoal.$decode($json)"""),
              contains(r"""'notes': $it.notes"""),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the discriminator from the config', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        final class Hardcover() extends Edition with HardcoverCharcoal;
        ''',
        config: {'discriminator': 'kind'},
        outputs: {output: decodedMatches(contains("'kind': 'Hardcover'"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('brings back an inherited default', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        sealed class Edition({this.year = first}) {
          static const first = 1;
          final int year;
        }
        final class Hardcover({super.year})
            extends Edition with HardcoverCharcoal;
        ''',
        outputs: {
          output: decodedMatches(
            contains(r'static const int $d0 = Edition.first;'),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('keeps what a superclass defines, over the mixin', () async {
      final result = await build(
        '''
        $header
        @immutable
        @Charcoal()
        sealed class Edition(this.id) {
          final int id;

          @override
          bool operator ==(Object other) => other is Edition && other.id == id;

          @override
          int get hashCode => id;

          @override
          String toString() => 'Edition';
        }
        final class Hardcover(super.id) extends Edition with HardcoverCharcoal;
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              isNot(contains('operator ==')),
              isNot(contains('get hashCode')),
              isNot(contains('String toString')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('fails the build on', () {
    test('a sealed class with no leaves', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        ''',
        'Edition is sealed, but has no classes to decode.',
      );
    });

    test('a leaf missing its mixin', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        final class Hardcover() extends Edition;
        ''',
        'Hardcover must declare `with HardcoverCharcoal`.',
      );
    });

    test('an abstract class that is not sealed in a family', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        abstract class Printed() extends Edition;
        ''',
        'Printed is abstract but not sealed',
      );
    });

    test('subclasses of a concrete class', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        class Book() with BookCharcoal;
        class Special() extends Book;
        ''',
        'Book has subclasses, so it must be sealed.',
      );
    });

    test('extending a sealed class no annotation covers', () async {
      await expectBuildError(
        '''
        $header
        sealed class Edition();
        @Charcoal()
        final class Hardcover() extends Edition with HardcoverCharcoal;
        ''',
        'Hardcover extends a class that no sealed @Charcoal class covers',
      );
    });

    test('duplicate tags', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        @Charcoal(tag: 'same')
        final class Hardcover() extends Edition with HardcoverCharcoal;
        @Charcoal(tag: 'same')
        final class Ebook() extends Edition with EbookCharcoal;
        ''',
        'Edition has two classes with the tag same.',
      );
    });

    test('a field named as the discriminator', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        final class Hardcover(this.type)
            extends Edition with HardcoverCharcoal {
          final String type;
        }
        ''',
        'Hardcover.type is named as the discriminator.',
      );
    });

    test('a discriminator anywhere but a root', () async {
      final result = await build('''
        $header
        @Charcoal()
        sealed class Edition();
        @Charcoal(discriminator: 'a')
        sealed class Digital() extends Edition;
        @Charcoal(discriminator: 'b')
        final class Ebook() extends Digital with EbookCharcoal;
        @Charcoal(discriminator: 'c')
        class Book() with BookCharcoal;
        ''');

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      for (final name in ['Digital', 'Ebook', 'Book']) {
        expect(errors, contains('$name sets a discriminator'));
      }
    });

    test('a tag anywhere but a leaf', () async {
      final result = await build('''
        $header
        @Charcoal(tag: 'a')
        sealed class Edition();
        final class Ebook() extends Edition with EbookCharcoal;
        @Charcoal(tag: 'b')
        class Book() with BookCharcoal;
        ''');

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      expect(errors, contains('Edition sets a tag'));
      expect(errors, contains('Book sets a tag'));
    });

    test('a leaf under two roots with different discriminators', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal(discriminator: 'a')
        sealed class Edition();
        @Charcoal(discriminator: 'b')
        sealed class Other();
        final class Ebook() extends Edition with EbookCharcoal implements Other;
        ''',
        'Ebook is under sealed classes with different discriminators',
      );
    });

    test('a field of a superclass left out of the constructor', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition(this.year) {
          final int year;
        }
        final class Ebook() extends Edition with EbookCharcoal {
          Ebook() : super(1);
        }
        ''',
        'Edition.year is not a constructor parameter of Ebook',
      );
    });

    test('a super parameter holding a field of another name', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition(this.year) {
          final int year;
        }
        final class Ebook(super.published) extends Edition with EbookCharcoal;
        ''',
        'Ebook.published must be a `this.published` or `super.published`',
      );
    });

    test('@immutable over a mutable family', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        sealed class Edition();
        final class Ebook() extends Edition with EbookCharcoal;
        @immutable
        @Charcoal()
        class Book(this.edition) with BookCharcoal {
          final Edition edition;
        }
        ''',
        'Book.edition holds a Edition, which is not @immutable',
      );
    });
  });
}
