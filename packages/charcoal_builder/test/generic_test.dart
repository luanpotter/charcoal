import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('a generic class', () {
    const ranked =
        '''
      $header
      enum Genre { fantasy }
      @immutable
      @Charcoal()
      final class Ranked<T>(this.item, this.rank, {this.runnerUp})
          with RankedCharcoal<T> {
        final T item;
        final int rank;
        final Ranked<T>? runnerUp;
      }
    ''';

    test('has copy and equality, but no JSON of its own', () async {
      final result = await build(
        ranked,
        outputs: {
          output: decodedMatches(
            allOf([
              contains('mixin RankedCharcoal<T> {'),
              contains('Ranked<T> copy() => this as Ranked<T>;'),
              contains(r'static bool $equals<T>(Ranked<T> $a, Ranked<T> $b)'),
              contains(r'if ($a.item != $b.item) return false;'),
              contains(r'item is _$Keep ? _$it.item : item as T'),
              contains('Ranked<T> Function({T item, int rank, '),
              isNot(contains('toMap')),
              isNot(contains('toJsonString')),
              isNot(contains('fromMap')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('keeps the bounds of its type parameters', () async {
      final result = await build(
        '''
        $header
        @Charcoal()
        final class Ranked<T extends num>(this.item) with RankedCharcoal<T> {
          final T item;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains('mixin RankedCharcoal<T extends num> {'),
              contains(r'static Ranked<T> $copy<T extends num>('),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('generates the code of each use in the holder', () async {
      final result = await build(
        '''
        $ranked
        @Charcoal()
        final class Book(this.topGenre, this.topName, this.others)
            with BookCharcoal {
          final Ranked<Genre> topGenre;
          final Ranked<String>? topName;
          final List<Ranked<Genre>> others;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r"'topGenre': _$Ranked0.$encode($it.topGenre)"),
              contains(r'_$Ranked0.$write($it.topGenre, $sink);'),
              contains(r'final $v => _$Ranked1.$encode($v)'),
              contains(r'abstract final class _$Ranked0 {'),
              contains(r'abstract final class _$Ranked1 {'),
              isNot(contains(r'_$Ranked2')),
              contains(r"'item': EnumName($it.item).name"),
              contains(r"Genre.values.byName($json['item'] as String)"),
              contains(r"'item': $it.item"),
              contains(r'static Ranked<Genre> $decode('),
              contains(r'_$Ranked0.$decode($v as Map<String, Object?>)'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('can come from another library', () async {
      final result = await build(
        '''
        import 'ranked.dart';
        $header
        @Charcoal()
        final class Book(this.top) with BookCharcoal {
          final Ranked<int> top;
        }
        ''',
        assets: {
          'package_name|lib/ranked.dart': '''
            import 'package:charcoal/charcoal.dart';
            part 'ranked.charcoal.g.dart';
            @Charcoal()
            final class Ranked<T>(this.item) with RankedCharcoal<T> {
              final T item;
            }
          ''',
        },
        outputs: {
          'package_name|lib/ranked.charcoal.g.dart': anything,
          output: decodedMatches(contains(r'abstract final class _$Ranked0')),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('compares by value only if what it holds does too', () async {
      final result = await build(
        '''
        $ranked
        @Charcoal()
        final class Author() with AuthorCharcoal;
        @Charcoal()
        final class Book(this.byValue, this.byList, this.byAuthor)
            with BookCharcoal {
          final Ranked<int> byValue;
          final Ranked<List<int>> byList;
          final Ranked<Author> byAuthor;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'if ($a.byValue != $b.byValue) return false;'),
              contains(r'_$Ranked1.$equals($a.byList, $b.byList)'),
              contains(r'_$Ranked2.$equals($a.byAuthor, $b.byAuthor)'),
              contains(r'_$Ranked1.$copy($it.byList)'),
              contains(r'AuthorCharcoal.$copy($it.item)'),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    group('ends, however it holds itself, if nothing grows', () {
      test('swapping its type parameters', () async {
        final result = await build(
          '''
          $header
          @Charcoal()
          final class Pair<A, B>(this.swapped) with PairCharcoal<A, B> {
            final Pair<B, A>? swapped;
          }
          @Charcoal()
          final class Book(this.pair) with BookCharcoal {
            final Pair<int, String> pair;
          }
          ''',
          outputs: {
            output: decodedMatches(
              allOf([
                contains(r'abstract final class _$Pair0'),
                contains(r'abstract final class _$Pair1'),
                isNot(contains(r'_$Pair2')),
              ]),
            ),
          },
        );

        expect(result.succeeded, isTrue);
      });

      test('making its type parameter nullable', () async {
        final result = await build(
          '''
          $header
          @Charcoal()
          final class Box<T>(this.next) with BoxCharcoal<T> {
            final Box<T?>? next;
          }
          @Charcoal()
          final class Book(this.box) with BookCharcoal {
            final Box<int> box;
          }
          ''',
          outputs: {
            output: decodedMatches(
              allOf([
                contains(r'static Box<int> $decode('),
                contains(r'static Box<int?> $decode('),
              ]),
            ),
          },
        );

        expect(result.succeeded, isTrue);
      });

      test('wrapping it once, outside of any cycle', () async {
        final result = await build(
          '''
          $header
          @Charcoal()
          final class Inner<U>(this.value) with InnerCharcoal<U> {
            final U value;
          }
          @Charcoal()
          final class Outer<T>(this.inner, this.next) with OuterCharcoal<T> {
            final Inner<List<T>> inner;
            final Outer<T>? next;
          }
          @Charcoal()
          final class Book(this.outer) with BookCharcoal {
            final Outer<int> outer;
          }
          ''',
          outputs: {
            output: decodedMatches(
              contains(r'static Inner<List<int>> $decode('),
            ),
          },
        );

        expect(result.succeeded, isTrue);
      });

      test('with as many uses as it takes', () async {
        final count = List.generate(100, (index) => index);
        final result = await build(
          '''
          $header
          @Charcoal()
          final class Box<T>(this.value) with BoxCharcoal<T> {
            final T value;
          }
          ${count.map((index) => 'enum E$index { a }').join('\n')}
          @Charcoal()
          final class Book(
            ${count.map((index) => 'this.f$index').join(', ')},
          ) with BookCharcoal {
            ${count.map((index) => 'final Box<E$index> f$index;').join('\n')}
          }
          ''',
          outputs: {output: decodedMatches(contains(r'_$Box99'))},
        );

        expect(result.succeeded, isTrue);
      });
    });

    group('fails the build on', () {
      test('a type argument it cannot serialize', () async {
        await expectBuildError(
          '''
          $ranked
          class Publisher {}
          @Charcoal()
          final class Book(this.top) with BookCharcoal {
            final Ranked<Publisher> top;
          }
          ''',
          'Book.top is a Ranked<Publisher>',
        );
      });

      test('a field it cannot serialize, naming the use', () async {
        await expectBuildError(
          '''
          $ranked
          @Charcoal()
          final class Book(this.top) with BookCharcoal {
            final Ranked<Set<Ranked<List<int>>>> top;
          }
          ''',
          'Ranked<Set<Ranked<List<int>>>>.item has a Set of values',
        );
      });

      test('a mutable type argument in an immutable holder', () async {
        await expectBuildError(
          '''
          $ranked
          @Charcoal()
          final class Author() with AuthorCharcoal;
          @immutable
          @Charcoal()
          final class Book(this.top) with BookCharcoal {
            final Ranked<Author> top;
          }
          ''',
          'Book.top holds a Author, which is not @immutable',
        );
      });

      test('type arguments that never stop growing', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          final class Nested<T>(this.deeper) with NestedCharcoal<T> {
            final Nested<List<T>>? deeper;
          }
          @Charcoal()
          final class Book(this.nested) with BookCharcoal {
            final Nested<int> nested;
          }
          ''',
          'Nested cannot be generated for each use, '
              'as it needs a Nested<List<T>>?',
        );
      });

      test('growth through another class', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          final class Outer<T>(this.inner) with OuterCharcoal<T> {
            final Inner<List<T>>? inner;
          }
          @Charcoal()
          final class Inner<U>(this.outer) with InnerCharcoal<U> {
            final Outer<U>? outer;
          }
          @Charcoal()
          final class Book(this.outer) with BookCharcoal {
            final Outer<int> outer;
          }
          ''',
          'Outer cannot be generated for each use',
        );
      });

      test('growth through a sealed leaf', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          sealed class Tree<T>();
          final class Branch<V>(this.next) extends Tree<V> with BranchCharcoal<V> {
            final Tree<Set<V>>? next;
          }
          @Charcoal()
          final class Book(this.tree) with BookCharcoal {
            final Tree<int> tree;
          }
          ''',
          'Tree cannot be generated for each use',
        );
      });

      test('a private constructor in another library', () async {
        final result = await build(
          '''
          import 'ranked.dart';
          $header
          @Charcoal()
          final class Book(this.top) with BookCharcoal {
            final Ranked<int> top;
          }
          ''',
          assets: {
            'package_name|lib/ranked.dart': '''
              import 'package:charcoal/charcoal.dart';
              part 'ranked.charcoal.g.dart';
              @Charcoal()
              final class Ranked<T>._(this.item) with RankedCharcoal<T> {
                final T item;
              }
            ''',
          },
          outputs: {'package_name|lib/ranked.charcoal.g.dart': anything},
        );

        expect(result.succeeded, isFalse);
        expect(
          result.errors.join('\n'),
          contains('Ranked<int> has no constructor this library can call.'),
        );
      });
    });
  });

  group('a generic sealed family', () {
    const lookup =
        '''
      $header
      @Charcoal()
      sealed class Lookup<T>();
      final class Known<T>(this.value) extends Lookup<T> with KnownCharcoal<T> {
        final T value;
      }
      final class Unknown() extends Lookup<Never> with UnknownCharcoal;
      final class Estimated(this.low)
          extends Lookup<int> with EstimatedCharcoal {
        final int low;
      }
    ''';

    test('has copy and equality, but no JSON of its own', () async {
      final result = await build(
        lookup,
        outputs: {
          output: decodedMatches(
            allOf([
              contains('extension LookupCharcoalMembers<T> on Lookup<T> {'),
              contains(r'static bool $equals<T>(Lookup<T> $a, Lookup<T> $b)'),
              contains(r'final Known<T> $l => switch ($b) {'),
              contains(r'final Known<T> $r => KnownCharcoal.$equals($l, $r)'),
              contains(r'final Estimated $l => switch ($b) {'),
              contains(r'KnownCharcoal.$copy($l) as Lookup<T>'),
              isNot(contains(r'LookupCharcoal.$encode')),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('only switches over the leaves that fit each use', () async {
      final result = await build(
        '''
        $lookup
        @Charcoal()
        final class Book(this.sold, this.title) with BookCharcoal {
          final Lookup<int> sold;
          final Lookup<String> title;
        }
        ''',
        outputs: {
          output: decodedMatches(
            allOf([
              contains(r'static Lookup<int> $decode('),
              contains(r'final Known<int> $l =>'),
              contains(r'final Estimated $l => EstimatedCharcoal.$encode($l)'),
              contains(r'static Lookup<String> $decode('),
              contains(r'final Known<String> $l =>'),
              contains(r'final Unknown $l => UnknownCharcoal.$encode($l)'),
              contains(r"final $tag = $r.peekStringField('type');"),
            ]),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    group('fails the build on', () {
      test('a use no leaf fits', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          sealed class Lookup<T>();
          final class Estimated() extends Lookup<int> with EstimatedCharcoal;
          @Charcoal()
          final class Book(this.title) with BookCharcoal {
            final Lookup<String> title;
          }
          ''',
          'Lookup<String> has no class below it that fits.',
        );
      });

      test('a generic leaf under a family that is not', () async {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          sealed class Edition();
          final class Boxed<T>(this.item)
              extends Edition with BoxedCharcoal<T> {
            final T item;
          }
          ''',
          'Boxed is generic but Edition is not',
        );
      });
    });
  });
}
