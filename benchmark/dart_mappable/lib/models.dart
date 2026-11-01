import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

@MappableEnum()
enum Genre { fantasy, sciFi }

@MappableClass()
final class FlatBook with FlatBookMappable {
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
}

@MappableClass()
final class Author with AuthorMappable {
  final String name;
  final int? birthYear;

  const Author({required this.name, this.birthYear});
}

@MappableClass()
final class Book with BookMappable {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final Author author;
  final List<Author> otherAuthors;
  final List<String> tags;
  final Map<String, int> awards;
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
    this.notes,
  });
}

@MappableClass()
final class Catalog with CatalogMappable {
  final List<Book> books;

  const Catalog({required this.books});
}
