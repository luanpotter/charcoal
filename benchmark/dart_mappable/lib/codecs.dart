import 'package:bench/codec.dart';
import 'package:bench/models.dart';

final Codec<FlatBook> flatCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: FlatBookMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: FlatBookMapper.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Book> bookCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: BookMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: BookMapper.fromMap,
  hasEquality: true,
  copies: Copies(
    same: (value) => value.copyWith(),
    replacing: (value) => value.copyWith(title: 'Other'),
    clearing: (value) => value.copyWith(notes: null),
  ),
);

final Codec<Catalog> catalogCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: CatalogMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: CatalogMapper.fromMap,
  hasEquality: true,
);

final Codec<Passage> passageCodec = Codec(
  toJson: (value) => value.toJson(),
  fromJson: PassageMapper.fromJson,
  toMap: (value) => value.toMap(),
  fromMap: PassageMapper.fromMap,
  hasEquality: true,
);

final List<Extra> extras = [];
