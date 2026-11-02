import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/write/json_writer.dart';

/// Writes what a sealed class generates, as an exhaustive switch per operation.
abstract final class FamilyWriter() {
  static String write(FamilyModel model) {
    final name = model.name;
    final key = JsonWriter.stringLiteral(model.discriminator);

    return '''
abstract final class ${name}Charcoal {
  static Map<String, Object?> \$encode($name \$it) =>
      ${_switch(model, (leaf) => '${leaf.name}Charcoal.\$encode(\$l)')};

  static void \$write($name \$it, StringBuffer \$sink) {
    switch (\$it) {
      ${model.leaves.map((leaf) => 'case final ${leaf.name} \$l: ${leaf.name}Charcoal.\$write(\$l, \$sink);').join('\n')}
    }
  }

  static String encodeJsonString($name \$it) {
    final \$sink = StringBuffer();
    \$write(\$it, \$sink);
    return \$sink.toString();
  }

  static $name fromMap(Map<String, Object?> \$json) {
    try {
      return \$decode(\$json);
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static $name fromJsonString(String \$source) {
    try {
      final \$r = CharcoalJsonReader(\$source);
      final \$it = \$read(\$r);
      \$r.finish();
      return \$it;
    } catch (\$error, \$stack) {
      Error.throwWithStackTrace(CharcoalException('$name', \$error), \$stack);
    }
  }

  static $name \$decode(Map<String, Object?> \$json) {
    final \$tag = \$json[$key] as String;
    return ${_byTag(model, r'$decode($json)')};
  }

  static $name \$read(CharcoalJsonReader \$r) {
    final \$tag = \$r.peekStringField($key);
    return ${_byTag(model, r'$read($r)')};
  }

  ${model.isImmutable ? '' : _mutableStatics(model)}
}

extension ${name}CharcoalMembers on $name {
  Map<String, Object?> toMap() => ${name}Charcoal.\$encode(this);

  void writeJson(StringBuffer \$sink) => ${name}Charcoal.\$write(this, \$sink);

  String toJsonString() => ${name}Charcoal.encodeJsonString(this);

  ${model.isImmutable ? '$name copy() => this;' : _mutableMembers(name)}
}
''';
  }

  static String _mutableStatics(FamilyModel model) {
    final name = model.name;
    final equals = _switch(model, (leaf) {
      final leafName = leaf.name;
      return '\$b is $leafName && ${leafName}Charcoal.\$equals(\$l, \$b)';
    }, on: r'$a');
    final hash = _switch(model, (leaf) => '${leaf.name}Charcoal.\$hash(\$l)');
    final copy = _switch(model, (leaf) {
      return leaf.isImmutable ? r'$l' : '${leaf.name}Charcoal.\$copy(\$l)';
    });
    return '''
  static bool \$equals($name \$a, $name \$b) => $equals;

  static int \$hash($name \$it) => $hash;

  static $name \$copy($name \$it) => $copy;
''';
  }

  static String _mutableMembers(String name) {
    return '''
  $name copy() => ${name}Charcoal.\$copy(this);

  bool contentEquals($name \$other) => ${name}Charcoal.\$equals(this, \$other);

  int get contentHash => ${name}Charcoal.\$hash(this);
''';
  }

  static String _switch(
    FamilyModel model,
    String Function(LeafModel leaf) armOf, {
    String on = r'$it',
  }) {
    final arms = model.leaves
        .map((leaf) => 'final ${leaf.name} \$l => ${armOf(leaf)},')
        .join('\n');
    return 'switch ($on) {\n$arms\n}';
  }

  static String _byTag(FamilyModel model, String call) {
    final arms = model.leaves
        .map((leaf) {
          final tag = JsonWriter.stringLiteral(leaf.tag);
          return '$tag => ${leaf.name}Charcoal.$call,';
        })
        .join('\n');
    return '''
switch (\$tag) {
  $arms
  _ => throw ArgumentError.value(\$tag, 'tag', 'Unknown in ${model.name}'),
}''';
  }
}
