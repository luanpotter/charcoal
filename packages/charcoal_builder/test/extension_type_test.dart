import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('extension types', () {
    const id = 'extension type Id<T>(int value) {}';

    test('unwrap and wrap, keeping phantom type arguments', () async {
      final result = await build(
        '''
        $header
        $id
        @Charcoal()
        class Book(this.id, this.parent) with BookCharcoal {
          final Id<Book> id;
          final Id<Book>? parent;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'id': $it.id"),
              contains(r"'parent': ?$it.parent"),
              contains(r"Id($json['id'] as int)"),
              contains(r'final $v => Id($v as int)'),
              contains(r'$sink.write($it.id.value);'),
              contains(r'$sink.write($v.value);'),
              contains(r'Id<Book>? $f0;'),
              contains(r'$f0 = Id($x0);'),
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
        class Book(this.main) with BookCharcoal {
          final Main main;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'main': $it.main.genre.name"),
              contains('Main(Genre.values.byName('),
              contains(r'$sink.write($it.main.genre.name);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('use a named primary constructor and private parts locally', () async {
      final result = await build(
        '''
        $header
        extension type Isbn._(String _text) {
          factory Isbn(String text) => Isbn._(text);
        }
        @Charcoal()
        class Book(this.isbn) with BookCharcoal {
          final Isbn isbn;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"Isbn._($json['isbn'] as String)"),
              contains(r'CharcoalJson.writeString($sink, $it.isbn._text);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fail the build when generated code cannot reach them', () async {
      final result = await build(
        '''
        import 'other.dart';
        $header
        extension type Box<T>(T value) {}
        @Charcoal()
        class Book(this.a, this.b, this.c) with BookCharcoal {
          final PrivateField a;
          final PrivateConstructor b;
          final Box<int> c;
        }
        ''',
        assets: {
          'package_name|lib/other.dart': '''
            extension type PrivateField(int _value) {}
            extension type PrivateConstructor._(int value) {}
          ''',
        },
      );

      final errors = result.errors.join('\n');
      expect(result.succeeded, isFalse);
      for (final field in 'abc'.split('')) {
        expect(errors, contains('Book.$field is a'));
      }
    });

    test('fail the build when named through a prefix', () async {
      final result = await build(
        '''
        import 'other.dart' as o;
        $header
        @Charcoal()
        class Book(this.a, this.b) with BookCharcoal {
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
