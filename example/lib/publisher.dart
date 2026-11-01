import 'package:charcoal/charcoal.dart';

part 'publisher.charcoal.g.dart';

@Charcoal(omit: Omit.none)
final class const Publisher({
  required this.website,
  required this.name,
  required this.revenue,
  this.founded,
}) with PublisherCharcoal {
  final String? website;
  final String name;
  final num revenue;
  final int? founded;
}
