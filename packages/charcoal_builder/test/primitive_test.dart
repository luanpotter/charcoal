import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('reads every primitive, nullable or aliased', () async {
    final result = await build(
      '''
      $header
      typedef Title = String;
      @Charcoal()
      class Book(
        this.a, this.b, this.c, this.d, this.e,
        this.f, this.g, this.h, this.i, this.j, this.k,
      ) with BookCharcoal {
        final String a;
        final int b;
        final double c;
        final num d;
        final bool e;
        final String? f;
        final int? g;
        final double? h;
        final num? i;
        final bool? j;
        final Title k;
      }
      ''',
      outputs: {
        output: decodedMatches(
          allOf([
            contains(r"$json['a'] as String"),
            contains(r"$json['b'] as int"),
            contains(r"($json['c'] as num).toDouble()"),
            contains(r"$json['d'] as num"),
            contains(r"$json['e'] as bool"),
            contains(r"'f': ?$it.f"),
            contains(r'final $v => $v as bool'),
            contains(r"$json['k'] as String"),
          ]),
        ),
      },
    );

    expect(result.succeeded, isTrue);
  });
}
