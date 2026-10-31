import 'package:charcoal/charcoal.dart';

part 'book.g.dart';

@Charcoal()
final class const Book({required this.title}) with BookCharcoal {
  final String title;
}
