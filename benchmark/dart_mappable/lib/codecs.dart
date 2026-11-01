import 'package:bench/codec.dart';
import 'package:bench/models.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: FlatBookMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: FlatBookMapper.fromMap,
);

final Codec<Book> bookCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: BookMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: BookMapper.fromMap,
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: CatalogMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: CatalogMapper.fromMap,
);
