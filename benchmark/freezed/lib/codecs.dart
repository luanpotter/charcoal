import 'dart:convert';

import 'package:bench/codec.dart';
import 'package:bench/models.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: (value) => jsonEncode(value.toJson()),
  fromJson: (text) => FlatBook.fromJson(_decode(text)),
  toMap: (value) => value.toJson(),
  fromMap: FlatBook.fromJson,
);

final Codec<Book> bookCodec = Codec(
  toJson: (value) => jsonEncode(value.toJson()),
  fromJson: (text) => Book.fromJson(_decode(text)),
  toMap: (value) => value.toJson(),
  fromMap: Book.fromJson,
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: (value) => jsonEncode(value.toJson()),
  fromJson: (text) => Catalog.fromJson(_decode(text)),
  toMap: (value) => value.toJson(),
  fromMap: Catalog.fromJson,
);

Map<String, dynamic> _decode(String text) {
  return jsonDecode(text) as Map<String, dynamic>;
}
