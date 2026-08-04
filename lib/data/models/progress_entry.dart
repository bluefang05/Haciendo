class ProgressEntry {
  const ProgressEntry({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.materials,
    required this.createdAt,
    required this.takenAt,
    required this.sortOrder,
    this.isPrivate = false,
    this.isMilestone = false,
    this.isSequence = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String materials;
  final DateTime createdAt;
  final DateTime takenAt;
  final int sortOrder;
  final bool isPrivate;
  final bool isMilestone;
  final bool isSequence;
  final bool isDeleted;
  final DateTime? deletedAt;

  ProgressEntry copyWith({
    String? title,
    String? description,
    String? materials,
    DateTime? takenAt,
    int? sortOrder,
    bool? isPrivate,
    bool? isMilestone,
    bool? isSequence,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      ProgressEntry(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        description: description ?? this.description,
        materials: materials ?? this.materials,
        createdAt: createdAt,
        takenAt: takenAt ?? this.takenAt,
        sortOrder: sortOrder ?? this.sortOrder,
        isPrivate: isPrivate ?? this.isPrivate,
        isMilestone: isMilestone ?? this.isMilestone,
        isSequence: isSequence ?? this.isSequence,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'description': description,
        'materials': materials,
        'created_at': createdAt.toIso8601String(),
        'taken_at': takenAt.toIso8601String(),
        'sort_order': sortOrder,
        'is_private': isPrivate ? 1 : 0,
        'is_milestone': isMilestone ? 1 : 0,
        'is_sequence': isSequence ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory ProgressEntry.fromMap(Map<String, Object?> map) => ProgressEntry(
        id: map['id']! as String,
        projectId: map['project_id']! as String,
        title: (map['title'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        materials: (map['materials'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at']! as String),
        takenAt: DateTime.parse(map['taken_at']! as String),
        sortOrder: map['sort_order']! as int,
        isPrivate: (map['is_private'] as int? ?? 0) == 1,
        isMilestone: (map['is_milestone'] as int? ?? 0) == 1,
        isSequence: (map['is_sequence'] as int? ?? 0) == 1,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
        deletedAt: map['deleted_at'] == null
            ? null
            : DateTime.parse(map['deleted_at']! as String),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'materials': materials,
        'createdAt': createdAt.toIso8601String(),
        'takenAt': takenAt.toIso8601String(),
        'sortOrder': sortOrder,
        'isPrivate': isPrivate,
        'isMilestone': isMilestone,
        'isSequence': isSequence,
      };
}
