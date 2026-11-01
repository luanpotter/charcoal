import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/language.dart';

part 'translation.charcoal.g.dart';

@Charcoal()
final class const Translation({
  required this.title,
  required this.translator,
  this.edition = _firstEdition,
  this.originalLanguage = Language.english,
}) with TranslationCharcoal {
  static const int _firstEdition = 1;

  final String title;
  final Author translator;
  final int edition;
  final Language? originalLanguage;
}
