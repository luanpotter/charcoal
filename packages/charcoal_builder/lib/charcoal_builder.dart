/// The `build_runner` generator for classes annotated with `@Charcoal()`.
///
/// Add it as a dev dependency next to `build_runner`, then generate with
/// `dart run build_runner build`. It applies to dependents automatically.
///
/// A project can set a default for the annotation's options in `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       charcoal_builder:charcoal:
///         options:
///           omit: none
/// ```
library;

import 'package:build/build.dart';
import 'package:charcoal_builder/src/charcoal_builder.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';

/// Creates the builder, which `build_runner` calls using `build.yaml`.
///
/// Throws an [ArgumentError] on any unknown option or value in [options].
Builder charcoalBuilder(BuilderOptions options) {
  return CharcoalBuilder(config: CharcoalConfig.fromMap(options.config));
}
