import 'package:build/build.dart';

class CharcoalBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // TODO(luan): implement charcoal
  }
}
