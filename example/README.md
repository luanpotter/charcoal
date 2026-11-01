# Example

Add the dependencies:

```bash
dart pub add charcoal dev:charcoal_builder dev:build_runner
```

Annotate a class and add its generated mixin, in `lib/book.dart`:

```dart
import 'package:charcoal/charcoal.dart';
import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book_details.dart';
import 'package:charcoal_example/dimensions.dart';
import 'package:charcoal_example/genre.dart';
import 'package:charcoal_example/isbn.dart';
import 'package:charcoal_example/language.dart';
import 'package:charcoal_example/publisher.dart';

part 'book.charcoal.g.dart';

@Charcoal()
final class const Book({
  required this.title,
  required this.pageCount,
  required this.rating,
  required this.isHardcover,
  required this.genre,
  required this.author,
  this.isbn,
  this.language,
  this.publisher,
  this.dimensions,
  this.details,
  this.notes,
}) with BookCharcoal {
  final String title;
  final int pageCount;
  final double rating;
  final bool isHardcover;
  final Genre genre;
  final Author author;
  final Isbn? isbn;
  final Language? language;
  final Publisher? publisher;
  final Dimensions? dimensions;
  final BookDetails? details;
  final String? notes;
}
```

Generate the code:

```bash
dart run build_runner build
```

Then use it, in `bin/main.dart`:

```dart
import 'dart:io';

import 'package:charcoal_example/author.dart';
import 'package:charcoal_example/book.dart';
import 'package:charcoal_example/genre.dart';

void main() {
  const book = Book(
    title: 'Dune',
    pageCount: 420,
    rating: 4.5,
    isHardcover: true,
    genre: Genre.sciFi,
    author: Author(penName: null, name: 'Frank Herbert'),
  );
  final json = book.toJsonString();
  stdout.writeln(json);
  stdout.writeln(BookCharcoal.fromJsonString(json).title);
}
```

The full project is in the [example folder](https://github.com/luanpotter/charcoal/tree/main/example).
