import 'dart:convert';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/listing.dart';
import 'package:test/test.dart';

void main() {
  const listing = Listing(genre: Genre.sciFi, subgenre: Genre.fantasy);

  test('writes names', () {
    expect(listing.toMap(), {'genre': 'sciFi', 'subgenre': 'fantasy'});
    expect(listing.toJsonString(), '{"genre":"sciFi","subgenre":"fantasy"}');
  });

  test('drops a null enum', () {
    const dropped = Listing(genre: Genre.fantasy);

    expect(dropped.toMap(), {'genre': 'fantasy'});
    expect(dropped.toJsonString(), jsonEncode(dropped.toMap()));
  });

  test('round trips', () {
    final decoded = ListingCharcoal.fromJsonString(listing.toJsonString());

    expect(decoded.genre, Genre.sciFi);
    expect(decoded.subgenre, Genre.fantasy);
    expect(ListingCharcoal.fromMap({'genre': 'sciFi'}).subgenre, isNull);
  });

  test('wraps an unknown name', () {
    expect(
      () => ListingCharcoal.fromMap({'genre': 'horror'}),
      throwsA(
        isA<CharcoalException>()
            .having((e) => e.type, 'type', 'Listing')
            .having((e) => e.cause, 'cause', isA<ArgumentError>()),
      ),
    );
  });

  test('wraps a wrong type', () {
    expect(
      () => ListingCharcoal.fromMap({'genre': 1}),
      throwsA(isA<CharcoalException>()),
    );
  });
}
