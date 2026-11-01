import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// The source of a parameter's default, valid outside of the class.
///
/// A default can name static members of its class directly, but generated code
/// lives in a mixin, so those get qualified with the name of the class.
abstract final class DefaultValueSource() {
  static String of(Expression expression, ClassElement owner) {
    final finder = _OwnMemberFinder(owner);
    expression.accept(finder);

    final out = StringBuffer();
    Token? previous;
    var token = expression.beginToken;
    while (true) {
      if (previous != null && token.offset > previous.end) {
        out.write(' ');
      }
      if (finder.tokens.contains(token)) {
        final qualified = '${owner.name}.${token.lexeme}';
        final isInterpolated =
            previous?.type == TokenType.STRING_INTERPOLATION_IDENTIFIER;
        out.write(isInterpolated ? '{$qualified}' : qualified);
      } else {
        out.write(token.lexeme);
      }
      if (token == expression.endToken) {
        return out.toString();
      }
      previous = token;
      token = token.next!;
    }
  }
}

final class _OwnMemberFinder(this._owner) extends RecursiveAstVisitor<void> {
  final ClassElement _owner;
  final Set<Token> tokens = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    final isAfterDot =
        (parent is PrefixedIdentifier && parent.identifier == node) ||
        (parent is PropertyAccess && parent.propertyName == node);
    if (!isAfterDot && node.element?.enclosingElement == _owner) {
      tokens.add(node.token);
    }
  }
}
