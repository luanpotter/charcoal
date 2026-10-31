import 'package:charcoal_example/book.dart';
import 'package:test/test.dart';

void main() {
  test('Book has its generated mixin', () {
    expect(const Book(title: 'Dune'), isA<BookCharcoal>());
  });
}
