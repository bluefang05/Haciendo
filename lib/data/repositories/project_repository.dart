import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/text_limits.dart';
import '../db/app_database.dart';
import '../models/photo_item.dart';
import '../models/progress_entry.dart';
import '../models/project.dart';
import '../models/project_bundle.dart';

class ProjectRepository {
  ProjectRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<Project> createProject({
    required String name,
    String description = '',
    ProjectType type = ProjectType.standard,
  }) async {
    final now = DateTime.now();
    final project = Project(
      id: _uuid.v4(),
      name: trimToLimit(name, TextLimits.title),
      description: trimToLimit(description, TextLimits.description),
      status: ProjectStatus.idea,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _database.database;
    await db.insert('projects', project.toMap());
    return project;
  }

  Future<void> upsertProject(Project project) async {
    final db = await _database.database;
    final sanitized = project.copyWith(
      name: trimToLimit(project.name, TextLimits.title),
      description: trimToLimit(project.description, TextLimits.description),
    );
    await db.insert(
      'projects',
      sanitized.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Project?> getProject(String id) async {
    final db = await _database.database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Project.fromMap(rows.first);
  }

  Future<List<Project>> getProjects({
    required int limit,
    required int offset,
    bool deleted = false,
    String? query,
  }) async {
    final db = await _database.database;
    final where = <String>['is_deleted = ?'];
    final args = <Object?>[deleted ? 1 : 0];
    if (query != null && query.trim().isNotEmpty) {
      where.add('(name LIKE ? OR description LIKE ?)');
      final value = '%${query.trim()}%';
      args.addAll([value, value]);
    }
    final rows = await db.query(
      'projects',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'is_favorite DESC, updated_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Project.fromMap).toList();
  }

  Future<void> moveProjectToTrash(Project project) async {
    await upsertProject(project.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> restoreProject(Project project) async {
    await upsertProject(project.copyWith(
      isDeleted: false,
      clearDeletedAt: true,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteProjectPermanently(String projectId) async {
    final db = await _database.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);
  }

  Future<void> replaceProjectData({
    required Project project,
    required List<ProgressEntry> entries,
    required List<PhotoItem> photos,
  }) async {
    final db = await _database.database;
    final sanitizedProject = project.copyWith(
      name: trimToLimit(project.name, TextLimits.title),
      description: trimToLimit(project.description, TextLimits.description),
    );
    await db.transaction((txn) async {
      await txn.delete('projects', where: 'id = ?', whereArgs: [project.id]);
      await txn.insert('projects', sanitizedProject.toMap());
      for (final entry in entries) {
        final sanitizedEntry = entry.copyWith(
          title: trimToLimit(entry.title, TextLimits.title),
          description: trimToLimit(entry.description, TextLimits.description),
          materials: trimToLimit(entry.materials, TextLimits.materials),
        );
        await txn.insert('entries', sanitizedEntry.toMap());
      }
      for (final photo in photos) {
        await txn.insert('photos', photo.toMap());
      }
    });
  }

  Future<ProgressEntry> createEntry({
    required String projectId,
    String title = '',
    String description = '',
    String materials = '',
    DateTime? takenAt,
    bool isPrivate = false,
    bool isMilestone = false,
    bool isSequence = false,
  }) async {
    final db = await _database.database;
    final maxRows = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM entries WHERE project_id = ?',
      [projectId],
    );
    final nextOrder = ((maxRows.first['max_order'] as int?) ?? -1) + 1;
    final now = DateTime.now();
    final entry = ProgressEntry(
      id: _uuid.v4(),
      projectId: projectId,
      title: trimToLimit(title, TextLimits.title),
      description: trimToLimit(description, TextLimits.description),
      materials: trimToLimit(materials, TextLimits.materials),
      createdAt: now,
      takenAt: takenAt ?? now,
      sortOrder: nextOrder,
      isPrivate: isPrivate,
      isMilestone: isMilestone,
      isSequence: isSequence,
    );
    await db.transaction((txn) async {
      await txn.insert('entries', entry.toMap());
      await txn.update(
        'projects',
        {'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
    return entry;
  }

  Future<ProgressEntry> createEntryWithPhotos({
    required ProgressEntry entry,
    required List<PhotoItem> photos,
  }) async {
    final db = await _database.database;
    final now = DateTime.now();
    final maxRows = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM entries WHERE project_id = ?',
      [entry.projectId],
    );
    final nextOrder = ((maxRows.first['max_order'] as int?) ?? -1) + 1;
    final sanitized = entry.copyWith(
      title: trimToLimit(entry.title, TextLimits.title),
      description: trimToLimit(entry.description, TextLimits.description),
      materials: trimToLimit(entry.materials, TextLimits.materials),
      sortOrder: nextOrder,
    );
    await db.transaction((txn) async {
      await txn.insert('entries', sanitized.toMap());
      for (final photo in photos) {
        await txn.insert('photos', photo.toMap());
      }
      await txn.update(
        'projects',
        {
          'updated_at': now.toIso8601String(),
          if (photos.isNotEmpty) 'cover_photo_id': photos.first.id,
        },
        where: photos.isEmpty ? 'id = ?' : 'id = ? AND cover_photo_id IS NULL',
        whereArgs: [entry.projectId],
      );
    });
    return sanitized;
  }

  Future<void> upsertEntry(ProgressEntry entry) async {
    final db = await _database.database;
    final sanitized = entry.copyWith(
      title: trimToLimit(entry.title, TextLimits.title),
      description: trimToLimit(entry.description, TextLimits.description),
      materials: trimToLimit(entry.materials, TextLimits.materials),
    );
    await db.insert(
      'entries',
      sanitized.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      'projects',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [entry.projectId],
    );
  }

  Future<List<ProgressEntry>> getEntries(
    String projectId, {
    required int limit,
    required int offset,
    bool includePrivate = true,
  }) async {
    final db = await _database.database;
    final where = <String>['project_id = ?', 'is_deleted = 0'];
    final args = <Object?>[projectId];
    if (!includePrivate) where.add('is_private = 0');
    final rows = await db.query(
      'entries',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'sort_order ASC, taken_at ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ProgressEntry.fromMap).toList();
  }

  Future<List<ProgressEntry>> getAllEntries(
    String projectId, {
    bool includePrivate = true,
  }) async {
    final db = await _database.database;
    final where = <String>['project_id = ?', 'is_deleted = 0'];
    final args = <Object?>[projectId];
    if (!includePrivate) where.add('is_private = 0');
    final rows = await db.query(
      'entries',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'sort_order ASC, taken_at ASC',
    );
    return rows.map(ProgressEntry.fromMap).toList();
  }

  Future<void> addPhoto(PhotoItem photo) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert('photos', photo.toMap());
      await txn.update(
        'projects',
        {
          'updated_at': DateTime.now().toIso8601String(),
          'cover_photo_id': photo.id,
        },
        where: 'id = ? AND cover_photo_id IS NULL',
        whereArgs: [photo.projectId],
      );
    });
  }

  Future<List<PhotoItem>> getPhotosForEntry(String entryId) async {
    final db = await _database.database;
    final rows = await db.query(
      'photos',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(PhotoItem.fromMap).toList();
  }

  Future<Map<String, List<PhotoItem>>> getPhotosForEntries(
    List<String> entryIds,
  ) async {
    if (entryIds.isEmpty) return {};
    final db = await _database.database;
    final placeholders = List.filled(entryIds.length, '?').join(',');
    final rows = await db.query(
      'photos',
      where: 'entry_id IN ($placeholders)',
      whereArgs: entryIds,
      orderBy: 'entry_id ASC, sort_order ASC',
    );
    final result = <String, List<PhotoItem>>{};
    for (final row in rows) {
      final photo = PhotoItem.fromMap(row);
      result.putIfAbsent(photo.entryId, () => []).add(photo);
    }
    return result;
  }

  Future<List<PhotoItem>> getPhotosForProject(String projectId) async {
    final db = await _database.database;
    final rows = await db.query(
      'photos',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC, sort_order ASC',
    );
    return rows.map(PhotoItem.fromMap).toList();
  }

  Future<List<PhotoItem>> getProjectPhotosPage(
    String projectId, {
    required int limit,
    required int offset,
    bool includePrivate = true,
  }) async {
    final db = await _database.database;
    final privateClause = includePrivate ? '' : 'AND entries.is_private = 0';
    final rows = await db.rawQuery(
      '''
      SELECT photos.*
      FROM photos
      INNER JOIN entries ON entries.id = photos.entry_id
      WHERE photos.project_id = ?
        AND entries.is_deleted = 0
        $privateClause
      ORDER BY entries.sort_order ASC, photos.sort_order ASC, photos.created_at ASC
      LIMIT ? OFFSET ?
      ''',
      [projectId, limit, offset],
    );
    return rows.map(PhotoItem.fromMap).toList();
  }

  Future<int> getProjectPhotoCount(
    String projectId, {
    bool includePrivate = true,
  }) async {
    final db = await _database.database;
    final privateClause = includePrivate ? '' : 'AND entries.is_private = 0';
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM photos
      INNER JOIN entries ON entries.id = photos.entry_id
      WHERE photos.project_id = ?
        AND entries.is_deleted = 0
        $privateClause
      ''',
      [projectId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<PhotoItem?> getProjectEdgePhoto(
    String projectId, {
    required bool first,
    bool includePrivate = false,
  }) async {
    final db = await _database.database;
    final privateClause = includePrivate ? '' : 'AND entries.is_private = 0';
    final direction = first ? 'ASC' : 'DESC';
    final rows = await db.rawQuery(
      '''
      SELECT photos.*
      FROM photos
      INNER JOIN entries ON entries.id = photos.entry_id
      WHERE photos.project_id = ?
        AND entries.is_deleted = 0
        $privateClause
      ORDER BY entries.sort_order $direction, photos.sort_order $direction, photos.created_at $direction
      LIMIT 1
      ''',
      [projectId],
    );
    return rows.isEmpty ? null : PhotoItem.fromMap(rows.first);
  }

  Future<ProjectBundle?> getPresentationPage(
    String projectId, {
    required int limit,
    required int offset,
  }) async {
    final project = await getProject(projectId);
    if (project == null) return null;
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT photos.*
      FROM photos
      INNER JOIN entries ON entries.id = photos.entry_id
      WHERE photos.project_id = ?
        AND entries.is_deleted = 0
        AND entries.is_private = 0
      ORDER BY entries.sort_order ASC, photos.sort_order ASC, photos.created_at ASC
      LIMIT ? OFFSET ?
      ''',
      [projectId, limit, offset],
    );
    final photos = rows.map(PhotoItem.fromMap).toList();
    final entriesById = await getEntriesByIds(
      photos.map((photo) => photo.entryId).toSet().toList(),
    );
    return ProjectBundle(
      project: project,
      entries: entriesById.values.toList(),
      photos: photos,
    );
  }

  Future<Map<String, ProgressEntry>> getEntriesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final db = await _database.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'entries',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'sort_order ASC, taken_at ASC',
    );
    return {
      for (final entry in rows.map(ProgressEntry.fromMap)) entry.id: entry,
    };
  }

  Future<PhotoItem?> getPhoto(String photoId) async {
    final db = await _database.database;
    final rows =
        await db.query('photos', where: 'id = ?', whereArgs: [photoId]);
    return rows.isEmpty ? null : PhotoItem.fromMap(rows.first);
  }

  Future<void> deletePhoto(String photoId) async {
    final db = await _database.database;
    await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  Future<void> moveEntryToTrash(ProgressEntry entry) async {
    await upsertEntry(entry.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
    ));
  }

  Future<void> restoreEntry(ProgressEntry entry) async {
    await upsertEntry(entry.copyWith(
      isDeleted: false,
      clearDeletedAt: true,
    ));
  }

  Future<void> reorderPhotos(List<PhotoItem> photos) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var i = 0; i < photos.length; i++) {
        await txn.update(
          'photos',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [photos[i].id],
        );
      }
    });
  }

  Future<ProjectBundle?> getBundle(
    String projectId, {
    bool includePrivate = true,
  }) async {
    final project = await getProject(projectId);
    if (project == null) return null;
    final entries =
        await getAllEntries(projectId, includePrivate: includePrivate);
    final photos = await getPhotosForProject(projectId);
    final allowedEntryIds = entries.map((entry) => entry.id).toSet();
    return ProjectBundle(
      project: project,
      entries: entries,
      photos: photos
          .where((photo) => allowedEntryIds.contains(photo.entryId))
          .toList(),
    );
  }
}
