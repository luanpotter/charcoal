import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';

part 'translation.charcoal.g.dart';

@Charcoal()
final class const Translation({
  required this.title,
  required this.translator,
}) with TranslationCharcoal {
  final String title;
  final Author translator;
}
