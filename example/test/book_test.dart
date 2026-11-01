import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/book.dart';
import 'package:test/test.dart';

void main() {
  const map = {
    'title': 'Dune',
    'pages': 412,
    'rating': 4.5,
    'isHardcover': true,
    'note': 'Reread',
  };

  test('round trips every field', () {
    final book = BookCharcoal.fromMap(map);

    expect(book.title, 'Dune');
    expect(book.pages, 412);
    expect(book.rating, 4.5);
    expect(book.isHardcover, isTrue);
    expect(book.note, 'Reread');
    expect(book.toMap(), map);
  });

  test('drops null fields', () {
    final book = BookCharcoal.fromMap({...map}..remove('note'));

    expect(book.note, isNull);
    expect(book.toMap().containsKey('note'), isFalse);
  });

  test('reads an explicit null', () {
    expect(BookCharcoal.fromMap({...map, 'note': null}).note, isNull);
  });

  test('reads an int as a double', () {
    expect(BookCharcoal.fromMap({...map, 'rating': 4}).rating, 4.0);
  });

  test('ignores unknown keys', () {
    expect(BookCharcoal.fromMap({...map, 'other': 1}).toMap(), map);
  });

  test('wraps a wrong type', () {
    expect(
      () => BookCharcoal.fromMap({...map, 'pages': '412'}),
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
