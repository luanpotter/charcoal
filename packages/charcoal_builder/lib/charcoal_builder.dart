import 'package:build/build.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';

Builder charcoalBuilder(BuilderOptions options) {
  return CharcoalBuilder(config: CharcoalConfig.fromMap(options.config));
}
