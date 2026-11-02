const int _catalogSize = 1000;

/// How many items a shelf holds, whatever the size of its family, so that times
/// only change with the cost of picking a leaf. It divides by every size.
const int _shelfSize = 88;

const int _passageSize = 1024;

/// Keys are in declaration order and nothing is null, as libraries differ on
/// dropping nulls, so that every library has to produce the same text.
Map<String, Object?> flatPayload() {
  return {
    'title': 'Dune',
    'pageCount': 420,
    'rating': 4.5,
    'isHardcover': true,
    'notes': 'A "classic", reread in São Paulo.\n',
  };
}

Map<String, Object?> bookPayload(int seed) {
  return {
    'title': 'Book number $seed',
    'pageCount': 100 + seed,
    'rating': seed / 8,
    'isHardcover': seed.isEven,
    'genre': seed.isEven ? 'sciFi' : 'fantasy',
    'author': _authorPayload(seed),
    'otherAuthors': [for (var i = 0; i < 3; i++) _authorPayload(seed + i)],
    'tags': ['classic', 'desert', 'tag $seed'],
    'awards': {'Hugo': 1966, 'Nebula': 1965},
    'publishedAt': DateTime.utc(1900 + seed % 100).toIso8601String(),
    'notes': 'Some notes about book "$seed".',
  };
}

Map<String, Object?> catalogPayload() {
  return {
    'books': [for (var i = 0; i < _catalogSize; i++) bookPayload(i)],
  };
}

/// Hits every leaf of a family of [size] evenly.
Map<String, Object?> shelfPayload(int size) {
  return {
    'items': [
      for (var i = 0; i < _shelfSize; i++)
        {'type': 'L${i % size}', 'id': i, 'label': 'Item number $i'},
    ],
  };
}

Map<String, Object?> passagePayload({required bool isEscaped}) {
  final unit = isEscaped ? 'a "São\tPaulo"\n\\' : 'just plain ascii';
  return {'body': (unit * (_passageSize ~/ unit.length))};
}

/// The same, with the first and the last thing it holds telling it apart.
Map<String, Object?> withOtherFirst(Map<String, Object?> payload) {
  return _withOther(payload, isFirst: true);
}

Map<String, Object?> withOtherLast(Map<String, Object?> payload) {
  return _withOther(payload, isFirst: false);
}

Map<String, Object?> _withOther(
  Map<String, Object?> payload, {
  required bool isFirst,
}) {
  final key = isFirst ? payload.keys.first : payload.keys.last;
  final value = payload[key];
  return {
    ...payload,
    key: switch (value) {
      final String text => '$text, but different',
      final List<Object?> list => _withOtherItem(list, isFirst: isFirst),
      _ => throw ArgumentError.value(value, key),
    },
  };
}

List<Object?> _withOtherItem(List<Object?> list, {required bool isFirst}) {
  final index = isFirst ? 0 : list.length - 1;
  final item = list[index]! as Map<String, Object?>;
  return [...list]..[index] = _withOtherText(item, isFirst: isFirst);
}

/// Leaves out a tag, which has to stay the one it was.
Map<String, Object?> _withOtherText(
  Map<String, Object?> item, {
  required bool isFirst,
}) {
  final keys = item.keys.where((key) => key != 'type' && item[key] is String);
  final key = isFirst ? keys.first : keys.last;
  return {...item, key: '${item[key]}, but different'};
}

Map<String, Object?> _authorPayload(int seed) {
  return {'name': 'Author number $seed', 'birthYear': 1900 + seed % 100};
}
