import 'package:charcoal/charcoal.dart';

part 'models.charcoal.g.dart';

enum Genre() {
  fantasy,
  sciFi,
}

@Charcoal()
final class const FlatBook({
  required this.title,
  required this.pageCount,
  required this.rating,
  required this.isHardcover,
  this.notes,
}) with FlatBookCharcoal {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final String? notes;
}

@Charcoal()
final class const Author({
  required this.name,
  this.birthYear,
}) with AuthorCharcoal {
  final String name;
  final int? birthYear;
}

@Charcoal()
final class const Book({
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
}) with BookCharcoal {
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
}

@Charcoal()
final class const Catalog({
  required this.books,
}) with CatalogCharcoal {
  final List<Book> books;
}
