import 'package:bench/codec.dart';
import 'package:bench/models.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: FlatBookCharcoal.encodeJsonString,
  fromJson: FlatBookCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: FlatBookCharcoal.fromMap,
);

final Codec<Book> bookCodec = Codec(
  toJson: BookCharcoal.encodeJsonString,
  fromJson: BookCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: BookCharcoal.fromMap,
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: CatalogCharcoal.encodeJsonString,
  fromJson: CatalogCharcoal.fromJsonString,
  toMap: (value) => value.toMap(),
  fromMap: CatalogCharcoal.fromMap,
);
