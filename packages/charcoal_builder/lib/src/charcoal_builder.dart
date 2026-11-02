import 'package:build/build.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';
import 'package:charcoal_builder/src/read/library_reader.dart';
import 'package:charcoal_builder/src/write/charcoal_writer.dart';

const _extension = '.charcoal.g.dart';

class CharcoalBuilder({
  this.config = const CharcoalConfig(),
}) implements Builder {
  final CharcoalConfig config;

  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': [_extension],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    if (!await buildStep.resolver.isLibrary(input)) {
      return;
    }

    final output = input.changeExtension(_extension);
    final reader = LibraryReader(buildStep.resolver, config);
    final model = await reader.read(
      await buildStep.inputLibrary,
      partFile: output.pathSegments.last,
    );

    if (reader.errors.isNotEmpty) {
      reader.errors.forEach(log.severe);
      return;
    }
    if (model.isEmpty) {
      return;
    }

    await buildStep.writeAsString(
      output,
      CharcoalWriter.write(partOf: input.pathSegments.last, model: model),
    );
  }
}
