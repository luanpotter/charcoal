import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';
import 'package:test/test.dart';

const String output = 'package_name|lib/book.charcoal.g.dart';
const String header = """
import 'package:charcoal/charcoal.dart';
part 'book.charcoal.g.dart';
""";

const String _package = 'package_name';
const String _partExtension = '.charcoal.g.dart';

/// Loading every source is slow, and tests only need what charcoal has.
final Future<Map<AssetId, List<int>>> _charcoalSources = _loadCharcoalSources();

Future<Map<AssetId, List<int>>> _loadCharcoalSources() async {
  final readerWriter = TestReaderWriter(rootPackage: _package);
  await readerWriter.testing.loadIsolateSources();
  return {
    for (final id in readerWriter.testing.assets)
      if (id.package == 'charcoal') id: readerWriter.testing.readBytes(id),
  };
}

/// Builds `book.dart`, failing if what was generated does not compile.
Future<TestBuilderResult> build(
  String source, {
  Map<String, Object> outputs = const {},
  Map<String, dynamic> config = const {},
  Map<String, String> assets = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: _package);
  (await _charcoalSources).forEach(readerWriter.testing.writeBytes);
  return await testBuilders(
    [
      CharcoalBuilder(config: CharcoalConfig.fromMap(config)),
      _CompilesBuilder(),
    ],
    {'$_package|lib/book.dart': source, ...assets},
    outputs: outputs,
    readerWriter: readerWriter,
  );
}

Future<void> expectBuildError(String source, String message) async {
  final result = await build(source);

  expect(result.succeeded, isFalse);
  expect(result.errors.join('\n'), contains(message));
}

/// Fails the build on any error in a library with a generated part.
final class _CompilesBuilder() implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.compiles'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    final part = input.changeExtension(_partExtension);
    final isGenerated = await buildStep.canRead(part);
    if (!isGenerated || !await buildStep.resolver.isLibrary(input)) {
      return;
    }

    final library = await buildStep.inputLibrary;
    for (final fragment in library.fragments) {
      final path = fragment.source.fullName;
      final result = await library.session.getErrors(path);
      if (result is ErrorsResult) {
        result.diagnostics.where(_isError).forEach((diagnostic) {
          log.severe('Generated code fails to compile: $path: $diagnostic');
        });
      }
    }
  }

  bool _isError(Diagnostic diagnostic) {
    return diagnostic.severity == Severity.error;
  }
}
