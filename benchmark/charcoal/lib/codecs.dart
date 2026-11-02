import 'dart:convert';

import 'package:bench/codec.dart';
import 'package:bench/models.dart';
import 'package:bench/payloads.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: FlatBookCharcoal.encodeJsonString,
  fromJson: FlatBookCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: FlatBookCharcoal.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Book> bookCodec = Codec(
  toJson: BookCharcoal.encodeJsonString,
  fromJson: BookCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: BookCharcoal.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: CatalogCharcoal.encodeJsonString,
  fromJson: CatalogCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: CatalogCharcoal.fromMap,
  hasEquality: true,
);

final Codec<Passage> passageCodec = Codec(
  toJson: PassageCharcoal.encodeJsonString,
  fromJson: PassageCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: PassageCharcoal.fromMap,
  hasEquality: true,
);

final Book _book = BookCharcoal.fromMap(bookPayload(1));
final String _bookText = jsonEncode(bookPayload(1));
final Catalog _catalog = CatalogCharcoal.fromMap(catalogPayload());
final String _catalogText = jsonEncode(catalogPayload());

final MutableBook _mutableBook = MutableBookCharcoal.fromMap(bookPayload(1));
final MutableBook _otherMutableBook = MutableBookCharcoal.fromMap(
  bookPayload(1),
);
final MutableCatalog _mutableCatalog = MutableCatalogCharcoal.fromMap(
  catalogPayload(),
);
final MutableCatalog _otherMutableCatalog = MutableCatalogCharcoal.fromMap(
  catalogPayload(),
);

final List<Extra> extras = [
  Extra('book.jsonEncodeToMap', () => jsonEncode(_book.toMap())),
  Extra(
    'book.fromMapJsonDecode',
    () => BookCharcoal.fromMap(jsonDecode(_bookText) as Map<String, Object?>),
  ),
  Extra('catalog.jsonEncodeToMap', () => jsonEncode(_catalog.toMap())),
  Extra(
    'catalog.fromMapJsonDecode',
    () => CatalogCharcoal.fromMap(
      jsonDecode(_catalogText) as Map<String, Object?>,
    ),
  ),
  Extra('book.copy', () => _mutableBook.copy()),
  Extra(
    'book.contentEquals',
    () => _mutableBook.contentEquals(_otherMutableBook),
    expected: true,
  ),
  Extra('book.contentHash', () => _mutableBook.contentHash),
  Extra('catalog.copy', () => _mutableCatalog.copy()),
  Extra(
    'catalog.contentEquals',
    () => _mutableCatalog.contentEquals(_otherMutableCatalog),
    expected: true,
  ),
  Extra('catalog.contentHash', () => _mutableCatalog.contentHash),
];
