import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/isbn.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/publisher.dart';

part 'book.charcoal.g.dart';

@Charcoal()
final class const Book({
  required this.title,
  required this.pageCount,
  required this.rating,
  required this.isHardcover,
  required this.genre,
  required this.author,
  this.isbn,
  this.language,
  this.publisher,
  this.dimensions,
  this.details,
  this.notes,
}) with BookCharcoal {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final Author author;
  final Isbn? isbn;
  final Language? language;
  final Publisher? publisher;
  final Dimensions? dimensions;
  final BookDetails? details;
  final String? notes;
}
