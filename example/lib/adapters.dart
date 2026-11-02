import 'package:charcoal/charcoal.dart';

final class const Price(this.cents) {
  final int cents;
}

final class const PriceAdapter() implements CharcoalAdapter<Price, int> {
  @override
  int encode(Price value) => value.cents;

  @override
  Price decode(int json) => Price(json);
}
