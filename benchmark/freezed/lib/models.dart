import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum Genre { fantasy, sciFi }

@freezed
abstract class FlatBook with _$FlatBook {
  const factory FlatBook({
    required String title,
    required int pageCount,
    required double rating,
    required bool isHardcover,
    String? notes,
  }) = _FlatBook;

  factory FlatBook.fromJson(Map<String, dynamic> json) =>
      _$FlatBookFromJson(json);
}

@freezed
abstract class Author with _$Author {
  const factory Author({required String name, int? birthYear}) = _Author;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
}

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String title,
    required int pageCount,
    required double rating,
    required bool isHardcover,
    required Genre genre,
    required Author author,
    required List<Author> otherAuthors,
    required List<String> tags,
    required Map<String, int> awards,
    required DateTime publishedAt,
    String? notes,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

@freezed
abstract class Catalog with _$Catalog {
  const factory Catalog({required List<Book> books}) = _Catalog;

  factory Catalog.fromJson(Map<String, dynamic> json) =>
      _$CatalogFromJson(json);
}
