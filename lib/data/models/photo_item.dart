class PhotoItem {
  const PhotoItem({
    required this.id,
    required this.entryId,
    required this.projectId,
    required this.originalPath,
    required this.displayPath,
    required this.thumbnailPath,
    required this.sortOrder,
    required this.createdAt,
    this.isSequenceFrame = false,
  });

  final String id;
  final String entryId;
  final String projectId;
  final String originalPath;
  final String displayPath;
  final String thumbnailPath;
  final int sortOrder;
  final DateTime createdAt;
  final bool isSequenceFrame;

  PhotoItem copyWith({
    String? entryId,
    String? projectId,
    String? originalPath,
    String? displayPath,
    String? thumbnailPath,
    int? sortOrder,
  }) =>
      PhotoItem(
        id: id,
        entryId: entryId ?? this.entryId,
        projectId: projectId ?? this.projectId,
        originalPath: originalPath ?? this.originalPath,
        displayPath: displayPath ?? this.displayPath,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        isSequenceFrame: isSequenceFrame,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'entry_id': entryId,
        'project_id': projectId,
        'original_path': originalPath,
        'display_path': displayPath,
        'thumbnail_path': thumbnailPath,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'is_sequence_frame': isSequenceFrame ? 1 : 0,
      };

  factory PhotoItem.fromMap(Map<String, Object?> map) => PhotoItem(
        id: map['id']! as String,
        entryId: map['entry_id']! as String,
        projectId: map['project_id']! as String,
        originalPath: map['original_path']! as String,
        displayPath: map['display_path']! as String,
        thumbnailPath: map['thumbnail_path']! as String,
        sortOrder: map['sort_order']! as int,
        createdAt: DateTime.parse(map['created_at']! as String),
        isSequenceFrame: (map['is_sequence_frame'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toJson({required String fileName}) => {
        'id': id,
        'entryId': entryId,
        'projectId': projectId,
        'file': fileName,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'isSequenceFrame': isSequenceFrame,
      };
}
