import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/write/json_writer.dart';

/// Writes what a sealed class generates, as an exhaustive switch per operation.
abstract final class FamilyWriter() {
  static String write(FamilyModel model) {
    if (model.isGeneric) {
      return _generic(model);
    }
    final name = model.name;
    return '''
abstract final class ${model.owner} {
  ${_directJson(model)}

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

  ${model.isImmutable ? '' : _mutableStatics(model)}
}

extension ${name}CharcoalMembers on $name {
  Map<String, Object?> toMap() => ${model.owner}.\$encode(this);

  void writeJson(StringBuffer \$sink) => ${model.owner}.\$write(this, \$sink);

  String toJsonString() => ${model.owner}.encodeJsonString(this);

  ${_members(model)}
}
''';
  }

  /// A generic sealed class has no JSON, until a use knows the type arguments.
  static String _generic(FamilyModel model) {
    final parameters = model.typeParameters;
    return '''
${model.isImmutable ? '' : 'abstract final class ${model.owner} {\n${_mutableStatics(model)}\n}'}

extension ${model.baseName}CharcoalMembers$parameters on ${model.name} {
  ${_members(model)}
}
''';
  }

  /// What one use of a generic sealed class needs, knowing its type arguments.
  static String writeInstantiated(FamilyModel model) {
    return '''
abstract final class ${model.owner} {
  ${_directJson(model)}

  ${model.isImmutable ? '' : _mutableStatics(model)}
}
''';
  }

  static String _directJson(FamilyModel model) {
    final name = model.name;
    final key = JsonWriter.stringLiteral(model.discriminator);
    final writes = model.leaves
        .map((leaf) {
          return 'case final ${leaf.pattern} \$l: '
              '${leaf.owner}.\$write(\$l, \$sink);';
        })
        .join('\n');
    return '''
  static Map<String, Object?> \$encode($name \$it) =>
      ${_switch(model, (leaf) => '${leaf.owner}.\$encode(\$l)')};

  static void \$write($name \$it, StringBuffer \$sink) {
    switch (\$it) {
      $writes
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
''';
  }

  static String _mutableStatics(FamilyModel model) {
    final name = model.name;
    final parameters = model.typeParameters;
    // A leaf like `Estimated extends Lookup<int>` is only a `Lookup<T>` at run
    // time, as far as the compiler can tell inside of the generic class.
    final cast = model.isGeneric ? ' as $name' : '';
    final equals = _switch(model, on: r'$a', (leaf) {
      return r'switch ($b) { '
          'final ${leaf.pattern} \$r => ${leaf.owner}.\$equals(\$l, \$r), '
          '_ => false, '
          '}';
    });
    final hash = _switch(model, (leaf) => '${leaf.owner}.\$hash(\$l)');
    final copy = _switch(model, (leaf) {
      return leaf.isImmutable ? '\$l$cast' : '${leaf.owner}.\$copy(\$l)$cast';
    });
    return '''
  static bool \$equals$parameters($name \$a, $name \$b) => $equals;

  static int \$hash$parameters($name \$it) => $hash;

  static $name \$copy$parameters($name \$it) => $copy;
''';
  }

  static String _members(FamilyModel model) {
    final name = model.name;
    final owner = model.owner;
    if (model.isImmutable) {
      return '$name copy() => this;';
    }
    return '''
  $name copy() => $owner.\$copy(this);

  bool contentEquals($name \$other) => $owner.\$equals(this, \$other);

  int get contentHash => $owner.\$hash(this);
''';
  }

  static String _switch(
    FamilyModel model,
    String Function(LeafModel leaf) armOf, {
    String on = r'$it',
  }) {
    final arms = model.leaves
        .map((leaf) => 'final ${leaf.pattern} \$l => ${armOf(leaf)},')
        .join('\n');
    return 'switch ($on) {\n$arms\n}';
  }

  static String _byTag(FamilyModel model, String call) {
    final arms = model.leaves
        .map((leaf) {
          final tag = JsonWriter.stringLiteral(leaf.tag);
          return '$tag => ${leaf.owner}.$call,';
        })
        .join('\n');
    return '''
switch (\$tag) {
  $arms
  _ => throw ArgumentError.value(\$tag, 'tag', 'Unknown in ${model.baseName}'),
}''';
  }
}
