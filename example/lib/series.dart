import 'package:charcoal/charcoal.dart';

part 'series.charcoal.g.dart';

@Charcoal()
final class const Series({
  this.name,
  this.position,
  this.score,
}) with SeriesCharcoal {
  final String? name;
  final int? position;
  final double? score;
}
