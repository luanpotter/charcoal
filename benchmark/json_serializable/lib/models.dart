import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

enum Genre { fantasy, sciFi }

@JsonSerializable(explicitToJson: true)
final class FlatBook {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final String? notes;

  const FlatBook({
    required this.title,
    required this.pageCount,
    required this.rating,
    required this.isHardcover,
    this.notes,
  });

  factory FlatBook.fromJson(Map<String, dynamic> json) =>
      _$FlatBookFromJson(json);

  Map<String, dynamic> toJson() => _$FlatBookToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class Author {
  final String name;
  final int? birthYear;

  const Author({required this.name, this.birthYear});

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class Book {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final Author author;
  final List<Author> otherAuthors;
  final List<String> tags;
  final Map<String, int> awards;
  final DateTime publishedAt;
  final String? notes;

  const Book({
    required this.title,
    required this.pageCount,
    required this.rating,
    required this.isHardcover,
    required this.genre,
    required this.author,
    required this.otherAuthors,
    required this.tags,
    required this.awards,
    required this.publishedAt,
    this.notes,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);
}

@JsonSerializable(explicitToJson: true)
final class Catalog {
  final List<Book> books;

  const Catalog({required this.books});

  factory Catalog.fromJson(Map<String, dynamic> json) =>
      _$CatalogFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogToJson(this);
}
