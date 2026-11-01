import 'package:build_test/build_test.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';
import 'package:test/test.dart';

const _output = 'package_name|lib/book.charcoal.g.dart';
const _header = """
import 'package:charcoal/charcoal.dart';
part 'book.charcoal.g.dart';
""";

Future<TestBuilderResult> _build(
  String source, {
  Map<String, Object> outputs = const {},
  Map<String, dynamic> config = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'package_name');
  await readerWriter.testing.loadIsolateSources();
  return testBuilder(
    CharcoalBuilder(config: CharcoalConfig.fromMap(config)),
    {'package_name|lib/book.dart': source},
    outputs: outputs,
    readerWriter: readerWriter,
  );
}

Future<void> _expectError(String source, String message) async {
  final result = await _build(source);

  expect(result.succeeded, isFalse);
  expect(result.errors.join('\n'), contains(message));
}

void main() {
  group('generates', () {
    const book =
        '''
      $_header
      @Charcoal()
      class Book({required this.title, required this.rating, this.note})
          with BookCharcoal {
        final String title;
        final double rating;
        final double? note;
      }
      ''';

    test('a formatted part with a header', () async {
      final result = await _build(
        book,
        outputs: {
          _output: decodedMatches(
            allOf(
              startsWith('// dart format width=120\n'),
              contains('// GENERATED CODE'),
              contains("part of 'book.dart';"),
              contains('mixin BookCharcoal {'),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('an encoder, dropping nulls', () async {
      final result = await _build(
        book,
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r'toMap() => $encode(this as Book);'),
              contains(r"'title': $it.title"),
              contains(r"'note': ?$it.note"),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('a decoder, converting doubles', () async {
      final result = await _build(
        book,
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r"title: $json['title'] as String"),
              contains(r"rating: ($json['rating'] as num).toDouble()"),
              contains(r'final $v => ($v as num).toDouble()'),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('positional parameters and a named primary constructor', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book.of(this.title) with BookCharcoal {
          final String title;
        }
        ''',
        outputs: {_output: decodedMatches(contains(r"Book.of($json['title']"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('one mixin per annotated class, skipping others', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book() with BookCharcoal;
        class Publisher {}
        @Charcoal()
        class Author() with AuthorCharcoal;
        ''',
        outputs: {
          _output: decodedMatches(
            allOf(
              contains('mixin BookCharcoal'),
              contains('mixin AuthorCharcoal'),
              isNot(contains('PublisherCharcoal')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('only constructor fields, leaving derived ones out', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.title) with BookCharcoal {
          static const shelfLife = 1;
          final String title;
          late final int length = title.length;
          String get upper => title.toUpperCase();
        }
        ''',
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r"'title': $it.title"),
              isNot(contains('shelfLife')),
              isNot(contains('length')),
              isNot(contains('upper')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('generates nothing for', () {
    test('a library without annotated classes', () async {
      final result = await _build('class Book {}');

      expect(result.succeeded, isTrue);
    });

    test('another annotation named Charcoal', () async {
      final result = await _build('''
        class Charcoal {
          const Charcoal();
        }
        @Charcoal()
        class Book {}
        ''');

      expect(result.succeeded, isTrue);
    });

    test('part files', () async {
      final result = await testBuilder(CharcoalBuilder(), {
        'package_name|lib/book.dart': "part 'publisher.dart';",
        'package_name|lib/publisher.dart': "part of 'book.dart';",
      }, outputs: {});

      expect(result.succeeded, isTrue);
    });
  });

  group('direct writer', () {
    test('merges adjacent literals', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.title, this.pages) with BookCharcoal {
          final String title;
          final int pages;
        }
        ''',
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r'''$sink.write('{"title":');'''),
              contains(r'''$sink.write(',"pages":');'''),
              isNot(contains(r'$comma')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('writes an empty class as one literal', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book() with BookCharcoal;
        ''',
        outputs: {_output: decodedMatches(contains(r"$sink.write('{}');"))},
      );

      expect(result.succeeded, isTrue);
    });

    test('needs no flag when a later field is certain', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.note, this.title, this.subtitle) with BookCharcoal {
          final String? note;
          final String title;
          final String? subtitle;
        }
        ''',
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r"$sink.write(',');"),
              contains(r'''$sink.write('"title":');'''),
              contains(r'''$sink.write(',"subtitle":');'''),
              isNot(contains(r'$comma')),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('needs no flag for a single droppable field', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.note) with BookCharcoal {
          final String? note;
        }
        ''',
        outputs: {_output: decodedMatches(isNot(contains(r'$comma')))},
      );

      expect(result.succeeded, isTrue);
    });

    test('uses a flag only when every field may drop', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.note, this.subtitle) with BookCharcoal {
          final String? note;
          final String? subtitle;
        }
        ''',
        outputs: {
          _output: decodedMatches(
            allOf(
              contains(r'var $comma = false;'),
              contains(r"if ($comma) $sink.write(',');"),
            ),
          ),
        },
      );

      expect(result.succeeded, isTrue);
    });

    test('escapes a dollar in a key', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal()
        class Book(this.\$count) with BookCharcoal {
          final int \$count;
        }
        ''',
        outputs: {_output: decodedMatches(contains(r'''{"\$count":'''))},
      );

      expect(result.succeeded, isTrue);
    });
  });

  group('omit', () {
    const book =
        '''
      $_header
      @Charcoal()
      class Book(this.note) with BookCharcoal {
        final String? note;
      }
      ''';
    const keepsNulls = r"'note': $it.note";
    const dropsNulls = r"'note': ?$it.note";

    test('drops nulls by default', () async {
      final result = await _build(
        book,
        outputs: {_output: decodedMatches(contains(dropsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the default from the config', () async {
      final result = await _build(
        book,
        config: {'omit': 'none'},
        outputs: {_output: decodedMatches(contains(keepsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the annotation over the config', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal(omit: Omit.nulls)
        class Book(this.note) with BookCharcoal {
          final String? note;
        }
        ''',
        config: {'omit': 'none'},
        outputs: {_output: decodedMatches(contains(dropsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('takes the annotation over the default', () async {
      final result = await _build(
        '''
        $_header
        @Charcoal(omit: Omit.none)
        class Book(this.note) with BookCharcoal {
          final String? note;
        }
        ''',
        outputs: {_output: decodedMatches(contains(keepsNulls))},
      );

      expect(result.succeeded, isTrue);
    });

    test('refuses an unknown config value', () {
      expect(
        () => CharcoalConfig.fromMap({'omit': 'everything'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses an unknown config key', () {
      expect(
        () => CharcoalConfig.fromMap({'discriminator': 'type'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  test('reads every primitive, nullable or aliased', () async {
    final result = await _build(
      '''
      $_header
      typedef Title = String;
      @Charcoal()
      class Book(
        this.a, this.b, this.c, this.d, this.e,
        this.f, this.g, this.h, this.i, this.j, this.k,
      ) with BookCharcoal {
        final String a;
        final int b;
        final double c;
        final num d;
        final bool e;
        final String? f;
        final int? g;
        final double? h;
        final num? i;
        final bool? j;
        final Title k;
      }
      ''',
      outputs: {
        _output: decodedMatches(
          allOf([
            contains(r"$json['a'] as String"),
            contains(r"$json['b'] as int"),
            contains(r"($json['c'] as num).toDouble()"),
            contains(r"$json['d'] as num"),
            contains(r"$json['e'] as bool"),
            contains(r"'f': ?$it.f"),
            contains(r'final $v => $v as bool'),
            contains(r"$json['k'] as String"),
          ]),
        ),
      },
    );

    expect(result.succeeded, isTrue);
  });

  test('refuses every other kind of type', () async {
    final result = await _build('''
      import 'dart:async';
      import 'package:charcoal/charcoal.dart';
      part 'book.charcoal.g.dart';

      class String {}
      class Publisher {}
      enum Genre { fantasy }
      extension type Id(int value) {}

      @Charcoal()
      class Book<T>(
        this.a, this.b, this.c, this.d, this.e, this.f, this.g,
        this.h, this.i, this.j, this.k, this.l, this.m, this.n,
      ) with BookCharcoal {
        final Object a;
        final Object? b;
        final dynamic c;
        final Null d;
        final Never e;
        final Function f;
        final List<int> g;
        final (int, int) h;
        final FutureOr<int> i;
        final T j;
        final String k;
        final Publisher l;
        final Genre m;
        final Id n;
      }
      ''');

    final errors = result.errors.join('\n');
    expect(result.succeeded, isFalse);
    for (final field in 'abcdefghijklmn'.split('')) {
      expect(errors, contains('Book.$field is a'));
    }
  });

  group('fails the build on', () {
    test('a missing part', () async {
      await _expectError(
        '''
        import 'package:charcoal/charcoal.dart';
        @Charcoal()
        class Book() with BookCharcoal;
        ''',
        "Missing part: add `part 'book.charcoal.g.dart';`",
      );
    });

    test('a missing mixin', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book();
        ''',
        'Book must declare `with BookCharcoal`.',
      );
    });

    test('a private class', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class _Book() with _BookCharcoal;
        ''',
        '_Book is private',
      );
    });

    test('an abstract class', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        abstract class Book() with BookCharcoal;
        ''',
        'Book is abstract',
      );
    });

    test('a generic class', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book<T>() with BookCharcoal;
        ''',
        'Book is generic',
      );
    });

    test('a superclass', () async {
      await _expectError(
        '''
        $_header
        class Publication {}
        @Charcoal()
        class Book() extends Publication with BookCharcoal;
        ''',
        'Book extends a class',
      );
    });

    test('no usable constructor', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book with BookCharcoal {
          Book.named();
        }
        ''',
        'Book has no usable constructor',
      );
    });

    test('a parameter with no field', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book with BookCharcoal {
          Book(String title);
        }
        ''',
        'Book.title must be a `this.title` parameter.',
      );
    });

    test('an unnamed factory chosen over a named primary', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book.of(this.title) with BookCharcoal {
          final String title;
          factory Book(String title) => Book.of(title);
        }
        ''',
        'Book.title must be a `this.title` parameter.',
      );
    });

    test('a parameter default', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book({this.pages = 1}) with BookCharcoal {
          final int pages;
        }
        ''',
        'Book.pages has a default',
      );
    });

    test('an unsupported field type', () async {
      await _expectError(
        '''
        $_header
        class Publisher {}
        @Charcoal()
        class Book(this.publisher) with BookCharcoal {
          final Publisher publisher;
        }
        ''',
        'Book.publisher is a Publisher, which charcoal cannot serialize.',
      );
    });

    test('a field outside the constructor', () async {
      await _expectError(
        '''
        $_header
        @Charcoal()
        class Book() with BookCharcoal {
          int pages = 0;
        }
        ''',
        'Book.pages is not a constructor parameter',
      );
    });

    test('every error in one run', () async {
      final result = await _build('''
        import 'package:charcoal/charcoal.dart';
        @Charcoal()
        class Book() {
          int pages = 0;
        }
        ''');

      expect(
        result.errors.join('\n'),
        allOf(
          contains('Missing part'),
          contains('must declare'),
          contains('Book.pages'),
        ),
      );
    });
  });
}
