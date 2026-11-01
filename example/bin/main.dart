import 'dart:io';

import 'package:charcoal_example/book.dart';

void main() {
  const book = Book(title: 'Dune', pages: 420, rating: 4.5, isHardcover: true);
  final json = book.toJsonString();
  stdout.writeln(json);
  stdout.writeln(BookCharcoal.fromJsonString(json).title);
}
