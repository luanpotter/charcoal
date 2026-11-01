import 'package:charcoal/charcoal.dart';

part 'author.charcoal.g.dart';

@Charcoal()
final class const Author({
  required this.penName,
  required this.name,
  this.birthYear,
  this.isAlive,
}) with AuthorCharcoal {
  final String? penName;
  final String name;
  final int? birthYear;
  final bool? isAlive;
}
