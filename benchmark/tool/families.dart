import 'dart:io';

import '../../packages/charcoal_builder/lib/src/write/code.dart';

/// Writes the sealed families of a library to `lib/families.dart`, as each is
/// the same class many times over: 54 leaves, in 5 different ways to declare.
void main(List<String> arguments) {
  final library = arguments.single;
  final source = switch (library) {
    'charcoal' => _charcoal(),
    'handwritten' => _handwritten(),
    'json_serializable' => _jsonSerializable(),
    'dart_mappable' => _dartMappable(),
    'freezed' => _freezed(),
    _ => throw ArgumentError.value(library, 'library'),
  };
  stdout.writeln(source.trimRight());
}

extension on StringBuffer {
  void writeCode(String template) => writeln(code(template));
}

const List<int> _sizes = [2, 8, 44];

Iterable<int> _leaves(int size) => Iterable.generate(size);

String _codec(
  int size, {
  required String toJson,
  required String fromJson,
  required String toMap,
  required String fromMap,
  required bool hasEquality,
}) {
  return code('''
    final Codec<Shelf$size> shelf${size}Codec = Codec(
      toJson: $toJson,
      fromJson: $fromJson,
      toMap: $toMap,
      fromMap: $fromMap,
      hasEquality: $hasEquality,
    );

    ''');
}

String _charcoal() {
  final out = StringBuffer()
    ..writeCode('''
      import 'package:bench/codec.dart';
      import 'package:bench/payloads.dart';
      import 'package:charcoal/charcoal.dart';

      part 'families.charcoal.g.dart';

      ''');
  for (final size in _sizes) {
    out
      ..write(_charcoalFamily('', size, annotation: '@immutable\n'))
      ..write(_charcoalFamily('Mutable', size, annotation: ''))
      ..writeln(
        _codec(
          size,
          toJson: 'Shelf${size}Charcoal.encodeJsonString',
          fromJson: 'Shelf${size}Charcoal.fromJsonString',
          toMap: '(value) => value.toMap()',
          fromMap: 'Shelf${size}Charcoal.fromMap',
          hasEquality: true,
        ),
      )
      ..writeCode('''
        final MutableShelf$size _mutable$size =
            MutableShelf${size}Charcoal.fromMap(shelfPayload($size));
        final MutableShelf$size _otherMutable$size =
            MutableShelf${size}Charcoal.fromMap(shelfPayload($size));

        ''');
  }
  out.writeln('final List<Extra> familyExtras = [');
  for (final size in _sizes) {
    out.writeCode('''
        Extra('sealed$size.copy', () => _mutable$size.copy()),
        Extra(
          'sealed$size.contentEquals',
          () => _mutable$size.contentEquals(_otherMutable$size),
          expected: true,
        ),
        Extra('sealed$size.contentHash', () => _mutable$size.contentHash),
      ''');
  }
  out.writeln('];');
  return out.toString();
}

String _charcoalFamily(String prefix, int size, {required String annotation}) {
  final item = '${prefix}Item$size';
  final shelf = '${prefix}Shelf$size';
  final out = StringBuffer()
    ..writeCode('''
      $annotation@Charcoal()
      sealed class const $item() with ${item}Charcoal;

      ''');
  for (final leaf in _leaves(size)) {
    final name = '${item}L$leaf';
    out.writeCode('''
      @Charcoal(tag: 'L$leaf')
      final class const $name({
        required this.id,
        required this.label,
      }) extends $item with ${name}Charcoal {
        final int id;
        final String label;
      }

      ''');
  }
  out.writeCode('''
    $annotation@Charcoal()
    final class const $shelf({required this.items}) with ${shelf}Charcoal {
      final List<$item> items;
    }

    ''');
  return out.toString();
}

/// What a person would write: maps for JSON, and the same two fields per leaf.
String _handwritten() {
  final out = StringBuffer()
    ..writeCode('''
      import 'dart:convert';

      import 'package:bench/codec.dart';

      final List<Extra> familyExtras = [];

      ''');
  for (final size in _sizes) {
    final item = 'Item$size';
    final shelf = 'Shelf$size';
    out.writeCode('''
      sealed class $item {
        const $item();

        factory $item.fromMap(Map<String, Object?> map) {
          final type = map['type'] as String;
          return switch (type) {
      ''');
    for (final leaf in _leaves(size)) {
      out.writeln("      'L$leaf' => ${item}L$leaf.fromMap(map),");
    }
    out.writeCode('''
            _ => throw ArgumentError.value(type, 'type'),
          };
        }

        Map<String, Object?> toMap();
      }

      ''');
    for (final leaf in _leaves(size)) {
      final name = '${item}L$leaf';
      out.writeCode('''
        final class $name extends $item {
          final int id;
          final String label;

          const $name({required this.id, required this.label});

          factory $name.fromMap(Map<String, Object?> map) {
            return $name(id: map['id'] as int, label: map['label'] as String);
          }

          @override
          Map<String, Object?> toMap() => {'type': 'L$leaf', 'id': id, 'label': label};

          @override
          bool operator ==(Object other) {
            return other is $name && other.id == id && other.label == label;
          }

          @override
          int get hashCode => Object.hash(id, label);
        }

        ''');
    }
    out
      ..writeCode('''
        final class $shelf {
          final List<$item> items;

          const $shelf({required this.items});

          factory $shelf.fromMap(Map<String, Object?> map) {
            return $shelf(
              items: [
                for (final item in map['items'] as List<Object?>)
                  $item.fromMap(item as Map<String, Object?>),
              ],
            );
          }

          Map<String, Object?> toMap() {
            return {
              'items': [for (final item in items) item.toMap()],
            };
          }

          @override
          bool operator ==(Object other) {
            if (other is! $shelf || other.items.length != items.length) {
              return false;
            }
            for (var i = 0; i < items.length; i++) {
              if (other.items[i] != items[i]) {
                return false;
              }
            }
            return true;
          }

          @override
          int get hashCode => Object.hashAll(items);
        }

        ''')
      ..writeln(
        _codec(
          size,
          toJson: '(value) => jsonEncode(value.toMap())',
          fromJson:
              '(text) => $shelf.fromMap(jsonDecode(text) as Map<String, Object?>)',
          toMap: '(value) => value.toMap()',
          fromMap: '$shelf.fromMap',
          hasEquality: true,
        ),
      );
  }
  return out.toString();
}

/// It has no sealed support, so this is the dispatch its users have to write.
String _jsonSerializable() {
  final out = StringBuffer()
    ..writeCode('''
      import 'dart:convert';

      import 'package:bench/codec.dart';
      import 'package:json_annotation/json_annotation.dart';

      part 'families.g.dart';

      final List<Extra> familyExtras = [];

      ''');
  for (final size in _sizes) {
    final item = 'Item$size';
    final shelf = 'Shelf$size';
    out.writeCode('''
      sealed class $item {
        const $item();

        factory $item.fromJson(Map<String, dynamic> json) {
          final type = json['type'] as String;
          return switch (type) {
      ''');
    for (final leaf in _leaves(size)) {
      out.writeln("      'L$leaf' => ${item}L$leaf.fromJson(json),");
    }
    out.writeCode('''
            _ => throw ArgumentError.value(type, 'type'),
          };
        }

        Map<String, dynamic> toJson();
      }

      ''');
    for (final leaf in _leaves(size)) {
      final name = '${item}L$leaf';
      out.writeCode('''
        @JsonSerializable(explicitToJson: true)
        final class $name extends $item {
          final int id;
          final String label;

          const $name({required this.id, required this.label});

          factory $name.fromJson(Map<String, dynamic> json) => _\$${name}FromJson(json);

          @override
          Map<String, dynamic> toJson() => {'type': 'L$leaf', ..._\$${name}ToJson(this)};
        }

        ''');
    }
    out
      ..writeCode('''
        @JsonSerializable(explicitToJson: true)
        final class $shelf {
          final List<$item> items;

          const $shelf({required this.items});

          factory $shelf.fromJson(Map<String, dynamic> json) => _\$${shelf}FromJson(json);

          Map<String, dynamic> toJson() => _\$${shelf}ToJson(this);
        }

        ''')
      ..writeln(
        _codec(
          size,
          toJson: '(value) => jsonEncode(value.toJson())',
          fromJson:
              '(text) => $shelf.fromJson(jsonDecode(text) as Map<String, dynamic>)',
          toMap: '(value) => value.toJson()',
          fromMap: '$shelf.fromJson',
          hasEquality: false,
        ),
      );
  }
  return out.toString();
}

String _dartMappable() {
  final out = StringBuffer()
    ..writeCode('''
      import 'package:bench/codec.dart';
      import 'package:dart_mappable/dart_mappable.dart';

      part 'families.mapper.dart';

      final List<Extra> familyExtras = [];

      ''');
  for (final size in _sizes) {
    final item = 'Item$size';
    final shelf = 'Shelf$size';
    final subclasses = _leaves(size).map((leaf) => '${item}L$leaf').join(', ');
    out.writeCode('''
      @MappableClass(discriminatorKey: 'type', includeSubClasses: [$subclasses])
      sealed class $item with ${item}Mappable {
        const $item();
      }

      ''');
    for (final leaf in _leaves(size)) {
      final name = '${item}L$leaf';
      out.writeCode('''
        @MappableClass(discriminatorValue: 'L$leaf')
        final class $name extends $item with ${name}Mappable {
          final int id;
          final String label;

          const $name({required this.id, required this.label});
        }

        ''');
    }
    out
      ..writeCode('''
        @MappableClass()
        final class $shelf with ${shelf}Mappable {
          final List<$item> items;

          const $shelf({required this.items});
        }

        ''')
      ..writeln(
        _codec(
          size,
          toJson: '(value) => value.toJson()',
          fromJson: '${shelf}Mapper.fromJson',
          toMap: '(value) => value.toMap()',
          fromMap: '${shelf}Mapper.fromMap',
          hasEquality: true,
        ),
      );
  }
  return out.toString();
}

String _freezed() {
  final out = StringBuffer()
    ..writeCode('''
      import 'dart:convert';

      import 'package:bench/codec.dart';
      import 'package:freezed_annotation/freezed_annotation.dart';

      part 'families.freezed.dart';
      part 'families.g.dart';

      final List<Extra> familyExtras = [];

      ''');
  for (final size in _sizes) {
    final item = 'Item$size';
    final shelf = 'Shelf$size';
    out.writeCode('''
      @Freezed(unionKey: 'type')
      sealed class $item with _\$$item {
      ''');
    for (final leaf in _leaves(size)) {
      out.writeCode('''
          @FreezedUnionValue('L$leaf')
          const factory $item.l$leaf({required int id, required String label}) = ${item}L$leaf;

        ''');
    }
    out
      ..writeCode('''
          factory $item.fromJson(Map<String, dynamic> json) => _\$${item}FromJson(json);
        }

        @freezed
        abstract class $shelf with _\$$shelf {
          const factory $shelf({required List<$item> items}) = _$shelf;

          factory $shelf.fromJson(Map<String, dynamic> json) => _\$${shelf}FromJson(json);
        }

        ''')
      ..writeln(
        _codec(
          size,
          toJson: '(value) => jsonEncode(value.toJson())',
          fromJson:
              '(text) => $shelf.fromJson(jsonDecode(text) as Map<String, dynamic>)',
          toMap: '(value) => value.toJson()',
          fromMap: '$shelf.fromJson',
          hasEquality: true,
        ),
      );
  }
  return out.toString();
}
