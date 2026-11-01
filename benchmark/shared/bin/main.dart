import 'dart:convert';

import 'package:bench/codec.dart';
import 'package:bench/codecs.dart';
import 'package:bench/payloads.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  _runAll('flat', flatCodec, flatPayload());
  _runAll('book', bookCodec, bookPayload(1));
  _runAll('catalog', catalogCodec, catalogPayload());
}

void _runAll<T>(String name, Codec<T> codec, Map<String, Object?> payload) {
  final text = jsonEncode(payload);
  final value = codec.fromMap(payload);
  _checkFair(name, codec, value, text);

  _Scenario('$name.toJson', () => codec.toJson(value)).report();
  _Scenario('$name.fromJson', () => codec.fromJson(text)).report();
  _Scenario('$name.toMap', () => codec.toMap(value)).report();
  _Scenario('$name.fromMap', () => codec.fromMap(payload)).report();
}

/// Every library has to agree on the output, or the numbers mean nothing.
void _checkFair<T>(String name, Codec<T> codec, T value, String text) {
  final outputs = {
    'toJson': codec.toJson(value),
    'fromJson': codec.toJson(codec.fromJson(text)),
    'toMap': jsonEncode(codec.toMap(value)),
  };
  for (final MapEntry(:key, value: output) in outputs.entries) {
    if (output != text) {
      throw StateError('$name.$key differs from the payload:\n$output\n$text');
    }
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

  @override
  void teardown() {
    if (_sink == null) {
      throw StateError('$name produced nothing.');
    }
  }
}
