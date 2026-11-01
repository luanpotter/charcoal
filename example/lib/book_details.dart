import 'dart:collection';

import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/genre.dart';
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
  this.quotes,
  this.awards,
  this.translations,
}) with BookDetailsCharcoal {
  final List<String?> partTitles;
  final List<List<String>> chapterTitles;
  final List<Author> otherAuthors;
  final Set<Genre> relatedGenres;
  final SplayTreeSet<String> tags;
  final SplayTreeMap<String, int> pageCountByChapter;
  final Iterable<String>? quotes;
  final Map<String, int>? awards;
  final Map<Language, Translation>? translations;
}
