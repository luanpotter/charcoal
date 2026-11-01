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

final class const DateAdapter() implements CharcoalAdapter<DateTime, String> {
  @override
  String encode(DateTime value) => value.toIso8601String();

  @override
  DateTime decode(String json) => DateTime.parse(json);
}
