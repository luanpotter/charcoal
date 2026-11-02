import 'dart:convert';

import 'package:bench/codec.dart';
import 'package:bench/codecs.dart';
import 'package:bench/families.dart';
import 'package:bench/payloads.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

const int _warmupMillis = 100;
const int _measureMillis = 500;

void main() {
  _runAll('flat', flatCodec, flatPayload());
  _runAll('book', bookCodec, bookPayload(1));
  _runAll('catalog', catalogCodec, catalogPayload());
  _runAll('sealed2', shelf2Codec, shelfPayload(2));
  _runAll('sealed8', shelf8Codec, shelfPayload(8));
  _runAll('sealed44', shelf44Codec, shelfPayload(44));
  _runStrings('plain', passagePayload(isEscaped: false));
  _runStrings('escaped', passagePayload(isEscaped: true));
  [...extras, ...familyExtras].forEach(_runExtra);
}

void _runAll<T>(String name, Codec<T> codec, Map<String, Object?> payload) {
  final text = jsonEncode(payload);
  final value = codec.fromMap(payload);
  _checkFair(name, codec, value, text);

  _Scenario('$name.toJson', () => codec.toJson(value)).report();
  _Scenario('$name.fromJson', () => codec.fromJson(text)).report();
  _Scenario('$name.toMap', () => codec.toMap(value)).report();
  _Scenario('$name.fromMap', () => codec.fromMap(payload)).report();

  if (codec.hasEquality) {
    _runEquality(name, codec, value, payload);
  }
  if (codec.copies case final copies?) {
    _runCopies(name, copies, value);
  }
}

void _runEquality<T>(
  String name,
  Codec<T> codec,
  T value,
  Map<String, Object?> payload,
) {
  final same = codec.fromMap(payload);
  final otherFirst = codec.fromMap(withOtherFirst(payload));
  final otherLast = codec.fromMap(withOtherLast(payload));
  _checkEquality(name, value, same, [otherFirst, otherLast]);

  _Scenario('$name.equals', () => value == same).report();
  _Scenario('$name.equalsOtherFirst', () => value == otherFirst).report();
  _Scenario('$name.equalsOtherLast', () => value == otherLast).report();
  _Scenario('$name.hashCode', () => value.hashCode).report();
}

void _runCopies<T>(String name, Copies<T> copies, T value) {
  if (copies.same(value) != value ||
      copies.replacing(value) == value ||
      copies.clearing(value) == value) {
    throw StateError('$name.copyWith does not do what it should.');
  }

  _Scenario('$name.copyWith', () => copies.same(value)).report();
  _Scenario('$name.copyWithValue', () => copies.replacing(value)).report();
  _Scenario('$name.copyWithNull', () => copies.clearing(value)).report();
}

void _runStrings(String name, Map<String, Object?> payload) {
  final codec = passageCodec;
  final text = jsonEncode(payload);
  final value = codec.fromMap(payload);
  _checkFair('$name.passage', codec, value, text);

  _Scenario('$name.toJson', () => codec.toJson(value)).report();
  _Scenario('$name.fromJson', () => codec.fromJson(text)).report();
}

void _runExtra(Extra extra) {
  final result = extra.action();
  if (extra.expected != null && result != extra.expected) {
    throw StateError('${extra.name} returned $result.');
  }
  _Scenario(extra.name, extra.action).report();
}

/// Every library has to agree on the output, or the numbers mean nothing.
void _checkFair<T>(String name, Codec<T> codec, T value, String text) {
  // `jsonEncode` converts objects by itself, hiding a lazy `toMap` below.
  _checkPlain(name, codec.toMap(value));

  final expected = _canonical(text);
  final outputs = {
    'toJson': codec.toJson(value),
    'fromJson': codec.toJson(codec.fromJson(text)),
    'toMap': jsonEncode(codec.toMap(value)),
  };
  for (final MapEntry(:key, value: output) in outputs.entries) {
    if (_canonical(output) != expected) {
      throw StateError('$name.$key differs from the payload:\n$output\n$text');
    }
  }
}

void _checkEquality<T>(String name, T value, T same, List<T> others) {
  if (identical(value, same) ||
      value != same ||
      value.hashCode != same.hashCode ||
      others.any((other) => other == value)) {
    throw StateError('$name does not compare by value.');
  }
}

/// Libraries differ on where a tag goes, so keys have to be put in one order.
String _canonical(String json) => jsonEncode(_sorted(jsonDecode(json)));

Object? _sorted(Object? value) {
  return switch (value) {
    final Map<String, Object?> map => {
      for (final key in map.keys.toList()..sort()) key: _sorted(map[key]),
    },
    final List<Object?> list => list.map(_sorted).toList(),
    _ => value,
  };
}

void _checkPlain(String name, Object? value) {
  switch (value) {
    case null || String() || num() || bool():
      return;
    case final List<Object?> list:
      list.forEach((item) => _checkPlain(name, item));
    case final Map<String, Object?> map:
      map.values.forEach((item) => _checkPlain(name, item));
    default:
      throw StateError('$name.toMap left a ${value.runtimeType} inside.');
  }
}

final class _Scenario extends BenchmarkBase {
  final Object? Function() _action;
  Object? _sink;

  _Scenario(super.name, this._action);

  @override
  void run() => _sink = _action();

  /// The default runs it 10 times, reporting 10 times the actual cost.
  @override
  void exercise() => run();

  /// Shorter than the default of 2 seconds, as there are many of them, and each
  /// is repeated in several rounds anyway.
  @override
  double measure() {
    setup();
    BenchmarkBase.measureFor(warmup, _warmupMillis);
    final result = BenchmarkBase.measureFor(exercise, _measureMillis);
    teardown();
    return result;
  }

  @override
  void teardown() {
    if (_sink == null) {
      throw StateError('$name produced nothing.');
    }
  }
}
