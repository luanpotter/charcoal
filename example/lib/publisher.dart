import 'package:charcoal/charcoal.dart';

part 'publisher.charcoal.g.dart';

@immutable
@Charcoal(omit: Omit.none)
final class const Publisher({
  required this.name,
  this.website,
  this.parent,
}) with PublisherCharcoal {
  final String name;
  final Uri? website;
  final Publisher? parent;
}
