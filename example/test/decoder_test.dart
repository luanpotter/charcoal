import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/edition.dart';
import 'package:test/test.dart';

const _author = Author(penName: 'Saint-Ex', name: 'Antoine');
const List<Edition> _editions = [
  Hardcover(year: 1943, weightGrams: 300),
  Ebook(year: 2005, formats: ['epub']),
];

void main() {
  test('a class decoder does what its statics do', () {
    const decoder = AuthorCharcoal.decoder;
    final json = _author.toJsonString();

    expect(decoder.fromJsonString(json), AuthorCharcoal.fromJsonString(json));
    expect(decoder.fromMap(_author.toMap()), _author);
  });

  test('a root decoder brings back every leaf', () {
    const decoder = EditionCharcoal.decoder;
    for (final edition in _editions) {
      final decoded = [
        decoder.fromJsonString(edition.toJsonString()),
        decoder.fromMap(edition.toMap()),
      ];

      for (final value in decoded) {
        expect(value.runtimeType, edition.runtimeType);
        expect(value.contentEquals(edition), isTrue);
      }
    }
  });

  test('a leaf decoder is one of its root', () {
    const CharcoalDecoder<Edition> decoder = HardcoverCharcoal.decoder;

    expect(decoder.fromMap(_editions.first.toMap()), _editions.first);
  });
}
