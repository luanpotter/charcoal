import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/language.dart';

part 'translation.charcoal.g.dart';

@Charcoal(omit: Omit.empty)
final class const Translation({
  required this.title,
  required this.translator,
  this.revision = _firstRevision,
  this.reviewers = const [],
  this.originalLanguage = Language.english,
  this.notes = '',
}) with TranslationCharcoal {
  static const int _firstRevision = 0;

  final String title;
  final Author translator;
  final int revision;
  final List<Author> reviewers;
  final Language originalLanguage;
  final String notes;
}
