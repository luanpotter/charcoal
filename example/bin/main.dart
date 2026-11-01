import 'dart:io';

import 'package:charcoal_example/book.dart';

void main() {
  const book = Book(title: 'Dune', pages: 412, rating: 4.5, isHardcover: true);
  stdout.writeln(BookCharcoal.fromMap(book.toMap()).toMap());
}
