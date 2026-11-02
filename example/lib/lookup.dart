import 'package:charcoal/charcoal.dart';

part 'lookup.charcoal.g.dart';

@Charcoal()
sealed class const Lookup<T>();

final class const Known<T>(this.value) extends Lookup<T> with KnownCharcoal<T> {
  final T value;
}

final class const Unknown() extends Lookup<Never> with UnknownCharcoal;

final class const Estimated({
  required this.low,
  required this.high,
}) extends Lookup<int> with EstimatedCharcoal {
  final int low;
  final int high;
}
