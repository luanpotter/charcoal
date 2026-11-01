# Example

Add the dependencies:

```bash
dart pub add charcoal dev:charcoal_builder dev:build_runner
```

Annotate a class and add its generated mixin, in `lib/book.dart`:

```dart
import 'package:charcoal/charcoal.dart';

part 'book.charcoal.g.dart';

@Charcoal()
final class const Book({
  required this.title,
  required this.pages,
  required this.rating,
  required this.isHardcover,
  this.note,
}) with BookCharcoal {
  final String title;
  final int pages;
  final double rating;
  final bool isHardcover;
  final String? note;
}
```

Generate the code:

```bash
dart run build_runner build
```

Then use it, in `bin/main.dart`:

```dart
import 'dart:io';

import 'package:charcoal_example/book.dart';

void main() {
  const book = Book(title: 'Dune', pages: 420, rating: 4.5, isHardcover: true);
  final json = book.toJsonString();
  stdout.writeln(json);
  stdout.writeln(BookCharcoal.fromJsonString(json).title);
}
```

The full project is in the [example folder](https://github.com/luanpotter/charcoal/tree/main/example).
