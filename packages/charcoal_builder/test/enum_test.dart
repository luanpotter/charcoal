import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('enums', () {
    const genre = 'enum Genre { fantasy, sciFi }';

    test('go by name, with no escaping', () async {
      final result = await build(
        '''
        $header
        $genre
        @Charcoal()
        class Book(this.genre, this.subgenre) with BookCharcoal {
          final Genre genre;
          final Genre? subgenre;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'genre': $it.genre.name"),
              contains(r"'subgenre': ?$it.subgenre?.name"),
              contains(r"Genre.values.byName($json['genre'] as String)"),
              contains(r'final $v => Genre.values.byName($v as String)'),
              contains(r'''$sink.write('{"genre":"');'''),
              contains(r'$sink.write($it.genre.name);'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can come from another library', () async {
      final result = await build(
        '''
        import 'genre.dart';
        $header
        @Charcoal()
        class Book(this.genre) with BookCharcoal {
          final Genre genre;
        }
        ''',
        assets: {'package_name|lib/genre.dart': genre},
        outputs: {output: decodedMatches(contains('Genre.values.byName'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('fail the build when imported with a prefix', () async {
      final result = await build(
        '''
        import 'genre.dart' as g;
        $header
        @Charcoal()
        class Book(this.genre) with BookCharcoal {
          final g.Genre genre;
        }
        ''',
        assets: {'package_name|lib/genre.dart': genre},
      );

      expect(result.succeeded, isFalse);
      expect(result.errors.join('\n'), contains('Book.genre is a Genre'));
    });

    test('fail the build when overriding name', () async {
      await expectBuildError(
        '''
        $header
        enum Genre {
          fantasy;
          String get name => 'a"b';
        }
        @Charcoal()
        class Book(this.genre) with BookCharcoal {
          final Genre genre;
        }
        ''',
        'Book.genre is a Genre',
      );
    });
  });
}
