import 'package:charcoal/charcoal.dart';

part 'author.charcoal.g.dart';

@Charcoal()
final class const Author({
  required this.penName,
  required this.name,
  this.born,
  this.isAlive,
}) with AuthorCharcoal {
  final String? penName;
  final String name;
  final int? born;
  final bool? isAlive;
}
