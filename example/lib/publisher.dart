import 'package:charcoal/charcoal.dart';

part 'publisher.charcoal.g.dart';

@Charcoal(omit: Omit.none)
final class const Publisher({
  required this.name,
  this.website,
  this.parent,
}) with PublisherCharcoal {
  final String name;
  final String? website;
  final Publisher? parent;
}
