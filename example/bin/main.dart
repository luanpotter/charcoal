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
