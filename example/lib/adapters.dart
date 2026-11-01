import 'package:charcoal/charcoal.dart';

final class const Price(this.cents) {
  final int cents;
}

final class const PageRange(this.first, this.last) {
  final int first;
  final int last;
}

final class const PriceAdapter() implements CharcoalAdapter<Price, int> {
  @override
  int encode(Price value) => value.cents;

  @override
  Price decode(int json) => Price(json);
}

final class const PageRangeAdapter()
    implements CharcoalAdapter<PageRange, List<int>> {
  @override
  List<int> encode(PageRange value) => [value.first, value.last];

  @override
  PageRange decode(List<int> json) => PageRange(json[0], json[1]);
}
