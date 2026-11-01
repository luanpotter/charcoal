import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/language.dart';

part 'translation.charcoal.g.dart';

@Charcoal()
final class const Translation({
  required this.title,
  required this.translator,
  this.edition = 1,
  this.originalLanguage = Language.english,
}) with TranslationCharcoal {
  final String title;
  final Author translator;
  final int edition;
  final Language? originalLanguage;
}
