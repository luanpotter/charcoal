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
import 'package:charcoal_builder/src/read/default_value_source.dart';

final Uri _charcoalLibrary = Uri.parse('package:charcoal/src/charcoal.dart');
final Uri _adapterLibrary = Uri.parse(
  'package:charcoal/src/charcoal_adapter.dart',
);

final class const _Adapter(this.element, this.adapted, this.wire) {
  final ClassElement element;
  final DartType adapted;
  final DartType wire;
}

final class LibraryReader(this._resolver, this._config) {
  final Resolver _resolver;
  final CharcoalConfig _config;
  final List<String> errors = [];

  /// Every adapter the library being read can see.
  List<_Adapter> _adapters = const [];

  /// A wire type has to be supported on its own, or adapters could loop.
  bool _isReadingWire = false;

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

    _adapters = _adaptersIn(library);
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

    final fields = await _readFields(element, constructor);
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

  /// Whatever implements `CharcoalAdapter` and is in scope without a prefix.
  List<_Adapter> _adaptersIn(LibraryElement library) {
    final classes = {
      ...library.classes,
      for (final import in library.firstFragment.libraryImports)
        if (import.prefix == null)
          ...import.namespace.definedNames2.values.whereType<ClassElement>(),
    };
    return [
      for (final element in classes)
        if (!element.isAbstract)
          for (final supertype in element.allSupertypes)
            if (supertype.element.name == 'CharcoalAdapter' &&
                supertype.element.library.uri == _adapterLibrary)
              _Adapter(
                element,
                supertype.typeArguments.first,
                supertype.typeArguments.last,
              ),
    ];
  }

  void _addError(String error) {
    if (!errors.contains(error)) {
      errors.add(error);
    }
  }

  FieldType? _adapterOf(DartType type, LibraryElement library) {
    if (_isReadingWire) {
      return null;
    }
    final typeSystem = library.typeSystem;
    final nonNullable = typeSystem.promoteToNonNull(type);
    final matches = _adapters.where((adapter) {
      return typeSystem.promoteToNonNull(adapter.adapted) == nonNullable;
    }).toList();
    if (matches.isEmpty) {
      return null;
    }
    if (matches.length > 1) {
      final names = matches.map((adapter) => adapter.element.name).join(', ');
      _addError(
        'There are two adapters for $nonNullable in scope: $names. '
        'Use `hide` on an import or export to pick one.',
      );
      return null;
    }
    return _useAdapter(matches.single, library);
  }

  FieldType? _useAdapter(_Adapter adapter, LibraryElement library) {
    final element = adapter.element;
    final adapted = adapter.adapted;
    final label = 'The adapter ${element.name}';

    final constructor = element.unnamedConstructor;
    final hasUsableConstructor =
        constructor != null &&
        constructor.isConst &&
        constructor.formalParameters.isEmpty;
    if (!hasUsableConstructor || element.typeParameters.isNotEmpty) {
      _addError(
        '$label needs a const constructor with no arguments, '
        'and no type parameters.',
      );
      return null;
    }
    if (adapted.nullabilitySuffix != NullabilitySuffix.none) {
      _addError('$label must adapt a non-nullable type.');
      return null;
    }
    if (!_isNameable(adapted, library)) {
      _addError('$label is for $adapted, which this library cannot name.');
      return null;
    }

    _isReadingWire = true;
    final wire = _fieldTypeOf(adapter.wire, library);
    _isReadingWire = false;
    if (wire == null) {
      _addError(
        '$label writes a ${adapter.wire}, which charcoal cannot serialize.',
      );
      return null;
    }
    return AdapterFieldType(
      typeName: adapted.getDisplayString(),
      adapter: 'const ${element.name}()',
      wire: wire,
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

  Future<List<FieldModel>> _readFields(
    ClassElement element,
    ConstructorElement constructor,
  ) async {
    final fields = <FieldModel>[];
    for (final parameter in constructor.formalParameters) {
      final parameterName = parameter.name!;
      final label = '${element.name}.$parameterName';
      if (parameter is! FieldFormalParameterElement) {
        errors.add('$label must be a `this.$parameterName` parameter.');
        continue;
      }

      final type = _fieldTypeOf(parameter.type, constructor.library);
      if (type == null) {
        errors.add(
          '$label is a ${parameter.type}, which charcoal cannot serialize. '
          'If it has a CharcoalAdapter, this library needs to import it.',
        );
        continue;
      }
      final defaultValue = parameter.computeConstantValue();
      fields.add(
        FieldModel(
          name: parameterName,
          type: type,
          isNamedParameter: parameter.isNamed,
          defaultValue: await _defaultSourceOf(parameter, element),
          isDefaultNull: defaultValue?.isNull ?? false,
          isDefaultEmpty: defaultValue != null && _isEmpty(defaultValue),
        ),
      );
    }
    return fields;
  }

  Future<String?> _defaultSourceOf(
    FormalParameterElement parameter,
    ClassElement owner,
  ) async {
    if (!parameter.hasDefaultValue) {
      return null;
    }
    final node = await _resolver.astNodeFor(
      parameter.firstFragment,
      resolve: true,
    );
    final expression = node is FormalParameter
        ? node.defaultClause?.value
        : null;
    return expression == null
        ? parameter.defaultValueCode
        : DefaultValueSource.of(expression, owner);
  }

  bool _isEmpty(DartObject value) {
    return value.toStringValue() == '' ||
        (value.toListValue()?.isEmpty ?? false) ||
        (value.toSetValue()?.isEmpty ?? false) ||
        (value.toMapValue()?.isEmpty ?? false);
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
        _adapterOf(type, library) ??
        _primitiveOf(type) ??
        _enumOf(type, library) ??
        _classOf(type, library) ??
        _extensionOf(type, library) ??
        _collectionOf(type, library);
    if (inner != null && type.nullabilitySuffix == NullabilitySuffix.question) {
      return NullableFieldType(inner);
    }
    return inner;
  }

  /// Null unless generated code can name, unwrap and construct it.
  FieldType? _extensionOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! ExtensionTypeElement || type is! InterfaceType) {
      return null;
    }
    final name = element.name!;
    final field = element.representation.name!;
    final constructor = element.primaryConstructor;
    final isLocal = element.library == library;
    final isAccessible =
        isLocal || (!field.startsWith('_') && !constructor.isPrivate);
    if (!isAccessible || !_isVisible(element, library)) {
      return null;
    }
    if (type.typeArguments.any((argument) => !_isNameable(argument, library))) {
      return null;
    }

    final representation = _fieldTypeOf(element.representation.type, library);
    if (representation == null) {
      return null;
    }
    final arguments = type.typeArguments
        .map((argument) => argument.getDisplayString())
        .join(', ');
    return ExtensionFieldType(
      typeName: arguments.isEmpty ? name : '$name<$arguments>',
      constructor: constructor.name == 'new'
          ? name
          : '$name.${constructor.name}',
      field: field,
      representation: representation,
    );
  }

  bool _isNameable(DartType type, LibraryElement library) {
    final element = type.element;
    if (element != null && !_isVisible(element, library)) {
      return false;
    }
    return type is! InterfaceType ||
        type.typeArguments.every((argument) {
          return _isNameable(argument, library);
        });
  }

  /// Null unless it can be rebuilt and every type it holds is supported.
  FieldType? _collectionOf(DartType type, LibraryElement library) {
    if (type is! InterfaceType) {
      return null;
    }
    final typeProvider = library.typeProvider;
    final map = type.asInstanceOf(typeProvider.mapElement);
    if (map != null) {
      return _mapOf(type, map, library);
    }
    final iterable = type.asInstanceOf(typeProvider.iterableElement);
    return iterable == null ? null : _iterableOf(type, iterable, library);
  }

  FieldType? _iterableOf(
    InterfaceType type,
    InterfaceType iterable,
    LibraryElement library,
  ) {
    final element = _fieldTypeOf(iterable.typeArguments.single, library);
    if (element == null) {
      return null;
    }
    if (type.isDartCoreList) {
      return IterableFieldType(element, IterableKind.list);
    }
    if (type.isDartCoreSet) {
      return IterableFieldType(element, IterableKind.set);
    }
    if (type.isDartCoreIterable) {
      return IterableFieldType(element, IterableKind.other);
    }
    final ofClass = _ofClassOf(type, 1, library);
    return ofClass == null
        ? null
        : IterableFieldType(element, IterableKind.other, ofClass: ofClass);
  }

  FieldType? _mapOf(
    InterfaceType type,
    InterfaceType map,
    LibraryElement library,
  ) {
    final [keyType, valueType] = map.typeArguments;
    final key = _mapKeyOf(keyType, library);
    final value = _fieldTypeOf(valueType, library);
    if (key == null || value == null) {
      return null;
    }
    if (type.isDartCoreMap) {
      return MapFieldType(key, value);
    }
    final ofClass = _ofClassOf(type, 2, library);
    return ofClass == null ? null : MapFieldType(key, value, ofClass: ofClass);
  }

  FieldType? _mapKeyOf(DartType type, LibraryElement library) {
    if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return null;
    }
    return type.isDartCoreString
        ? const PrimitiveFieldType(DartPrimitive.string)
        : _enumOf(type, library);
  }

  /// The class, if generated code can name it and call its `of` constructor.
  ///
  /// It must have the type parameters of what it holds, to declare it as such.
  String? _ofClassOf(InterfaceType type, int arity, LibraryElement library) {
    final element = type.element;
    final hasOf = element.getNamedConstructor('of') != null;
    final isUsable =
        hasOf &&
        element.typeParameters.length == arity &&
        _isVisible(element, library);
    return isUsable ? element.name : null;
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
