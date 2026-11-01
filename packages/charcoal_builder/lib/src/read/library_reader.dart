import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:charcoal/charcoal.dart';
import 'package:charcoal_builder/src/charcoal_config.dart';
import 'package:charcoal_builder/src/model/class_model.dart';
import 'package:charcoal_builder/src/model/field_type.dart';

final Uri _charcoalLibrary = Uri.parse('package:charcoal/src/charcoal.dart');

final class LibraryReader(this._resolver, this._config) {
  final Resolver _resolver;
  final CharcoalConfig _config;
  final List<String> errors = [];

  Future<List<ClassModel>> read(
    LibraryElement library, {
    required String partFile,
  }) async {
    final annotated = library.classes
        .where((element) => _annotationOf(element) != null)
        .toList();
    if (annotated.isEmpty) {
      return [];
    }

    if (!_hasPart(library, partFile)) {
      errors.add("Missing part: add `part '$partFile';` to this library.");
    }

    return [for (final element in annotated) await _readClass(element)];
  }

  DartObject? _annotationOf(ClassElement element) {
    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      final type = value?.type?.element;
      if (type?.name == 'Charcoal' && type?.library?.uri == _charcoalLibrary) {
        return value;
      }
    }
    return null;
  }

  Omit _omitOf(ClassElement element) {
    final name = _annotationOf(element)?.getField('omit')?.variable?.name;
    return name == null ? _config.omit : Omit.values.byName(name);
  }

  bool _hasPart(LibraryElement library, String partFile) {
    return library.firstFragment.partIncludes.any((part) {
      final uri = part.uri;
      return uri is DirectiveUriWithRelativeUriString &&
          uri.relativeUriString == partFile;
    });
  }

  Future<ClassModel> _readClass(ClassElement element) async {
    final name = element.name!;

    if (element.isPrivate) {
      errors.add('$name is private, so it cannot be annotated.');
    }
    if (element.isAbstract || element.isSealed) {
      errors.add('$name is abstract, which is not supported yet.');
    }
    if (element.typeParameters.isNotEmpty) {
      errors.add('$name is generic, which is not supported yet.');
    }
    if (element.supertype?.isDartCoreObject == false) {
      errors.add('$name extends a class, which is not supported yet.');
    }
    if (!await _hasMixin(element)) {
      errors.add('$name must declare `with ${name}Charcoal`.');
    }

    final constructor = _wireConstructor(element);
    if (constructor == null) {
      errors.add(
        '$name has no usable constructor: '
        'it needs an unnamed or a primary one.',
      );
      return ClassModel(
        name: name,
        constructor: name,
        omit: _config.omit,
        fields: const [],
      );
    }

    final fields = _readFields(name, constructor);
    _checkOtherFields(element, fields);

    return ClassModel(
      name: name,
      constructor: constructor.name == 'new'
          ? name
          : '$name.${constructor.name}',
      omit: _omitOf(element),
      fields: fields,
    );
  }

  /// Read from the syntax, as the generated mixin may not exist yet.
  Future<bool> _hasMixin(ClassElement element) async {
    final node = await _resolver.astNodeFor(element.firstFragment);
    if (node is! ClassDeclaration) {
      return false;
    }
    final mixins = node.withClause?.mixinTypes ?? const <NamedType>[];
    final expected = '${element.name}Charcoal';
    return mixins.any((mixin) => mixin.name.lexeme == expected);
  }

  /// The unnamed constructor, factory or not, else the primary one.
  ConstructorElement? _wireConstructor(ClassElement element) {
    return element.unnamedConstructor ??
        element.constructors.where((e) => e.isPrimary).firstOrNull;
  }

  List<FieldModel> _readFields(String name, ConstructorElement constructor) {
    final fields = <FieldModel>[];
    for (final parameter in constructor.formalParameters) {
      final parameterName = parameter.name!;
      final label = '$name.$parameterName';
      if (parameter is! FieldFormalParameterElement) {
        errors.add('$label must be a `this.$parameterName` parameter.');
        continue;
      }
      if (parameter.hasDefaultValue) {
        errors.add('$label has a default, which is not supported yet.');
      }

      final type = _fieldTypeOf(parameter.type, constructor.library);
      if (type == null) {
        errors.add(
          '$label is a ${parameter.type}, which charcoal cannot serialize.',
        );
        continue;
      }
      fields.add(
        FieldModel(
          name: parameterName,
          type: type,
          isNamedParameter: parameter.isNamed,
        ),
      );
    }
    return fields;
  }

  void _checkOtherFields(ClassElement element, List<FieldModel> fields) {
    final parameters = _wireConstructor(element)!.formalParameters
        .map((parameter) => parameter.name)
        .toSet();
    for (final field in element.fields) {
      final isSkipped =
          field.isStatic || field.isLate || field.isOriginGetterSetter;
      if (!isSkipped && !parameters.contains(field.name)) {
        errors.add(
          '${element.name}.${field.name} is not a constructor parameter, '
          'so a round trip would lose it.',
        );
      }
    }
  }

  FieldType? _fieldTypeOf(DartType type, LibraryElement library) {
    final inner =
        _primitiveOf(type) ?? _enumOf(type, library) ?? _classOf(type, library);
    if (inner != null && type.nullabilitySuffix == NullabilitySuffix.question) {
      return NullableFieldType(inner);
    }
    return inner;
  }

  /// Null if generated code could not name it, or if `name` is overridden.
  FieldType? _enumOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! EnumElement || element.getGetter('name') != null) {
      return null;
    }
    return _isVisible(element, library) ? EnumFieldType(element.name!) : null;
  }

  /// Null unless it has generated code that can decode a concrete instance.
  FieldType? _classOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! ClassElement ||
        _annotationOf(element) == null ||
        element.isAbstract ||
        element.isSealed ||
        element.typeParameters.isNotEmpty) {
      return null;
    }
    return _isVisible(element, library) ? ClassFieldType(element.name!) : null;
  }

  bool _isVisible(Element element, LibraryElement library) {
    return library.firstFragment.scope.lookup(element.name!).getter == element;
  }

  /// Null for any other type, which becomes a build error naming the field.
  FieldType? _primitiveOf(DartType type) {
    final element = type.element;
    if (element == null || element.library?.isDartCore != true) {
      return null;
    }
    final primitive = DartPrimitive.values
        .where((primitive) => primitive.typeName == element.name)
        .firstOrNull;
    return primitive == null ? null : PrimitiveFieldType(primitive);
  }
}
