/// Statements, with adjacent literal writes merged into one.
final class Statements() {
  final StringBuffer _code = StringBuffer();
  final StringBuffer _literal = StringBuffer();

  void literal(String text) => _literal.write(text);

  void code(String statement) {
    _flush();
    _code.writeln(statement);
  }

  String finish() {
    _flush();
    return _code.toString();
  }

  void _flush() {
    if (_literal.isNotEmpty) {
      _code.writeln("\$sink.write('$_literal');");
      _literal.clear();
    }
  }
}
