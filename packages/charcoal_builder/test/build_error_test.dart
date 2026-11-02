import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('refuses every other kind of type', () async {
    final result = await build('''
      import 'dart:async';
      import 'package:charcoal/charcoal.dart';
      part 'book.charcoal.g.dart';

      class String {}
      class Publisher {}
      extension type Id(Object value) {}

      @Charcoal()
      final class Book<T>(
        this.a, this.b, this.c, this.d, this.e, this.f, this.g,
        this.h, this.i, this.j, this.k, this.l, this.m,
      ) with BookCharcoal {
        final Object a;
        final Object? b;
        final dynamic c;
        final Null d;
        final Never e;
        final Function f;
        final Map<double, int> g;
        final (int, int) h;
        final FutureOr<int> i;
        final T j;
        final String k;
        final Publisher l;
        final Id m;
      }
      ''');

    final errors = result.errors.join('\n');
    expect(result.succeeded, isFalse);
    for (final field in 'abcdefghijklm'.split('')) {
      expect(errors, contains('Book.$field is a'));
    }
  });

  group('fails the build on', () {
    test('a missing part', () async {
      await expectBuildError(
        '''
        import 'package:charcoal/charcoal.dart';
        @Charcoal()
        final class Book() with BookCharcoal;
        ''',
        "Missing part: add `part 'book.charcoal.g.dart';`",
      );
    });

    test('a missing mixin', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book();
        ''',
        'Book must declare `with BookCharcoal`.',
      );
    });

    test('a class that is not final', () async {
      for (final modifier in ['', 'base ', 'interface ']) {
        await expectBuildError(
          '''
          $header
          @Charcoal()
          ${modifier}class Book() with BookCharcoal;
          ''',
          'Book must be final, or sealed',
        );
      }
    });

    test('a superclass', () async {
      await expectBuildError(
        '''
        $header
        class Publication {}
        @Charcoal()
        final class Book() extends Publication with BookCharcoal;
        ''',
        'Book extends a class',
      );
    });

    test('a private class', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class _Book() with _BookCharcoal;
        ''',
        '_Book is private',
      );
    });

    test('an abstract class', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        abstract class Book() with BookCharcoal;
        ''',
        'Book is abstract',
      );
    });

    test('a generic class', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book<T>() with BookCharcoal;
        ''',
        'Book is generic',
      );
    });

    test('no usable constructor', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book with BookCharcoal {
          Book.named();
        }
        ''',
        'Book has no usable constructor',
      );
    });

    test('a parameter with no field', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book with BookCharcoal {
          Book(String title);
        }
        ''',
        'Book.title must be a `this.title` or `super.title` parameter.',
      );
    });

    test('an unnamed factory chosen over a named primary', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book.of(this.title) with BookCharcoal {
          final String title;
          factory Book(String title) => Book.of(title);
        }
        ''',
        'Book.title must be a `this.title` or `super.title` parameter.',
      );
    });

    test('an unsupported field type', () async {
      await expectBuildError(
        '''
        $header
        class Publisher {}
        @Charcoal()
        final class Book(this.publisher) with BookCharcoal {
          final Publisher publisher;
        }
        ''',
        'Book.publisher is a Publisher, which charcoal cannot serialize.',
      );
    });

    test('a field outside the constructor', () async {
      await expectBuildError(
        '''
        $header
        @Charcoal()
        final class Book() with BookCharcoal {
          int pageCount = 0;
        }
        ''',
        'Book.pageCount is not a constructor parameter',
      );
    });

    test('every error in one run', () async {
      final result = await build('''
        import 'package:charcoal/charcoal.dart';
        @Charcoal()
        final class Book() {
          int pageCount = 0;
        }
        ''');

      expect(
        result.errors.join('\n'),
        allOf(
          contains('Missing part'),
          contains('must declare'),
          contains('Book.pageCount'),
        ),
      );
    });
  });
}
