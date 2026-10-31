import 'package:build_test/build_test.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:test/test.dart';

void main() {
  test('charcoal builder runs', () async {
    final result = await testBuilder(
      CharcoalBuilder(),
      {'package_name|lib/book.dart': 'class Book {}'},
      outputs: {},
    );

    expect(result.succeeded, isTrue);
  });
}
