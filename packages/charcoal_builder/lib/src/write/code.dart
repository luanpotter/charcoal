/// A template written indented as the code around it: each line loses as many
/// leading spaces as come before the closing `'''`, and the line break before
/// them is left out.
///
/// A line with fewer keeps what it has, as do the later lines of a value it
/// interpolates.
String code(String template) {
  final end = template.lastIndexOf('\n');
  if (end == -1 || template.substring(end).trim().isNotEmpty) {
    throw ArgumentError.value(template, 'template', 'Needs its own last line');
  }
  final margin = template.length - end - 1;
  return template
      .substring(0, end)
      .split('\n')
      .map((line) {
        var cut = 0;
        while (cut < margin &&
            cut < line.length &&
            line.codeUnitAt(cut) == 0x20) {
          cut++;
        }
        return line.substring(cut);
      })
      .join('\n');
}
