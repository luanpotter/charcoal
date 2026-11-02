import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/language.dart';

part 'translation.charcoal.g.dart';

@immutable
@Charcoal(omit: Omit.empty)
final class const Translation({
  required this.title,
  required this.translator,
  this.revision = _firstRevision,
  List<Author>? reviewers,
  this.originalLanguage = Language.english,
  this.notes = '',
  this.dimensions = const Dimensions(),
}) with TranslationCharcoal {
  static const int _firstRevision = 0;

  final String title;
  final Author translator;
  final int revision;
  final List<Author> reviewers = reviewers ?? const [];
  final Language originalLanguage;
  final String notes;
  final Dimensions dimensions;
}
