const int _catalogSize = 1000;

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

Map<String, Object?> _authorPayload(int seed) {
  return {'name': 'Author number $seed', 'birthYear': 1900 + seed % 100};
}
