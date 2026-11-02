<p align="center">
  <img alt="charcoal logo" width="96" src="https://raw.githubusercontent.com/luanpotter/charcoal/main/media/charcoal-6x.png">
</p>

<h1 align="center">charcoal</h1>

<p align="center">
  <a title="CI" href="https://github.com/luanpotter/charcoal/actions/workflows/ci.yml"><img alt="CI status" src="https://img.shields.io/github/actions/workflow/status/luanpotter/charcoal/ci.yml?branch=main&logo=github&style=flat-square"></a>
  <a title="Pub" href="https://pub.dev/packages/charcoal"><img alt="Pub version" src="https://img.shields.io/pub/v/charcoal?style=flat-square"></a>
  <a title="Melos" href="https://github.com/invertase/melos"><img alt="Maintained with Melos" src="https://img.shields.io/badge/maintained%20with-melos-f700ff?style=flat-square"></a>
</p>

A highly opinionated Dart `build_runner` with a unified annotation. Generates JSON, copy, equality, hash and `toString` as direct code for any annotated data class, with the whole type graph resolved at build time: no registry, no runtime lookup, nor dynamic dispatch. Configurations (and errors) are checked at build time.

The main goal of this project is to be a blazingly fast, static alternative to [dart_mappable](https://github.com/schultek/dart_mappable), which is itself a sane alternative to Google's [json_serializable](https://github.com/google/json_serializable.dart).


## Install

```bash
dart pub add charcoal dev:charcoal_builder dev:build_runner
```


## Usage

```dart
import 'package:charcoal/charcoal.dart';

part 'book.charcoal.g.dart';

@immutable
@Charcoal()
final class Book({
  required this.id,
  required this.title,
  required this.genres,
  this.notes,
  this.releasedAt,
}) with BookCharcoal {
  final Id<Book> id;
  final String title;
  final List<Genre> genres;
  final String? notes;
  final DateTime? releasedAt;
}
```

```dart
final book = BookCharcoal.fromJsonString(body);
final revised = book.copyWith(notes: null);
final json = revised.toJsonString();
```

Generate the code with `dart run build_runner build`, which you can add to your build script.


## Benchmarks

The goal of Charcoal is to bring the ergonomics of `dart_mappable` but without the dynamic dispatching. The comparison with the other alternatives is not just speed then, but feature set. That being said, you can see how it compares to all three (`json_serializable`, `dart_mappable`, and `freezed`) using our [benchmarks](https://github.com/luanpotter/charcoal/blob/main/benchmark/README.md).


## Contributing

See our [CONTRIBUTING](https://github.com/luanpotter/charcoal/blob/main/CONTRIBUTING.md) guide.
