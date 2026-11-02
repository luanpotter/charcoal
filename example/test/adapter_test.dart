import 'dart:collection';
import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/adapters.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:test/test.dart';

final DateTime _date = DateTime.utc(1965, 8);

BookDetails _details({
  Price? price,
  List<DateTime> reprintDates = const [],
}) {
  return BookDetails(
    partTitles: const [],
    chapterTitles: const [],
    otherAuthors: const [],
    relatedGenres: const {},
    tags: SplayTreeSet(),
    pageCountByChapter: SplayTreeMap(),
    relatedBookIds: const [],
    price: price,
    reprintDates: reprintDates,
  );
}

void main() {
  final full = _details(price: const Price(999), reprintDates: [_date, _date]);
  final text = _date.toIso8601String();

  test('writes the wire type', () {
    final map = full.toMap();

    expect(map['price'], 999);
    expect(map['reprintDates'], [text, text]);
    expect(full.toJsonString(), contains('"price":999'));
    expect(full.toJsonString(), contains('"reprintDates":["$text","$text"]'));
  });

  test('matches jsonEncode(toMap())', () {
    expect(full.toJsonString(), jsonEncode(full.toMap()));
    expect(_details().toJsonString(), jsonEncode(_details().toMap()));
  });

  test('works with nullables and defaults', () {
    final empty = _details();

    expect(empty.toMap().containsKey('price'), isFalse);
    expect(BookDetailsCharcoal.fromMap(empty.toMap()).price, isNull);
    expect(BookDetailsCharcoal.fromMap(empty.toMap()).reprintDates, isEmpty);
    expect(
      BookDetailsCharcoal.fromJsonString(empty.toJsonString()).price,
      isNull,
    );
  });

  test('round trips through JSON and maps', () {
    final decoded = [
      BookDetailsCharcoal.fromJsonString(full.toJsonString()),
      BookDetailsCharcoal.fromMap(full.toMap()),
    ];

    for (final details in decoded) {
      expect(details.price?.cents, 999);
      expect(details.reprintDates, [_date, _date]);
      expect(details.reprintDates, isA<List<DateTime>>());
    }
  });

  test('wraps a failure inside an adapter', () {
    final map = full.toMap();

    for (final broken in [
      {...map, 'price': 'free'},
      {
        ...map,
        'reprintDates': ['not a date'],
      },
    ]) {
      expect(
        () => BookDetailsCharcoal.fromMap(broken),
        throwsA(isA<CharcoalException>()),
      );
      expect(
        () => BookDetailsCharcoal.fromJsonString(jsonEncode(broken)),
        throwsA(isA<CharcoalException>()),
      );
    }
  });
}
