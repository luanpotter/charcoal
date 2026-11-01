import 'package:charcoal/charcoal.dart';

part 'dimensions.charcoal.g.dart';

@Charcoal()
final class const Dimensions({
  this.widthCm,
  this.heightCm,
  this.weightKg,
}) with DimensionsCharcoal {
  final double? widthCm;
  final double? heightCm;
  final num? weightKg;
}
