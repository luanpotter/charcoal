import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:charcoal_builder/src/charcoal_writer.dart';

final _charcoalLibrary = Uri.parse('package:charcoal/src/charcoal.dart');

class CharcoalBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final input = buildStep.inputId;
    if (!await buildStep.resolver.isLibrary(input)) {
      return;
    }

    final library = await buildStep.inputLibrary;
    final classes = library.classes.where(_isAnnotated).map((e) => e.name);
    if (classes.isEmpty) {
      return;
    }

    await buildStep.writeAsString(
      input.changeExtension('.g.dart'),
      CharcoalWriter.write(
        partOf: input.pathSegments.last,
        classes: classes.nonNulls,
      ),
    );
  }

  bool _isAnnotated(ClassElement element) {
    return element.metadata.annotations.any((annotation) {
      final type = annotation.computeConstantValue()?.type?.element;
      return type?.name == 'Charcoal' && type?.library?.uri == _charcoalLibrary;
    });
  }
}
