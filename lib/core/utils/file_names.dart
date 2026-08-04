String safeFileName(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return normalized.isEmpty ? 'proyecto' : normalized;
}
