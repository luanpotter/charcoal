import 'package:charcoal/charcoal.dart';

part 'book.charcoal.g.dart';

@Charcoal()
final class const Book({
  required this.title,
  required this.pages,
  required this.rating,
  required this.isHardcover,
  this.note,
}) with BookCharcoal {
  final String title;
  final int pages;
  final double rating;
  final bool isHardcover;
  final String? note;
}
