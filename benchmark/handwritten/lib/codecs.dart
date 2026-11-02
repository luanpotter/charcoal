import 'dart:convert';

import 'package:bench/codec.dart';
import 'package:bench/models.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: (value) => jsonEncode(value.toMap()),
  fromJson: (text) => FlatBook.fromMap(_decode(text)),
  toMap: (value) => value.toMap(),
  fromMap: FlatBook.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Book> bookCodec = Codec(
  toJson: (value) => jsonEncode(value.toMap()),
  fromJson: (text) => Book.fromMap(_decode(text)),
  toMap: (value) => value.toMap(),
  fromMap: Book.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: (value) => jsonEncode(value.toMap()),
  fromJson: (text) => Catalog.fromMap(_decode(text)),
  toMap: (value) => value.toMap(),
  fromMap: Catalog.fromMap,
  hasEquality: true,
);

final Codec<Passage> passageCodec = Codec(
  toJson: (value) => jsonEncode(value.toMap()),
  fromJson: (text) => Passage.fromMap(_decode(text)),
  toMap: (value) => value.toMap(),
  fromMap: Passage.fromMap,
  hasEquality: true,
);

final List<Extra> extras = [];

Map<String, Object?> _decode(String text) {
  return jsonDecode(text) as Map<String, Object?>;
}
