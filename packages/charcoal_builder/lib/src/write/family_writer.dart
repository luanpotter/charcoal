import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/write/code.dart';
import 'package:charcoal_builder/src/write/json_writer.dart';

/// Writes the mixin of a sealed class: what each leaf implements, and statics
/// over the leaves, as an exhaustive switch per operation.
abstract final class FamilyWriter() {
  static String write(FamilyModel model) {
    final interfaces = model.isRoot && !model.isGeneric
        ? ' implements CharcoalEncodable'
        : '';
    return code('''
      mixin ${model.owner}${model.typeParameters}$interfaces {
        ${_members(model)}

        ${model.isGeneric ? '' : _json(model)}

        ${_statics(model)}
      }
      ''');
  }

  /// What one use of a generic sealed class needs, knowing its type arguments.
  static String writeInstantiated(FamilyModel model) {
    return code('''
      abstract final class ${model.owner} {
        ${_directJson(model)}

        ${_statics(model)}
      }
      ''');
  }

  /// A generic sealed class has none, until a use knows the type arguments.
  static String _json(FamilyModel model) {
    final name = model.name;
    return code('''
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

      ${JsonWriter.decoder(name)}
      ''');
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
    return code('''
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
      ''');
  }

  /// What a holder calls, where a dynamic call on the root would cost more.
  static String _statics(FamilyModel model) {
    final name = model.name;
    final parameters = model.typeParameters;
    final isOther = model.leaves.length > 1 ? '_ => false, ' : '';
    final equals = _switch(model, on: r'$a', (leaf) {
      if (leaf.isComparedByOperator) {
        return r'$l == $b';
      }
      return r'switch ($b) { '
          'final ${leaf.pattern} \$r => ${leaf.owner}.\$equals(\$l, \$r), '
          '$isOther'
          '}';
    });
    final hash = _switch(model, (leaf) {
      return leaf.isComparedByOperator
          ? r'$l.hashCode'
          : '${leaf.owner}.\$hash(\$l)';
    });
    final statics = code('''
      static bool \$equals$parameters($name \$a, $name \$b) => $equals;

      static int \$hash$parameters($name \$it) => $hash;
      ''');
    if (model.isImmutable) {
      return statics;
    }
    // A leaf like `Estimated extends Lookup<int>` is only a `Lookup<T>` at run
    // time, as far as the compiler can tell inside of the generic class.
    final cast = model.isGeneric ? ' as $name' : '';
    final copy = _switch(model, (leaf) {
      return leaf.isImmutable ? '\$l$cast' : '${leaf.owner}.\$copy(\$l)$cast';
    });
    return code('''
      $statics

      static $name \$copy$parameters($name \$it) => $copy;
      ''');
  }

  /// Abstract, as each leaf has them already: a root declares them, and what
  /// is below it only narrows `copy`.
  static String _members(FamilyModel model) {
    final name = model.name;
    if (!model.isRoot || model.isImmutable) {
      return '$name copy();';
    }
    return code('''
      $name copy();

      bool contentEquals($name \$other);

      int get contentHash;
      ''');
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
    return code('''
      switch (\$tag) {
        $arms
        _ => throw ArgumentError.value(\$tag, 'tag', 'Unknown in ${model.baseName}'),
      }
      ''');
  }
}
