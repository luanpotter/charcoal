import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('extension types', () {
    const id = 'extension type Id<T>(int value) {}';

    test('go through casts, keeping phantom type arguments', () async {
      final result = await build(
        '''
        $header
        $id
        @Charcoal()
        final class Book(this.id, this.parent) with BookCharcoal {
          final Id<Book> id;
          final Id<Book>? parent;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'id': $it.id"),
              contains(r"'parent': ?$it.parent"),
              contains(r"($json['id'] as int) as Id<Book>"),
              contains(r'final $v => ($v as int) as Id<Book>'),
              contains(r'$sink.write(($it.id as int));'),
              contains(r'$sink.write(($v as int));'),
              contains(r'Id<Book>? $f0;'),
              contains(r'$f0 = $x0 as Id<Book>;'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('convert a representation JSON cannot hold', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        extension type Main(Genre genre) {}
        @Charcoal()
        final class Book(this.main) with BookCharcoal {
          final Main main;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'main': EnumName(($it.main as Genre)).name"),
              contains(
                r"(Genre.values.byName($json['main'] as String)) as Main",
              ),
              contains(r'$sink.write(EnumName(($it.main as Genre)).name);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test(
      'never touch a private constructor or field, wherever it is',
      () async {
        final result = await build(
          '''
        import 'other.dart';
        $header
        @Charcoal()
        final class Book(this.a, this.b) with BookCharcoal {
          final PrivateField a;
          final PrivateConstructor b;
        }
        ''',
          assets: {
            'package_name|lib/other.dart': '''
            extension type PrivateField(int _value) {}
            extension type PrivateConstructor._(int value) {}
          ''',
          },
          outputs: {
            output: decodedMatches(
              allOf([
                contains(r"($json['a'] as int) as PrivateField"),
                contains(r"($json['b'] as int) as PrivateConstructor"),
                isNot(contains('_value')),
                isNot(contains('PrivateConstructor._')),
              ]),
            ),
          },
        );

        expect(result.succeeded, isTrue);
      },
    );

    test('fail the build on a type parameter as representation', () async {
      await expectBuildError(
        '''
        $header
        extension type Box<T>(T value) {}
        @Charcoal()
        final class Book(this.box) with BookCharcoal {
          final Box<int> box;
        }
        ''',
        'Book.box is a',
      );
    });

    test('fail the build when named through a prefix', () async {
      final result = await build(
        '''
        import 'other.dart' as o;
        $header
        @Charcoal()
        final class Book(this.a, this.b) with BookCharcoal {
          final o.Id a;
          final Tagged<o.Tag> b;
        }
        extension type Tagged<T>(int value) {}
        ''',
        assets: {
          'package_name|lib/other.dart': '''
            class Tag {}
            extension type Id(int value) {}
          ''',
        },
      );

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      expect(errors, contains('Book.a is a'));
      expect(errors, contains('Book.b is a'));
    });
  });
}
