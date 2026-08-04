import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/data/models/project.dart';

void main() {
  test('Project map round trip preserves API data', () {
    final now = DateTime(2026, 8, 2, 12, 0);
    final project = Project(
      id: 'id',
      name: 'Dibujo',
      description: 'Proceso',
      status: ProjectStatus.inProgress,
      type: ProjectType.standard,
      createdAt: now,
      updatedAt: now,
      isFavorite: true,
    );
    final restored = Project.fromMap(project.toMap());
    expect(restored.id, project.id);
    expect(restored.status, ProjectStatus.inProgress);
    expect(restored.isFavorite, isTrue);
  });
}
