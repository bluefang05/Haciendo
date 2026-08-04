import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/core/utils/progress_entry_titles.dart';
import 'package:haciendo/data/models/progress_entry.dart';

void main() {
  ProgressEntry entryWithTitle(String title) {
    final now = DateTime(2026, 8, 3, 10, 0);
    return ProgressEntry(
      id: 'entry',
      projectId: 'project',
      title: title,
      description: '',
      materials: '',
      createdAt: now,
      takenAt: now,
      sortOrder: 0,
    );
  }

  test('empty progress title uses current step number', () {
    expect(progressEntryTitle(entryWithTitle(''), 1), 'Paso 2');
  });

  test('real progress title is preserved', () {
    expect(
        progressEntryTitle(entryWithTitle('  Base lista  '), 1), 'Base lista');
  });
}
