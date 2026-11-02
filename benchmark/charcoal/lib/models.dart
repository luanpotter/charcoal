import 'package:charcoal/charcoal.dart';

part 'models.charcoal.g.dart';

enum Genre() {
  fantasy,
  sciFi,
}

@immutable
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

@immutable
@Charcoal()
final class const Author({
  required this.name,
  this.birthYear,
}) with AuthorCharcoal {
  final String name;
  final int? birthYear;
}

@immutable
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

@immutable
@Charcoal()
final class const Catalog({
  required this.books,
}) with CatalogCharcoal {
  final List<Book> books;
}

@immutable
@Charcoal()
final class const Passage({
  required this.body,
}) with PassageCharcoal {
  final String body;
}

/// The same as an [Author], for what only a mutable class has.
@Charcoal()
final class const MutableAuthor({
  required this.name,
  this.birthYear,
}) with MutableAuthorCharcoal {
  final String name;
  final int? birthYear;
}

/// The same as a [Book], for what only a mutable class has.
@Charcoal()
final class const MutableBook({
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
}) with MutableBookCharcoal {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final MutableAuthor author;
  final List<MutableAuthor> otherAuthors;
  final List<String> tags;
  final Map<String, int> awards;
  final DateTime publishedAt;
  final String? notes;
}

/// The same as a [Catalog], for what only a mutable class has.
@Charcoal()
final class const MutableCatalog({
  required this.books,
}) with MutableCatalogCharcoal {
  final List<MutableBook> books;
}
