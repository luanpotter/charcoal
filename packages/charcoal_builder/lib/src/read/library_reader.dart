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
import 'package:charcoal_builder/src/read/instantiation_graph.dart';

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

  /// The library being read, whose scope all generated code lives in.
  late LibraryElement _library;

  /// The type parameters of the generic class being read, if any.
  Set<TypeParameterElement> _typeParameters = const {};

  /// Each use of a generic class found so far, by how it is written.
  final Map<String, ClassFieldType> _instantiations = {};

  /// The uses of a generic class that were not read yet.
  final List<(InterfaceType, ClassFieldType)> _pending = [];

  Future<LibraryModel> read(
    LibraryElement library, {
    required String partFile,
  }) async {
    final covered = library.classes.where(_isCovered).toList();
    if (covered.isEmpty) {
      return const LibraryModel();
    }

    if (!_hasPart(library, partFile)) {
      errors.add("Missing part: add `part '$partFile';` to this library.");
    }

    _library = library;
    _adapters = _adaptersIn(library);
    final classes = [
      for (final element in covered)
        if (!element.isSealed) await _readClass(element),
    ];
    final families = [
      for (final element in covered)
        if (element.isSealed) _readFamily(element),
    ];

    final instantiatedClasses = <ClassModel>[];
    final instantiatedFamilies = <FamilyModel>[];
    while (_pending.isNotEmpty) {
      final (type, field) = _pending.removeLast();
      final element = type.element;
      if (element is ClassElement && element.isSealed) {
        instantiatedFamilies.add(_readInstantiatedFamily(type, element, field));
      } else if (element is ClassElement) {
        final model = await _readInstantiatedClass(type, element, field);
        instantiatedClasses.add(model);
      }
    }

    return LibraryModel(
      classes: classes,
      families: families,
      instantiatedClasses: instantiatedClasses,
      instantiatedFamilies: instantiatedFamilies,
    );
  }

  /// Its type parameters as declared, such as `<T extends num>`.
  String _typeParametersOf(ClassElement element) {
    if (element.typeParameters.isEmpty) {
      return '';
    }
    final parameters = element.typeParameters.map((parameter) {
      final bound = parameter.bound;
      return bound == null
          ? parameter.name!
          : '${parameter.name} extends ${bound.getDisplayString()}';
    });
    return '<${parameters.join(', ')}>';
  }

  /// How the class itself writes its type, such as `Link<T>`.
  String _selfNameOf(ClassElement element) {
    final name = element.name!;
    if (element.typeParameters.isEmpty) {
      return name;
    }
    final parameters = element.typeParameters.map((e) => e.name!).join(', ');
    return '$name<$parameters>';
  }

  /// Concrete classes below a sealed one, always in the same library.
  Iterable<ClassElement> _leavesOf(ClassElement element) {
    return element.library.classes.where((other) {
      return !other.isAbstract &&
          !other.isSealed &&
          _supertypesOf(other).contains(element);
    });
  }

  String _tagOf(ClassElement element) {
    return _stringOption(element, 'tag') ?? element.name!;
  }

  /// Annotated, or below a sealed class that is.
  bool _isCovered(ClassElement element) {
    return _annotationOf(element) != null ||
        _supertypesOf(element).any((supertype) {
          return supertype.isSealed && _annotationOf(supertype) != null;
        });
  }

  Iterable<ClassElement> _supertypesOf(ClassElement element) {
    return element.allSupertypes
        .map((type) => type.element)
        .whereType<ClassElement>();
  }

  Iterable<ClassElement> _superclassesOf(ClassElement element) sync* {
    var type = element.supertype;
    while (type != null && !type.isDartCoreObject) {
      final superclass = type.element;
      if (superclass is ClassElement) {
        yield superclass;
      }
      type = superclass.supertype;
    }
  }

  /// The covered sealed classes at the top of whatever it is under.
  Iterable<ClassElement> _rootsOf(ClassElement element) {
    bool isCoveredSealed(ClassElement other) {
      return other.isSealed && _isCovered(other);
    }

    return [
      if (element.isSealed) element,
      ..._supertypesOf(element).where(isCoveredSealed),
    ].where((candidate) => !_supertypesOf(candidate).any(isCoveredSealed));
  }

  String _discriminatorOf(ClassElement element) {
    final keys = _rootsOf(element).map(_ownDiscriminatorOf).toSet();
    if (keys.length > 1) {
      _addError(
        '${element.name} is under sealed classes with different discriminators:'
        ' ${keys.join(', ')}.',
      );
    }
    return keys.firstOrNull ?? _config.discriminator;
  }

  String _ownDiscriminatorOf(ClassElement root) {
    return _stringOption(root, 'discriminator') ?? _config.discriminator;
  }

  String? _stringOption(ClassElement element, String option) {
    return _annotationOf(element)?.getField(option)?.toStringValue();
  }

  FamilyModel _readFamily(ClassElement element) {
    final name = element.name!;
    if (element.isPrivate) {
      errors.add('$name is private, so it cannot be annotated.');
    }
    if (_stringOption(element, 'tag') != null) {
      errors.add('$name sets a tag, which only a class it covers can.');
    }
    final isRoot = _rootsOf(element).contains(element);
    if (!isRoot && _stringOption(element, 'discriminator') != null) {
      errors.add('$name sets a discriminator, which only a sealed root can.');
    }
    _checkSuperclass(element);

    final isGeneric = element.typeParameters.isNotEmpty;
    final leaves = [
      for (final other in _leavesOf(element))
        LeafModel(
          pattern: _genericPatternOf(other, element),
          owner: '${other.name}Charcoal',
          tag: _tagOf(other),
          isImmutable: _isImmutable(other),
        ),
    ];
    for (final other in _leavesOf(element)) {
      if (!isGeneric && other.typeParameters.isNotEmpty) {
        errors.add(
          '${other.name} is generic but $name is not, so decoding a $name '
          'could not know its type arguments.',
        );
      }
    }
    if (leaves.isEmpty) {
      errors.add('$name is sealed, but has no classes to decode.');
    }
    final tags = <String>{};
    for (final leaf in leaves) {
      if (!tags.add(leaf.tag)) {
        errors.add('$name has two classes with the tag ${leaf.tag}.');
      }
    }

    return FamilyModel(
      name: _selfNameOf(element),
      baseName: name,
      owner: '${name}Charcoal',
      discriminator: _discriminatorOf(element),
      isImmutable: _isImmutable(element),
      leaves: leaves,
      typeParameters: _typeParametersOf(element),
    );
  }

  /// One use of a generic sealed class, with only the leaves that can fit it.
  FamilyModel _readInstantiatedFamily(
    InterfaceType type,
    ClassElement element,
    ClassFieldType field,
  ) {
    final leaves = <LeafModel>[];
    for (final other in _leavesOf(element)) {
      final leafType = _instantiateLeaf(other, type);
      if (leafType == null) {
        continue;
      }
      final leaf = _fieldTypeOf(leafType, _library);
      if (leaf is! ClassFieldType) {
        errors.add(
          '${field.name} needs ${other.name}, which this library cannot name.',
        );
        continue;
      }
      leaves.add(
        LeafModel(
          pattern: leaf.name,
          owner: leaf.owner,
          tag: _tagOf(other),
          isImmutable: leaf.isImmutable,
        ),
      );
    }
    if (leaves.isEmpty) {
      errors.add('${field.name} has no class below it that fits.');
    }
    return FamilyModel(
      name: field.name,
      baseName: element.name!,
      owner: field.owner,
      discriminator: _discriminatorOf(element),
      isImmutable: field.isImmutable,
      leaves: leaves,
    );
  }

  /// The leaf with the type arguments it gets as [target], if it can be one.
  InterfaceType? _instantiateLeaf(ClassElement leaf, InterfaceType target) {
    final instantiated = _bindLeaf(leaf, target);
    return instantiated != null &&
            _library.typeSystem.isSubtypeOf(instantiated, target)
        ? instantiated
        : null;
  }

  /// How a generic sealed class matches a leaf, in its own type parameters.
  String _genericPatternOf(ClassElement leaf, ClassElement root) {
    return _bindLeaf(leaf, root.thisType)?.getDisplayString() ?? leaf.name!;
  }

  /// The leaf with whatever type arguments [target] gives it, if all are known.
  InterfaceType? _bindLeaf(ClassElement leaf, InterfaceType target) {
    final declared = leaf.thisType.asInstanceOf(target.element)?.typeArguments;
    if (declared == null) {
      return null;
    }
    final bound = <TypeParameterElement, DartType>{};
    for (final (index, argument) in declared.indexed) {
      if (argument is TypeParameterType) {
        bound[argument.element] ??= target.typeArguments[index];
      }
    }
    final arguments = [
      for (final parameter in leaf.typeParameters) bound[parameter],
    ];
    if (arguments.contains(null)) {
      return null;
    }
    return leaf.instantiate(
      typeArguments: arguments.nonNulls.toList(),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  /// One use of a generic class, with fields of the real types.
  Future<ClassModel> _readInstantiatedClass(
    InterfaceType type,
    ClassElement element,
    ClassFieldType field,
  ) async {
    final wire = _wireConstructor(element);
    final constructor = type.constructors
        .where((candidate) => candidate.name == wire?.name)
        .firstOrNull;
    final isReachable =
        constructor != null &&
        (!constructor.isPrivate || element.library == _library);
    if (!isReachable) {
      errors.add('${field.name} has no constructor this library can call.');
    }

    _typeParameters = const {};
    final fields = constructor == null
        ? const <FieldModel>[]
        : await _readFields(element, constructor, label: field.name);
    for (final model in fields) {
      _checkSets('${field.name}.${model.name}', model);
    }
    return ClassModel(
      name: field.name,
      baseName: element.name!,
      constructor: constructor == null || constructor.name == 'new'
          ? field.name
          : '${field.name}.${constructor.name}',
      owner: field.owner,
      omit: _omitOf(element),
      fields: fields,
      isImmutable: field.isImmutable,
      familyTag: _familyTagOf(element),
      handWritten: _handWrittenOf(element),
    );
  }

  FamilyTag? _familyTagOf(ClassElement element) {
    return _rootsOf(element).isEmpty
        ? null
        : FamilyTag(key: _discriminatorOf(element), value: _tagOf(element));
  }

  void _checkSuperclass(ClassElement element) {
    final superclass = element.supertype?.element;
    final isAllowed =
        element.supertype?.isDartCoreObject != false ||
        (superclass is ClassElement &&
            superclass.isSealed &&
            _isCovered(superclass));
    if (!isAllowed) {
      errors.add(
        '${element.name} extends a class that no sealed @Charcoal class '
        'covers, so its fields could not be read.',
      );
    }
  }

  void _checkOptions(ClassElement element, List<FieldModel> fields) {
    final name = element.name!;
    if (_stringOption(element, 'discriminator') != null) {
      errors.add('$name sets a discriminator, which only a sealed root can.');
    }
    if (_rootsOf(element).isEmpty) {
      if (_stringOption(element, 'tag') != null) {
        errors.add('$name sets a tag, but no sealed class covers it.');
      }
      return;
    }
    final discriminator = _discriminatorOf(element);
    if (fields.any((field) => field.name == discriminator)) {
      errors.add('$name.$discriminator is named as the discriminator.');
    }
  }

  Set<String> _handWrittenOf(ClassElement element) {
    final owners = [element, ..._superclassesOf(element)];
    return {
      for (final member in const ['==', 'toString', 'copy', 'copyWith'])
        if (owners.any((owner) => _defines(owner, member))) member,
    };
  }

  bool _defines(ClassElement element, String member) {
    return element.getMethod(member)?.isAbstract == false ||
        element.getGetter(member)?.isAbstract == false;
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
    final candidates = [
      element,
      ..._superclassesOf(element),
      ..._supertypesOf(element),
    ];
    for (final candidate in candidates) {
      final name = _annotationOf(candidate)?.getField('omit')?.variable?.name;
      if (name != null) {
        return Omit.values.byName(name);
      }
    }
    return _config.omit;
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
    if (element.isAbstract) {
      errors.add('$name is abstract but not sealed, so it cannot be decoded.');
    } else if (!element.isFinal) {
      errors.add('$name must be final, or sealed, so that no subclass exists.');
    }
    _checkSuperclass(element);
    if (!await _hasMixin(element)) {
      errors.add('$name must declare `with ${name}Charcoal`.');
    }

    final selfName = _selfNameOf(element);
    final owner = '${name}Charcoal';
    final constructor = _wireConstructor(element);
    if (constructor == null) {
      errors.add(
        '$name has no usable constructor: '
        'it needs an unnamed or a primary one.',
      );
      return ClassModel(
        name: selfName,
        baseName: name,
        constructor: selfName,
        owner: owner,
        omit: _config.omit,
        fields: const [],
      );
    }

    _typeParameters = element.typeParameters.toSet();
    final fields = await _readFields(element, constructor, label: name);
    _typeParameters = const {};
    _checkOtherFields(element, fields);
    _checkEquality(element, fields);
    _checkOptions(element, fields);

    return ClassModel(
      name: selfName,
      baseName: name,
      constructor: constructor.name == 'new'
          ? selfName
          : '$selfName.${constructor.name}',
      owner: owner,
      omit: _omitOf(element),
      fields: fields,
      typeParameters: _typeParametersOf(element),
      isImmutable: _isImmutable(element),
      familyTag: _familyTagOf(element),
      handWritten: _handWrittenOf(element),
    );
  }

  bool _isImmutable(ClassElement element) {
    return element.metadata.hasImmutable ||
        element.allSupertypes.any((type) => type.element.metadata.hasImmutable);
  }

  void _checkEquality(ClassElement element, List<FieldModel> fields) {
    final name = element.name!;
    for (final owner in [element, ..._superclassesOf(element)]) {
      if (_defines(owner, '==') != _defines(owner, 'hashCode')) {
        _addError(
          '${owner.name} must define both == and hashCode, or neither.',
        );
      }
    }

    final isImmutable = _isImmutable(element);
    for (final field in fields) {
      final label = '$name.${field.name}';
      _checkSets(label, field);
      if (isImmutable && field.type.mutableClass != null) {
        errors.add(
          '$label holds a ${field.type.mutableClass}, which is not @immutable, '
          'so $name cannot be either.',
        );
      }
    }
  }

  void _checkSets(String label, FieldModel field) {
    if (field.type.hasSetWithoutValues) {
      errors.add(
        '$label has a Set of values that do not compare by value, so it '
        'could never compare by content: use a List, or a @immutable class.',
      );
    }
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

    final adaptedElement = adapted.element;
    if (adaptedElement is ClassElement && _isCovered(adaptedElement)) {
      _addError(
        '$label is for $adapted, which already is a @Charcoal class.',
      );
      return null;
    }

    final wire = adapter.wire.nullabilitySuffix == NullabilitySuffix.none
        ? _primitiveOf(adapter.wire)
        : null;
    final isWireAllowed =
        wire is PrimitiveFieldType && wire.primitive != DartPrimitive.num;
    if (!isWireAllowed) {
      _addError(
        '$label writes a ${adapter.wire}, '
        'but it can only write an int, a double, a String or a bool.',
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
    ConstructorElement constructor, {
    required String label,
  }) async {
    final fields = <FieldModel>[];
    for (final parameter in constructor.formalParameters) {
      final parameterName = parameter.name!;
      final fieldLabel = '$label.$parameterName';
      if (!_readsItsOwnField(parameter)) {
        errors.add(
          '$fieldLabel must be a `this.$parameterName` or '
          '`super.$parameterName` parameter.',
        );
        continue;
      }

      final type = _fieldTypeOf(parameter.type, _library);
      if (type == null) {
        errors.add(
          '$fieldLabel is a ${parameter.type}, which charcoal cannot serialize.'
          ' If it has a CharcoalAdapter, this library needs to import it.',
        );
        continue;
      }
      final defaultValue = parameter.computeConstantValue();
      final field = FieldModel(
        name: parameterName,
        type: type,
        isNamedParameter: parameter.isNamed,
        defaultValue: await _defaultSourceOf(parameter, element),
        isDefaultNull: defaultValue?.isNull ?? false,
        isDefaultEmpty: defaultValue != null && _isEmpty(defaultValue),
      );
      _checkOmit(fieldLabel, field, _omitOf(element));
      fields.add(field);
    }
    return fields;
  }

  /// Whether it ends up in a field of its own name, through any `super.x`.
  bool _readsItsOwnField(FormalParameterElement parameter) {
    FormalParameterElement? current = parameter;
    while (current is SuperFormalParameterElement) {
      current = current.superConstructorParameter;
    }
    return current is FieldFormalParameterElement &&
        current.name == parameter.name;
  }

  /// Whatever gets dropped has to decode back to exactly what it was.
  void _checkOmit(String label, FieldModel field, Omit omit) {
    final type = field.type;
    final hasNonNullDefault =
        field.defaultValue != null && !field.isDefaultNull;
    if (type is NullableFieldType && hasNonNullDefault && omit != Omit.none) {
      errors.add(
        '$label defaults to a value that is not null, so a dropped null '
        'could not come back: use Omit.none or remove the default.',
      );
    }
    if (omit == Omit.empty && type.canBeEmpty && !field.isDefaultEmpty) {
      errors.add(
        '$label can be dropped by Omit.empty, so a missing key has to decode '
        'to it: give it a default of zero or empty.',
      );
    }
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
    if (expression != null) {
      return DefaultValueSource.of(expression, owner);
    }
    if (parameter case SuperFormalParameterElement(
      :final superConstructorParameter?,
    )) {
      final superclass = owner.supertype?.element;
      if (superclass is ClassElement) {
        return await _defaultSourceOf(superConstructorParameter, superclass);
      }
    }
    return parameter.defaultValueCode;
  }

  bool _isEmpty(DartObject value) {
    return value.toIntValue() == 0 ||
        value.toDoubleValue() == 0 ||
        (value.toListValue()?.isEmpty ?? false) ||
        (value.toSetValue()?.isEmpty ?? false) ||
        (value.toMapValue()?.isEmpty ?? false);
  }

  void _checkOtherFields(ClassElement element, List<FieldModel> fields) {
    final parameters = _wireConstructor(element)!.formalParameters
        .map((parameter) => parameter.name)
        .toSet();
    for (final owner in [element, ..._superclassesOf(element)]) {
      _checkFieldsOf(owner, element, parameters);
      for (final mixin in owner.mixins) {
        _checkFieldsOf(mixin.element, element, parameters);
      }
    }
  }

  void _checkFieldsOf(
    InterfaceElement owner,
    ClassElement element,
    Set<String?> parameters,
  ) {
    for (final field in owner.fields) {
      final isSkipped =
          field.isStatic || field.isLate || field.isOriginGetterSetter;
      if (!isSkipped && !parameters.contains(field.name)) {
        errors.add(
          '${owner.name}.${field.name} is not a constructor parameter of '
          '${element.name}, so a round trip would lose it.',
        );
      }
    }
  }

  FieldType? _fieldTypeOf(DartType type, LibraryElement library) {
    final inner =
        _adapterOf(type, library) ??
        _typeParameterOf(type) ??
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

  /// Null unless the class being read declares it.
  FieldType? _typeParameterOf(DartType type) {
    return type is TypeParameterType && _typeParameters.contains(type.element)
        ? TypeParameterFieldType(type.element.name!)
        : null;
  }

  /// Null unless generated code can name it and its representation.
  FieldType? _extensionOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! ExtensionTypeElement ||
        type is! InterfaceType ||
        !_isNameable(type, library)) {
      return null;
    }

    final representation = _fieldTypeOf(element.representation.type, library);
    if (representation == null) {
      return null;
    }
    final name = element.name!;
    final arguments = type.typeArguments
        .map((argument) => argument.getDisplayString())
        .join(', ');
    return ExtensionFieldType(
      arguments.isEmpty ? name : '$name<$arguments>',
      representation,
    );
  }

  bool _isNameable(DartType type, LibraryElement library) {
    if (type is TypeParameterType) {
      return _typeParameters.contains(type.element);
    }
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
    final isSet = type.asInstanceOf(library.typeProvider.setElement) != null;
    if (type.isDartCoreList) {
      return IterableFieldType(element, IterableKind.list, isSet: false);
    }
    if (type.isDartCoreSet) {
      return IterableFieldType(element, IterableKind.set, isSet: true);
    }
    if (type.isDartCoreIterable) {
      return IterableFieldType(element, IterableKind.other, isSet: false);
    }
    final ofClass = _ofClassOf(type, 1, library);
    return ofClass == null
        ? null
        : IterableFieldType(
            element,
            IterableKind.other,
            isSet: isSet,
            ofClass: ofClass,
          );
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
    final extension = _extensionOf(type, library);
    if (extension is ExtensionFieldType) {
      final representation = extension.representation;
      return representation is PrimitiveFieldType &&
              _isPrimitiveKey(representation)
          ? extension
          : null;
    }
    final primitive = _primitiveOf(type);
    if (primitive is PrimitiveFieldType) {
      return _isPrimitiveKey(primitive) ? primitive : null;
    }
    return _enumOf(type, library);
  }

  bool _isPrimitiveKey(PrimitiveFieldType type) {
    return type.primitive == DartPrimitive.string ||
        type.primitive == DartPrimitive.int;
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

  /// Null if generated code could not name it.
  FieldType? _enumOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! EnumElement) {
      return null;
    }
    return _isVisible(element, library) ? EnumFieldType(element.name!) : null;
  }

  /// Null unless it has generated code that can decode a concrete instance.
  FieldType? _classOf(DartType type, LibraryElement library) {
    final element = type.element;
    if (element is! ClassElement ||
        type is! InterfaceType ||
        !_isCovered(element) ||
        (element.isAbstract && !element.isSealed) ||
        !_isVisible(element, library)) {
      return null;
    }
    if (element.typeParameters.isNotEmpty) {
      return _genericClassOf(type, element, library);
    }
    final name = element.name!;
    final isImmutable = _isImmutable(element);
    return ClassFieldType(
      name,
      owner: '${name}Charcoal',
      isImmutable: isImmutable,
      mutableClass: isImmutable ? null : name,
    );
  }

  /// A use of a generic class, read later as it could well hold itself.
  FieldType? _genericClassOf(
    InterfaceType type,
    ClassElement element,
    LibraryElement library,
  ) {
    final name = element.name!;
    final written = type.typeArguments
        .map((argument) => argument.getDisplayString())
        .join(', ');
    final typeName = '$name<$written>';
    final isClassImmutable = _isImmutable(element);

    if (type.typeArguments.any(_mentionsTypeParameter)) {
      return type.typeArguments.every((e) => _isNameable(e, library))
          ? ClassFieldType(
              typeName,
              owner: '${name}Charcoal',
              isImmutable: isClassImmutable,
              mutableClass: isClassImmutable ? null : typeName,
            )
          : null;
    }

    final known = _instantiations[typeName];
    if (known != null) {
      return known;
    }
    final arguments = type.typeArguments
        .map((argument) => _fieldTypeOf(argument, library))
        .toList();
    if (arguments.contains(null)) {
      return null;
    }
    final growing = _growingTypeIn(element);
    if (growing != null) {
      _addError(
        '$name cannot be generated for each use, as it needs a $growing, '
        'whose type arguments would grow forever.',
      );
      return null;
    }

    final held = arguments.nonNulls;
    final field = ClassFieldType(
      typeName,
      owner: '_\$$name${_instantiations.length}',
      isImmutable: isClassImmutable && held.every((e) => e.isValue),
      mutableClass: isClassImmutable
          ? held.map((e) => e.mutableClass).nonNulls.firstOrNull
          : typeName,
    );
    _instantiations[typeName] = field;
    _pending.add((type, field));
    return field;
  }

  String? _growingTypeIn(ClassElement element) {
    final graph = InstantiationGraph(
      (other) => _isCovered(other) && other.typeParameters.isNotEmpty,
      (other) => other.isSealed
          ? const []
          : _wireConstructor(other)?.formalParameters.map((e) => e.type) ??
                const [],
      (other) => other.isSealed ? _leavesOf(other) : const [],
    );
    return graph.growingTypeIn(element);
  }

  bool _mentionsTypeParameter(DartType type) {
    return type is TypeParameterType ||
        (type is InterfaceType &&
            type.typeArguments.any(_mentionsTypeParameter));
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
