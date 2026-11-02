import 'package:charcoal/charcoal.dart';

part 'dimensions.charcoal.g.dart';

@immutable
@Charcoal(omit: Omit.empty)
final class const Dimensions({
  this.widthCm,
  this.heightCm,
  this.weightKg,
}) with DimensionsCharcoal {
  final double? widthCm;
  final double? heightCm;
  final num? weightKg;
}
