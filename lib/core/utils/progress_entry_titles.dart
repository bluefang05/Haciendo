import '../../data/models/progress_entry.dart';

String automaticStepTitle(int zeroBasedIndex) => 'Paso ${zeroBasedIndex + 1}';

String progressEntryTitle(ProgressEntry entry, int zeroBasedIndex) {
  final title = entry.title.trim();
  return title.isEmpty ? automaticStepTitle(zeroBasedIndex) : title;
}
