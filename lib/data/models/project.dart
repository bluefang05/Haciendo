enum ProjectStatus { idea, inProgress, paused, completed, archived }

enum ProjectType { standard, sequence }

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.coverPhotoId,
    this.isFavorite = false,
    this.isDeleted = false,
    this.deletedAt,
    this.pinHash,
    this.reminderAt,
    this.reminderEnabled = false,
  });

  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final ProjectType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverPhotoId;
  final bool isFavorite;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? pinHash;
  final DateTime? reminderAt;
  final bool reminderEnabled;

  bool get isProtected => pinHash != null && pinHash!.isNotEmpty;

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectType? type,
    DateTime? updatedAt,
    String? coverPhotoId,
    bool clearCoverPhoto = false,
    bool? isFavorite,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? pinHash,
    bool clearPinHash = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    bool? reminderEnabled,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverPhotoId: clearCoverPhoto ? null : (coverPhotoId ?? this.coverPhotoId),
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status.name,
        'type': type.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'cover_photo_id': coverPhotoId,
        'is_favorite': isFavorite ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
        'pin_hash': pinHash,
        'reminder_at': reminderAt?.toIso8601String(),
        'reminder_enabled': reminderEnabled ? 1 : 0,
      };

  factory Project.fromMap(Map<String, Object?> map) => Project(
        id: map['id']! as String,
        name: map['name']! as String,
        description: (map['description'] as String?) ?? '',
        status: ProjectStatus.values.byName((map['status'] as String?) ?? 'idea'),
        type: ProjectType.values.byName((map['type'] as String?) ?? 'standard'),
        createdAt: DateTime.parse(map['created_at']! as String),
        updatedAt: DateTime.parse(map['updated_at']! as String),
        coverPhotoId: map['cover_photo_id'] as String?,
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
        deletedAt: map['deleted_at'] == null
            ? null
            : DateTime.parse(map['deleted_at']! as String),
        pinHash: map['pin_hash'] as String?,
        reminderAt: map['reminder_at'] == null
            ? null
            : DateTime.parse(map['reminder_at']! as String),
        reminderEnabled: (map['reminder_enabled'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status.name,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'coverPhotoId': coverPhotoId,
        'isFavorite': isFavorite,
        'reminderAt': reminderAt?.toIso8601String(),
        'reminderEnabled': reminderEnabled,
      };
}
