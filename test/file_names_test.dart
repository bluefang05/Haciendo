import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/core/utils/file_names.dart';

void main() {
  test('safeFileName removes Android-hostile characters', () {
    expect(safeFileName('Mesa: antes/después?'), 'Mesa_antes_después_');
  });
}
