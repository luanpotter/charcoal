import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/book.dart';
import 'package:test/test.dart';

void main() {
  const map = {
    'title': 'Dune',
    'pageCount': 420,
    'rating': 4.5,
    'isHardcover': true,
    'genre': 'sciFi',
    'author': {'name': 'Frank Herbert'},
    'notes': 'Reread',
  };

  test('round trips every field', () {
    final book = BookCharcoal.fromMap(map);

    expect(book.title, 'Dune');
    expect(book.pageCount, 420);
    expect(book.rating, 4.5);
    expect(book.isHardcover, isTrue);
    expect(book.notes, 'Reread');
    expect(book.toMap(), map);
  });

  test('drops null fields', () {
    final book = BookCharcoal.fromMap({...map}..remove('notes'));

    expect(book.notes, isNull);
    expect(book.toMap().containsKey('notes'), isFalse);
  });

  test('reads an explicit null', () {
    expect(BookCharcoal.fromMap({...map, 'notes': null}).notes, isNull);
  });

  test('reads an int as a double', () {
    expect(BookCharcoal.fromMap({...map, 'rating': 4}).rating, 4.0);
  });

  test('ignores unknown keys', () {
    expect(BookCharcoal.fromMap({...map, 'other': 1}).toMap(), map);
  });

  test('wraps a wrong type', () {
    expect(
      () => BookCharcoal.fromMap({...map, 'pageCount': '420'}),
      throwsA(
        isA<CharcoalException>()
            .having((e) => e.type, 'type', 'Book')
            .having((e) => e.cause, 'cause', isA<TypeError>()),
      ),
    );
  });

  test('wraps a missing key', () {
    expect(
      () => BookCharcoal.fromMap({...map}..remove('title')),
      throwsA(isA<CharcoalException>()),
    );
  });
}
