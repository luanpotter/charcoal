import 'package:charcoal/charcoal.dart';

part 'listing.charcoal.g.dart';

enum Genre() {
  fantasy,
  sciFi,
}

@Charcoal()
final class const Listing({
  required this.genre,
  this.subgenre,
}) with ListingCharcoal {
  final Genre genre;
  final Genre? subgenre;
}
