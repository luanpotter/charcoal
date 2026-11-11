import 'package:charcoal_builder/src/write/code.dart';
import 'package:test/test.dart';

void main() {
  group('code', () {
    test('takes off what comes before the closing quotes', () {
      final book = code('''
        final class Book {
          final String title;
        }
        ''');

      expect(book, 'final class Book {\n  final String title;\n}');
    });

    test('keeps what is indented past them', () {
      final shelf = code('''
          Book('Dune'),
        ''');

      expect(shelf, "  Book('Dune'),");
    });

    test('keeps the later lines of what it interpolates', () {
      const fields = 'final String title;\nfinal int pages;';
      final book = code('''
        final class Book {
          $fields
        }
        ''');

      expect(
        book,
        'final class Book {\n  final String title;\nfinal int pages;\n}',
      );
    });

    test('refuses a template not ending on its own line', () {
      expect(() => code('final class Book {}'), throwsArgumentError);
    });
  });
}
