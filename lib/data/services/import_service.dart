import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/photo_item.dart';
import '../models/progress_entry.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import 'file_storage_service.dart';
import 'reminder_service.dart';

enum BackupImportMode { copy, replace }

class ImportService {
  ImportService({
    ProjectRepository? repository,
    FileStorageService? storage,
  })  : _repository = repository ?? ProjectRepository(),
        _storage = storage ?? FileStorageService();

  final ProjectRepository _repository;
  final FileStorageService _storage;
  final Uuid _uuid = const Uuid();

  static const int maxArchiveFiles = 1200;
  static const int maxArchiveBytes = 1024 * 1024 * 1024;
  static const int maxEntryBytes = 100 * 1024 * 1024;
  static const int maxManifestBytes = 2 * 1024 * 1024;

  Future<Project> importBackup(
    String zipPath, {
    BackupImportMode mode = BackupImportMode.copy,
  }) async {
    await _storage.initialize();
    final extraction = Directory(
      await _storage.createExportPath(
        'import_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await extraction.create(recursive: true);

    try {
      final decoded = await _validateAndExtract(zipPath, extraction);

      final oldProject = Map<String, dynamic>.from(
        decoded['project'] as Map? ?? const <String, dynamic>{},
      );
      final originalProjectId = oldProject['id'] as String?;
      if (originalProjectId == null || originalProjectId.isEmpty) {
        throw const FormatException(
            'El respaldo no contiene un proyecto válido.');
      }

      final replacing = mode == BackupImportMode.replace;
      final targetProjectId = replacing ? originalProjectId : _uuid.v4();
      final importProjectId = replacing ? _uuid.v4() : targetProjectId;

      final now = DateTime.now();
      final restoredPinHash =
          replacing ? oldProject['pinHash'] as String? : null;
      var project = Project(
        id: targetProjectId,
        name: replacing
            ? (oldProject['name'] as String? ?? 'Proyecto')
            : '${oldProject['name'] ?? 'Proyecto'} (copia)',
        description: oldProject['description'] as String? ?? '',
        status: _enumOr(
          ProjectStatus.values,
          oldProject['status'] as String?,
          ProjectStatus.idea,
        ),
        type: _enumOr(
          ProjectType.values,
          oldProject['type'] as String?,
          ProjectType.standard,
        ),
        createdAt: replacing
            ? DateTime.tryParse(oldProject['createdAt'] as String? ?? '') ?? now
            : now,
        updatedAt: now,
        isFavorite: oldProject['isFavorite'] as bool? ?? false,
        pinHash: restoredPinHash,
        reminderEnabled: false,
      );

      final entryMap = <String, String>{};
      final importedEntries = <ProgressEntry>[];
      final entries = decoded['entries'] as List<dynamic>? ?? const [];
      for (final value in entries) {
        if (value is! Map) continue;
        final raw = Map<String, dynamic>.from(value);
        final oldEntryId = raw['id'] as String?;
        if (oldEntryId == null) continue;
        final newId = replacing ? oldEntryId : _uuid.v4();
        entryMap[oldEntryId] = newId;
        final entry = ProgressEntry(
          id: newId,
          projectId: targetProjectId,
          title: raw['title'] as String? ?? '',
          description: raw['description'] as String? ?? '',
          materials: raw['materials'] as String? ?? '',
          createdAt: replacing
              ? DateTime.tryParse(raw['createdAt'] as String? ?? '') ?? now
              : now,
          takenAt: DateTime.tryParse(raw['takenAt'] as String? ?? '') ?? now,
          sortOrder: raw['sortOrder'] as int? ?? 0,
          isPrivate: raw['isPrivate'] as bool? ?? false,
          isMilestone: raw['isMilestone'] as bool? ?? false,
          isSequence: raw['isSequence'] as bool? ?? false,
        );
        importedEntries.add(entry);
      }

      String? coverPhotoId;
      final importedPhotos = <PhotoItem>[];
      final photos = decoded['photos'] as List<dynamic>? ?? const [];
      for (final value in photos) {
        if (value is! Map) continue;
        final raw = Map<String, dynamic>.from(value);
        final oldEntryId = raw['entryId'] as String?;
        final newEntryId = oldEntryId == null ? null : entryMap[oldEntryId];
        final relative = raw['file'] as String?;
        if (newEntryId == null || relative == null) continue;

        final source = File(p.normalize(p.join(extraction.path, relative)));
        if (!p.isWithin(extraction.path, source.path) ||
            !await source.exists()) {
          continue;
        }
        final photo = await _storage.importPhoto(
          sourcePath: source.path,
          projectId: importProjectId,
          entryId: newEntryId,
          sortOrder: raw['sortOrder'] as int? ?? 0,
          preference: StoragePreference.original,
          isSequenceFrame: raw['isSequenceFrame'] as bool? ?? false,
        );
        importedPhotos.add(photo);
        coverPhotoId ??= photo.id;
      }

      project = coverPhotoId == null
          ? project
          : project.copyWith(
              coverPhotoId: coverPhotoId,
              updatedAt: DateTime.now(),
            );
      if (replacing) {
        await _replaceExistingProject(
          targetProjectId: targetProjectId,
          stagedProjectId: importProjectId,
          project: project,
          entries: importedEntries,
          photos: importedPhotos,
        );
      } else {
        await _repository.replaceProjectData(
          project: project,
          entries: importedEntries,
          photos: importedPhotos,
        );
      }
      return project;
    } finally {
      if (await extraction.exists()) {
        await extraction.delete(recursive: true);
      }
    }
  }

  T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> _validateAndExtract(
    String zipPath,
    Directory extraction,
  ) async {
    final archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
    if (archive.files.length > maxArchiveFiles) {
      throw const FormatException('El respaldo contiene demasiados archivos.');
    }

    ArchiveFile? manifest;
    var totalBytes = 0;
    for (final file in archive.files) {
      final name = _safeArchiveName(file.name);
      if (name == null) {
        throw const FormatException('El respaldo contiene rutas no validas.');
      }
      if (file.isSymbolicLink) {
        throw const FormatException('El respaldo contiene enlaces no validos.');
      }
      if (file.isFile) {
        if (file.size > maxEntryBytes) {
          throw const FormatException(
              'El respaldo contiene un archivo demasiado grande.');
        }
        totalBytes += file.size;
        if (totalBytes > maxArchiveBytes) {
          throw const FormatException('El respaldo es demasiado grande.');
        }
        if (name == 'backup.json') {
          manifest = file;
        } else if (!name.startsWith('images/')) {
          throw const FormatException(
              'El respaldo contiene archivos inesperados.');
        }
      }
    }

    if (manifest == null) {
      throw const FormatException('El ZIP no contiene backup.json.');
    }
    if (manifest.size > maxManifestBytes) {
      throw const FormatException(
          'El manifiesto del respaldo es demasiado grande.');
    }
    final manifestBytes = manifest.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('No se pudo leer backup.json.');
    }
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    const supportedFormats = {
      'com.enmanuelapps.haciendo.backup',
      'com.enmanuelapp.haciendo.backup',
    };
    if (decoded is! Map<String, dynamic> ||
        !supportedFormats.contains(decoded['format'])) {
      throw const FormatException(
          'Este archivo no es un respaldo de Haciendo.');
    }

    final project = decoded['project'];
    final entries = decoded['entries'];
    final photos = decoded['photos'];
    if (project is! Map || entries is! List || photos is! List) {
      throw const FormatException('El respaldo esta incompleto.');
    }

    final imageNames = archive.files
        .where((file) => file.isFile)
        .map((file) => _safeArchiveName(file.name))
        .whereType<String>()
        .where((name) => name.startsWith('images/'))
        .toSet();
    for (final value in photos) {
      if (value is! Map) continue;
      final relative = value['file'] as String?;
      final safe = relative == null ? null : _safeArchiveName(relative);
      if (safe == null ||
          !safe.startsWith('images/') ||
          !imageNames.contains(safe)) {
        throw const FormatException('El respaldo referencia fotos no validas.');
      }
    }

    for (final file in archive.files) {
      if (!file.isFile || file == manifest) continue;
      final name = _safeArchiveName(file.name)!;
      final target = File(p.joinAll([extraction.path, ...name.split('/')]));
      if (!p.isWithin(extraction.path, target.path)) {
        throw const FormatException('El respaldo contiene rutas no validas.');
      }
      await target.parent.create(recursive: true);
      final bytes = file.readBytes();
      if (bytes == null) {
        throw const FormatException(
            'No se pudo extraer una imagen del respaldo.');
      }
      await target.writeAsBytes(bytes, flush: true);
    }
    return decoded;
  }

  String? _safeArchiveName(String name) {
    final normalized = p.posix.normalize(name.replaceAll('\\', '/'));
    if (normalized == '.' ||
        normalized.startsWith('../') ||
        normalized.contains('/../') ||
        p.posix.isAbsolute(normalized)) {
      return null;
    }
    return normalized;
  }

  Future<void> _replaceExistingProject({
    required String targetProjectId,
    required String stagedProjectId,
    required Project project,
    required List<ProgressEntry> entries,
    required List<PhotoItem> photos,
  }) async {
    final existing = await _repository.getProject(targetProjectId);
    final targetDirectory =
        Directory(_storage.projectDirectory(targetProjectId));
    final stagedDirectory =
        Directory(_storage.projectDirectory(stagedProjectId));
    final backupDirectory = Directory(
      '${targetDirectory.path}_replace_${DateTime.now().microsecondsSinceEpoch}',
    );
    var movedExisting = false;
    var movedStaged = false;

    final finalPhotos = photos
        .map(
          (photo) => photo.copyWith(
            projectId: targetProjectId,
            originalPath: photo.originalPath.replaceFirst(
              stagedDirectory.path,
              targetDirectory.path,
            ),
            displayPath: photo.displayPath.replaceFirst(
              stagedDirectory.path,
              targetDirectory.path,
            ),
            thumbnailPath: photo.thumbnailPath.replaceFirst(
              stagedDirectory.path,
              targetDirectory.path,
            ),
          ),
        )
        .toList();

    try {
      if (await targetDirectory.exists()) {
        await targetDirectory.rename(backupDirectory.path);
        movedExisting = true;
      }
      if (await stagedDirectory.exists()) {
        await stagedDirectory.rename(targetDirectory.path);
        movedStaged = true;
      }
      if (existing != null) {
        await ReminderService.instance
            .cancel(existing.id.hashCode & 0x7fffffff);
      }
      await _repository.replaceProjectData(
        project: project,
        entries: entries,
        photos: finalPhotos,
      );
      if (await backupDirectory.exists()) {
        await backupDirectory.delete(recursive: true);
      }
    } catch (_) {
      if (movedStaged && await targetDirectory.exists()) {
        await targetDirectory.rename(stagedDirectory.path);
      }
      if (movedExisting && await backupDirectory.exists()) {
        await backupDirectory.rename(targetDirectory.path);
      }
      rethrow;
    }
  }
}
