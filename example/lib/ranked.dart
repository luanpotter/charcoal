import 'package:charcoal/charcoal.dart';

part 'ranked.charcoal.g.dart';

@immutable
@Charcoal()
final class const Ranked<T>({
  required this.item,
  required this.rank,
  this.runnerUp,
}) with RankedCharcoal<T> {
  final T item;
  final int rank;
  final Ranked<T>? runnerUp;
}
