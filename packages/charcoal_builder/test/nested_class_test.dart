import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('nested classes', () {
    const author = '''
      import 'package:charcoal/charcoal.dart';
      part 'author.charcoal.g.dart';
      @Charcoal()
      class Author(this.name) with AuthorCharcoal {
        final String name;
      }
    ''';
    const assets = {'package_name|lib/author.dart': author};
    final authorOutput = {'package_name|lib/author.charcoal.g.dart': anything};

    test('call the generated code of the other class', () async {
      final result = await build(
        '''
        import 'author.dart';
        $header
        @Charcoal()
        class Book(this.author, this.editor) with BookCharcoal {
          final Author author;
          final Author? editor;
        }
        ''',
        assets: assets,
        outputs: {
          ...authorOutput,
          output: decodedMatches(
            allOf([
              contains(r"'author': AuthorCharcoal.$encode($it.author)"),
              contains(r'final $v => AuthorCharcoal.$encode($v)'),
              contains(r'AuthorCharcoal.$write($it.author, $sink);'),
              contains(r'AuthorCharcoal.$write($v, $sink);'),
              contains(
                r"AuthorCharcoal.$decode($json['author'] "
                'as Map<String, Object?>)',
              ),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can refer to themselves', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        class Book(this.sequel) with BookCharcoal {
          final Book? sequel;
        }
        ''',
        outputs: {
          output: decodedMatches(contains(r'BookCharcoal.$write($v, $sink);')),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('fail the build when imported with a prefix', () async {
      final result = await build(
        '''
        import 'author.dart' as a;
        $header
        @Charcoal()
        class Book(this.author) with BookCharcoal {
          final a.Author author;
        }
        ''',
        assets: assets,
        outputs: authorOutput,
      );

      expect(result.succeeded, isFalse);
      expect(result.errors.join('\n'), contains('Book.author is a Author'));
    });

    test('fail to compile when their mixin is hidden', () async {
      final result = await build(
        '''
        import 'author.dart' show Author;
        $header
        @Charcoal()
        class Book(this.author) with BookCharcoal {
          final Author author;
        }
        ''',
        assets: assets,
        outputs: {...authorOutput, output: anything},
      );

      expect(result.succeeded, isFalse);
      expect(
        result.errors.join('\n'),
        contains('Generated code fails to compile'),
      );
    });

    test('fail the build when generic', () async {
      final result = await build('''
        $header
        @Charcoal()
        class Book(this.author) with BookCharcoal {
          final Author<int> author;
        }
        @Charcoal()
        class Author<T>() with AuthorCharcoal;
        ''');

      expect(result.succeeded, isFalse);
      expect(
        result.errors.join('\n'),
        contains('Book.author is a Author<int>'),
      );
    });
  });
}
