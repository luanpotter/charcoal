/// What a careful person would write with no package at all, as the floor that
/// generated code gets compared to.
///
/// JSON goes through maps and `dart:convert`, as writing a direct encoder and
/// parser by hand is what nobody would do for each of their classes.
enum Genre { fantasy, sciFi }

const Object _keep = _Keep();

final class _Keep {
  const _Keep();
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

final class FlatBook {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final String? notes;

  const FlatBook({
    required this.title,
    required this.pageCount,
    required this.rating,
    required this.isHardcover,
    this.notes,
  });

  factory FlatBook.fromMap(Map<String, Object?> map) {
    return FlatBook(
      title: map['title'] as String,
      pageCount: map['pageCount'] as int,
      rating: (map['rating'] as num).toDouble(),
      isHardcover: map['isHardcover'] as bool,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'pageCount': pageCount,
      'rating': rating,
      'isHardcover': isHardcover,
      'notes': ?notes,
    };
  }

  FlatBook copyWith({
    String? title,
    int? pageCount,
    double? rating,
    bool? isHardcover,
    Object? notes = _keep,
  }) {
    return FlatBook(
      title: title ?? this.title,
      pageCount: pageCount ?? this.pageCount,
      rating: rating ?? this.rating,
      isHardcover: isHardcover ?? this.isHardcover,
      notes: identical(notes, _keep) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlatBook &&
        other.title == title &&
        other.pageCount == pageCount &&
        other.rating == rating &&
        other.isHardcover == isHardcover &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(title, pageCount, rating, isHardcover, notes);
}

final class Author {
  final String name;
  final int? birthYear;

  const Author({required this.name, this.birthYear});

  factory Author.fromMap(Map<String, Object?> map) {
    return Author(
      name: map['name'] as String,
      birthYear: map['birthYear'] as int?,
    );
  }

  Map<String, Object?> toMap() => {'name': name, 'birthYear': ?birthYear};

  @override
  bool operator ==(Object other) {
    return other is Author &&
        other.name == name &&
        other.birthYear == birthYear;
  }

  @override
  int get hashCode => Object.hash(name, birthYear);
}

final class Book {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final Author author;
  final List<Author> otherAuthors;
  final List<String> tags;
  final Map<String, int> awards;
  final DateTime publishedAt;
  final String? notes;

  const Book({
    required this.title,
    required this.pageCount,
    required this.rating,
    required this.isHardcover,
    required this.genre,
    required this.author,
    required this.otherAuthors,
    required this.tags,
    required this.awards,
    required this.publishedAt,
    this.notes,
  });

  factory Book.fromMap(Map<String, Object?> map) {
    return Book(
      title: map['title'] as String,
      pageCount: map['pageCount'] as int,
      rating: (map['rating'] as num).toDouble(),
      isHardcover: map['isHardcover'] as bool,
      genre: Genre.values.byName(map['genre'] as String),
      author: Author.fromMap(map['author'] as Map<String, Object?>),
      otherAuthors: [
        for (final author in map['otherAuthors'] as List<Object?>)
          Author.fromMap(author as Map<String, Object?>),
      ],
      tags: [for (final tag in map['tags'] as List<Object?>) tag as String],
      awards: {
        for (final entry in (map['awards'] as Map<String, Object?>).entries)
          entry.key: entry.value as int,
      },
      publishedAt: DateTime.parse(map['publishedAt'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'pageCount': pageCount,
      'rating': rating,
      'isHardcover': isHardcover,
      'genre': genre.name,
      'author': author.toMap(),
      'otherAuthors': [for (final author in otherAuthors) author.toMap()],
      'tags': tags,
      'awards': awards,
      'publishedAt': publishedAt.toIso8601String(),
      'notes': ?notes,
    };
  }

  Book copyWith({
    String? title,
    int? pageCount,
    double? rating,
    bool? isHardcover,
    Genre? genre,
    Author? author,
    List<Author>? otherAuthors,
    List<String>? tags,
    Map<String, int>? awards,
    DateTime? publishedAt,
    Object? notes = _keep,
  }) {
    return Book(
      title: title ?? this.title,
      pageCount: pageCount ?? this.pageCount,
      rating: rating ?? this.rating,
      isHardcover: isHardcover ?? this.isHardcover,
      genre: genre ?? this.genre,
      author: author ?? this.author,
      otherAuthors: otherAuthors ?? this.otherAuthors,
      tags: tags ?? this.tags,
      awards: awards ?? this.awards,
      publishedAt: publishedAt ?? this.publishedAt,
      notes: identical(notes, _keep) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Book &&
        other.title == title &&
        other.pageCount == pageCount &&
        other.rating == rating &&
        other.isHardcover == isHardcover &&
        other.genre == genre &&
        other.author == author &&
        _listEquals(other.otherAuthors, otherAuthors) &&
        _listEquals(other.tags, tags) &&
        _mapEquals(other.awards, awards) &&
        other.publishedAt == publishedAt &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      pageCount,
      rating,
      isHardcover,
      genre,
      author,
      Object.hashAll(otherAuthors),
      Object.hashAll(tags),
      _mapHash(awards),
      publishedAt,
      notes,
    );
  }
}

final class Catalog {
  final List<Book> books;

  const Catalog({required this.books});

  factory Catalog.fromMap(Map<String, Object?> map) {
    return Catalog(
      books: [
        for (final book in map['books'] as List<Object?>)
          Book.fromMap(book as Map<String, Object?>),
      ],
    );
  }

  Map<String, Object?> toMap() {
    return {
      'books': [for (final book in books) book.toMap()],
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Catalog && _listEquals(other.books, books);
  }

  @override
  int get hashCode => Object.hashAll(books);
}

final class Passage {
  final String body;

  const Passage({required this.body});

  factory Passage.fromMap(Map<String, Object?> map) {
    return Passage(body: map['body'] as String);
  }

  Map<String, Object?> toMap() => {'body': body};

  @override
  bool operator ==(Object other) => other is Passage && other.body == body;

  @override
  int get hashCode => body.hashCode;
}
