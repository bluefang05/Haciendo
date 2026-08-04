class TextLimits {
  const TextLimits._();

  static const title = 80;
  static const description = 1000;
  static const materials = 500;
}

String trimToLimit(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return trimmed.substring(0, maxLength).trimRight();
}
