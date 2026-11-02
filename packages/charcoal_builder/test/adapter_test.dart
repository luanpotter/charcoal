import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('adapters', () {
    const adapter = '''
      class Stamp {}
      class const StampAdapter() implements CharcoalAdapter<Stamp, int> {
        @override
        int encode(Stamp value) => 1;
        @override
        Stamp decode(int json) => Stamp();
      }
    ''';

    test('are called directly, at any depth', () async {
      final result = await build(
        '''
        $header
        $adapter
        @Charcoal()
        final class Book(this.a, this.b, this.c) with BookCharcoal {
          final Stamp a;
          final Stamp? b;
          final List<Stamp> c;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'a': const StampAdapter().encode($it.a)"),
              contains(r'final $v => const StampAdapter().encode($v)'),
              contains(r'const StampAdapter().encode($e0)'),
              contains(r"const StampAdapter().decode($json['a'] as int)"),
              contains(r'$sink.write(const StampAdapter().encode($it.a));'),
              contains(r'$f0 = const StampAdapter().decode($x0);'),
              contains(r'Stamp? $f0;'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('take precedence over what charcoal would do', () async {
      final result = await build(
        '''
        $header
        enum Genre { fantasy }
        class const GenreAdapter() implements CharcoalAdapter<Genre, int> {
          @override
          int encode(Genre value) => value.index;
          @override
          Genre decode(int json) => Genre.values[json];
        }
        @Charcoal()
        final class Book(this.genre) with BookCharcoal {
          final Genre genre;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('const GenreAdapter().encode'),
              isNot(contains('byName')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    const stamps = {
      'package_name|lib/stamp.dart':
          '''
          import 'package:charcoal/charcoal.dart';
          $adapter
          ''',
    };
    const book = '''
      @Charcoal()
      final class Book(this.a) with BookCharcoal {
        final Stamp a;
      }
    ''';

    test('come along with the type they adapt', () async {
      final result = await build(
        '''
        import 'stamp.dart';
        $header
        $book
        ''',
        assets: stamps,
        outputs: {output: decodedMatches(contains('const StampAdapter()'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('can be bundled through a re-export', () async {
      final result = await build(
        '''
        import 'bundle.dart';
        part 'book.charcoal.g.dart';
        $book
        ''',
        assets: {
          ...stamps,
          'package_name|lib/bundle.dart': '''
            export 'package:charcoal/charcoal.dart';
            export 'stamp.dart';
          ''',
        },
        outputs: {output: decodedMatches(contains('const StampAdapter()'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('are not used when hidden', () async {
      final result = await build(
        '''
        import 'stamp.dart' hide StampAdapter;
        $header
        $book
        ''',
        assets: stamps,
      );

      expect(result.succeeded, isFalse);
      expect(
        result.errors.join('\n'),
        allOf(
          contains('Book.a is a Stamp, which charcoal cannot serialize.'),
          contains('this library needs to import it'),
        ),
      );
    });

    test('ship with charcoal for common types', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Book(
          this.date,
          this.uri,
          this.delay,
          this.big,
        ) with BookCharcoal {
          final DateTime date;
          final Uri? uri;
          final Duration delay;
          final BigInt big;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'date': const DateTimeAdapter().encode($it.date)"),
              contains(r'final $v => const UriAdapter().encode($v)'),
              contains(r'$sink.write(const DurationAdapter().encode('),
              contains(r'writeString($sink, const BigIntAdapter().encode('),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can replace what ships, through a re-export', () async {
      const mine = '''
        class const MyDate() implements CharcoalAdapter<DateTime, int> {
          @override
          int encode(DateTime value) => value.millisecondsSinceEpoch;
          @override
          DateTime decode(int json) {
            return DateTime.fromMillisecondsSinceEpoch(json);
          }
        }
      ''';
      final result = await build(
        '''
        import 'bundle.dart';
        part 'book.charcoal.g.dart';
        @Charcoal()
        final class Book(this.date) with BookCharcoal {
          final DateTime date;
        }
        ''',
        assets: {
          'package_name|lib/mine.dart':
              '''
              import 'package:charcoal/charcoal.dart';
              $mine
              ''',
          'package_name|lib/bundle.dart': '''
            export 'package:charcoal/charcoal.dart' hide DateTimeAdapter;
            export 'mine.dart';
          ''',
        },
        outputs: {
          output: decodedMatches(
            allOf([
              contains('const MyDate().encode'),
              isNot(contains('DateTimeAdapter')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('conflict with what ships when not hidden', () async {
      await expectBuildError(
        '''
        $header
        class const MyDate() implements CharcoalAdapter<DateTime, int> {
          @override
          int encode(DateTime value) => 1;
          @override
          DateTime decode(int json) => DateTime(2000);
        }
        @Charcoal()
        final class Book(this.date) with BookCharcoal {
          final DateTime date;
        }
        ''',
        'There are two adapters for DateTime in scope',
      );
    });

    test('are not used through a prefix', () async {
      final result = await build(
        '''
        import 'stamp.dart' show Stamp;
        import 'stamp.dart' as s show StampAdapter;
        $header
        $book
        ''',
        assets: stamps,
      );

      expect(result.succeeded, isFalse);
      expect(result.errors.join('\n'), contains('Book.a is a Stamp'));
    });

    test('are ignored when abstract', () async {
      final result = await build(
        '''
        $header
        $adapter
        abstract class Other implements CharcoalAdapter<Stamp, String> {}
        $book
        ''',
        outputs: {output: decodedMatches(contains('const StampAdapter()'))},
      );

      expect(result.succeeded, isTrue);
    });

    test('in scope but unused do not fail the build', () async {
      final result = await build(
        '''
        $header
        class const Broken(this.value)
            implements CharcoalAdapter<DateTime, Object> {
          final int value;
          @override
          Object encode(DateTime value) => 1;
          @override
          DateTime decode(Object json) => DateTime(2000);
        }
        @Charcoal()
        final class Book(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {output: anything},
      );

      expect(result.succeeded, isTrue);
    });

    group('fail the build on', () {
      Future<void> expectAdapterError(String code, String message) async {
        await expectBuildError('''
          $header
          class Stamp {}
          $code
          @Charcoal()
          final class Book(this.a) with BookCharcoal {
            final Stamp a;
          }
          ''', message);
      }

      const body = '''
        @override
        int encode(Stamp value) => 1;
        @override
        Stamp decode(int json) => Stamp();
      ''';

      test('a constructor with arguments', () async {
        await expectBuildError(
          '''
          $header
          class Stamp {}
          class const A([this.b = 1]) implements CharcoalAdapter<Stamp, int> {
            final int b;
            $body
          }
          @Charcoal()
          final class Book(this.a) with BookCharcoal {
            final Stamp a;
          }
          ''',
          'needs a const constructor with no arguments',
        );
      });

      test('type parameters', () async {
        await expectAdapterError(
          '''
          class const A<T>() implements CharcoalAdapter<Stamp, int> {
            $body
          }
          ''',
          'no type parameters',
        );
      });

      test('a wire type charcoal cannot serialize', () async {
        await expectAdapterError(
          '''
          class const A() implements CharcoalAdapter<Stamp, Object> {
            @override
            Object encode(Stamp value) => 1;
            @override
            Stamp decode(Object json) => Stamp();
          }
          ''',
          'The adapter A writes a Object',
        );
      });

      test('a collection as wire type', () async {
        await expectAdapterError(
          '''
          class const A() implements CharcoalAdapter<Stamp, List<int>> {
            @override
            List<int> encode(Stamp value) => [];
            @override
            Stamp decode(List<int> json) => Stamp();
          }
          ''',
          'it can only write an int, a double, a String or a bool',
        );
      });

      test('a @Charcoal class', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          final class Stamp() with StampCharcoal;
          class const A() implements CharcoalAdapter<Stamp, int> {
            $body
          }
          @Charcoal()
          final class Book(this.a) with BookCharcoal {
            final Stamp a;
          }
          ''',
          'The adapter A is for Stamp, which already is a @Charcoal class.',
        );
      });

      test('a nullable adapted type', () async {
        await expectAdapterError(
          '''
          class const A() implements CharcoalAdapter<Stamp?, int> {
            @override
            int encode(Stamp? value) => 1;
            @override
            Stamp? decode(int json) => null;
          }
          ''',
          'must adapt a non-nullable type',
        );
      });

      test('two adapters for one type', () async {
        await expectBuildError(
          '''
          $header
          $adapter
          class const Other() implements CharcoalAdapter<Stamp, int> {
            @override
            int encode(Stamp value) => 1;
            @override
            Stamp decode(int json) => Stamp();
          }
          @Charcoal()
          final class Book(this.a) with BookCharcoal {
            final Stamp a;
          }
          ''',
          'There are two adapters for Stamp in scope: StampAdapter, Other.',
        );
      });
    });
  });
}
