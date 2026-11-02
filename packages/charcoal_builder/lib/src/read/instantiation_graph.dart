import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

final class const _Edge(this.from, this.to, this.written) {
  final TypeParameterElement from;
  final TypeParameterElement to;

  /// The type this came from, if its argument wraps the type parameter, which
  /// makes each pass through this edge need a longer type argument.
  final String? written;
}

/// Decides if generating each use of a generic class would ever end.
///
/// Each edge is a type parameter passed on to a generic class by a field. Uses
/// keep coming forever exactly if an edge that wraps it is part of a cycle, as
/// in `Nested<T>` holding a `Nested<List<T>>`. Any other cycle runs out of new
/// types, as in `Pair<A, B>` holding a `Pair<B, A>`.
final class InstantiationGraph(
  this._isGeneric,
  this._fieldTypesOf,
  this._leavesOf,
) {
  final bool Function(ClassElement element) _isGeneric;
  final Iterable<DartType> Function(ClassElement element) _fieldTypesOf;
  final Iterable<ClassElement> Function(ClassElement element) _leavesOf;

  final Set<ClassElement> _visited = {};
  final List<_Edge> _edges = [];

  /// The type that keeps growing, among what using [element] needs, if any.
  String? growingTypeIn(ClassElement element) {
    _visit(element);
    for (final edge in _edges) {
      final written = edge.written;
      if (written != null && _reaches(edge.to, edge.from)) {
        return written;
      }
    }
    return null;
  }

  void _visit(ClassElement element) {
    if (!_visited.add(element)) {
      return;
    }
    _fieldTypesOf(element).forEach(_walk);
    for (final leaf in _leavesOf(element)) {
      _addLeafEdges(leaf, element);
      _visit(leaf);
    }
  }

  /// A leaf only takes type arguments from the type parameters it passes up.
  void _addLeafEdges(ClassElement leaf, ClassElement root) {
    final declared = leaf.thisType.asInstanceOf(root)?.typeArguments ?? [];
    for (final (index, argument) in declared.indexed) {
      if (argument is TypeParameterType) {
        final from = root.typeParameters[index];
        _edges.add(_Edge(from, argument.element, null));
      }
    }
  }

  void _walk(DartType type) {
    if (type is! InterfaceType) {
      return;
    }
    final element = type.element;
    if (element is ClassElement && _isGeneric(element)) {
      for (final (index, argument) in type.typeArguments.indexed) {
        final grows = argument is! TypeParameterType;
        for (final from in _typeParametersIn(argument)) {
          final to = element.typeParameters[index];
          _edges.add(_Edge(from, to, grows ? '$type' : null));
        }
      }
      _visit(element);
    }
    type.typeArguments.forEach(_walk);
  }

  Iterable<TypeParameterElement> _typeParametersIn(DartType type) {
    return switch (type) {
      TypeParameterType(:final element) => [element],
      InterfaceType(:final typeArguments) => typeArguments.expand(
        _typeParametersIn,
      ),
      _ => const [],
    };
  }

  bool _reaches(TypeParameterElement from, TypeParameterElement to) {
    final seen = {from};
    final pending = [from];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (current == to) {
        return true;
      }
      for (final edge in _edges) {
        if (edge.from == current && seen.add(edge.to)) {
          pending.add(edge.to);
        }
      }
    }
    return false;
  }
}
