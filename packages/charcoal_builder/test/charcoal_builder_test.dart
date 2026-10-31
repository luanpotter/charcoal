import 'package:build_test/build_test.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:test/test.dart';

const _import = "import 'package:charcoal/charcoal.dart';";

Future<TestBuilderResult> _build(
  String source, {
  Map<String, Object> outputs = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'package_name');
  await readerWriter.testing.loadIsolateSources();
  return testBuilder(
    CharcoalBuilder(),
    {'package_name|lib/book.dart': source},
    outputs: outputs,
    readerWriter: readerWriter,
  );
}

void main() {
  test('generates a mixin for an annotated class', () async {
    final result = await _build(
      '''
      $_import
      part 'book.g.dart';
      @Charcoal()
      class Book {}
      ''',
      outputs: {
        'package_name|lib/book.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

mixin BookCharcoal {}
''',
      },
    );

    expect(result.succeeded, isTrue);
  });

  test('generates one mixin per annotated class, skipping others', () async {
    final result = await _build(
      '''
      $_import
      part 'book.g.dart';
      @Charcoal()
      class Book {}
      class Publisher {}
      @Charcoal()
      class Author {}
      ''',
      outputs: {
        'package_name|lib/book.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

mixin BookCharcoal {}

mixin AuthorCharcoal {}
''',
      },
    );

    expect(result.succeeded, isTrue);
  });

  test('generates nothing without an annotated class', () async {
    final result = await _build('class Book {}');

    expect(result.succeeded, isTrue);
  });

  test('ignores another annotation named Charcoal', () async {
    final result = await _build('''
      class Charcoal {
        const Charcoal();
      }
      @Charcoal()
      class Book {}
      ''');

    expect(result.succeeded, isTrue);
  });

  test('skips part files', () async {
    final result = await testBuilder(CharcoalBuilder(), {
      'package_name|lib/book.dart': "part 'publisher.dart';",
      'package_name|lib/publisher.dart': "part of 'book.dart';",
    }, outputs: {});

    expect(result.succeeded, isTrue);
  });
}
