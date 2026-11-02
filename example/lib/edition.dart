import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';

part 'edition.charcoal.g.dart';

@Charcoal()
sealed class const Edition({required this.year}) {
  final int year;
}

/// A marker over the family, not a branch of it.
sealed class const Readable() implements Edition;

sealed class const Digital({
  required super.year,
  required this.formats,
}) extends Edition {
  final List<String> formats;
}

@immutable
@Charcoal(tag: 'hardcover')
final class const Hardcover({
  required super.year,
  this.weightGrams,
}) extends Edition with HardcoverCharcoal implements Readable {
  final int? weightGrams;
}

final class const Ebook({
  required super.year,
  required super.formats,
}) extends Digital with EbookCharcoal implements Readable;

final class const Audiobook({
  required super.year,
  required super.formats,
  required this.narrator,
}) extends Digital with AudiobookCharcoal {
  final Author narrator;
}
