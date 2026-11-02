import 'dart:collection';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/adapters.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/edition.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/id.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/translation.dart';

part 'book_details.charcoal.g.dart';

@Charcoal()
final class BookDetails({
  required this.partTitles,
  required this.chapterTitles,
  required this.otherAuthors,
  required this.relatedGenres,
  required this.tags,
  required this.pageCountByChapter,
  required this.relatedBookIds,
  this.subtitle = '',
  this.quotes = const [],
  this.awardsByYear = const {},
  this.translations,
  this.price,
  this.reprintDates = const [],
  this.editions = const [],
}) with BookDetailsCharcoal {
  final List<String?> partTitles;
  final List<List<String>> chapterTitles;
  final List<Author> otherAuthors;
  final Set<Genre> relatedGenres;
  final SplayTreeSet<String> tags;
  final SplayTreeMap<String, int> pageCountByChapter;
  final List<Id<Book>> relatedBookIds;
  final String subtitle;
  final Iterable<String> quotes;
  final Map<int, String> awardsByYear;
  final Map<Language, Translation>? translations;
  final Price? price;
  final List<DateTime> reprintDates;
  final List<Edition> editions;
}
