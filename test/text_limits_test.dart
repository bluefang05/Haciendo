import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/core/utils/text_limits.dart';

void main() {
  test('trimToLimit trims whitespace and long text', () {
    expect(trimToLimit('  proceso  ', TextLimits.title), 'proceso');
    expect(trimToLimit('abcdef', 4), 'abcd');
    expect(trimToLimit('abc   ', 4), 'abc');
  });
}
