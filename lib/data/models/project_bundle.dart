import 'photo_item.dart';
import 'progress_entry.dart';
import 'project.dart';

class ProjectBundle {
  const ProjectBundle({
    required this.project,
    required this.entries,
    required this.photos,
  });

  final Project project;
  final List<ProgressEntry> entries;
  final List<PhotoItem> photos;
}
