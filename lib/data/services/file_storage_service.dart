import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/photo_item.dart';
import 'image_processing_service.dart';
import 'platform_service.dart';

class FileStorageService {
  FileStorageService({
    PlatformService? platformService,
    ImageProcessingService? imageProcessingService,
  })  : _platformService = platformService ?? PlatformService.instance,
        _imageProcessingService =
            imageProcessingService ?? const ImageProcessingService();

  final PlatformService _platformService;
  final ImageProcessingService _imageProcessingService;
  final Uuid _uuid = const Uuid();

  String? _filesPath;
  String? _cachePath;

  Future<void> initialize() async {
    if (_filesPath != null) return;
    final directories = await _platformService.getAppDirectories();
    _filesPath = directories['files'];
    _cachePath = directories['cache'];
    await Directory(projectsRoot).create(recursive: true);
    await Directory(exportsRoot).create(recursive: true);
  }

  String get projectsRoot => p.join(_filesPath!, 'projects');
  String get exportsRoot => p.join(_cachePath!, 'exports');

  String projectDirectory(String projectId) => p.join(projectsRoot, projectId);
  String projectImagesDirectory(String projectId) =>
      p.join(projectDirectory(projectId), 'images');

  Future<PhotoItem> importPhoto({
    required String sourcePath,
    required String projectId,
    required String entryId,
    required int sortOrder,
    required StoragePreference preference,
    bool isSequenceFrame = false,
  }) async {
    await initialize();
    final id = _uuid.v4();
    final imageDirectory = Directory(projectImagesDirectory(projectId));
    await imageDirectory.create(recursive: true);

    final extension = p.extension(sourcePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final originalPath =
        p.join(imageDirectory.path, '${id}_original$safeExtension');
    final displayPath = p.join(imageDirectory.path, '${id}_display.jpg');
    final thumbnailPath = p.join(imageDirectory.path, '${id}_thumb.jpg');

    await File(sourcePath).copy(originalPath);
    final processed = await _imageProcessingService.process(
      originalPath: originalPath,
      displayPath: displayPath,
      thumbnailPath: thumbnailPath,
      preference: preference,
    );

    return PhotoItem(
      id: id,
      entryId: entryId,
      projectId: projectId,
      originalPath: originalPath,
      displayPath: processed.displayPath,
      thumbnailPath: processed.thumbnailPath,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      isSequenceFrame: isSequenceFrame,
    );
  }

  Future<PhotoItem> duplicatePhoto({
    required PhotoItem source,
    required String newId,
    required int sortOrder,
  }) async {
    await initialize();
    final imageDirectory = Directory(projectImagesDirectory(source.projectId));
    await imageDirectory.create(recursive: true);
    final originalPath = p.join(imageDirectory.path,
        '${newId}_original${p.extension(source.originalPath)}');
    final displayPath = p.join(imageDirectory.path, '${newId}_display.jpg');
    final thumbnailPath = p.join(imageDirectory.path, '${newId}_thumb.jpg');
    await File(source.originalPath).copy(originalPath);
    await File(source.displayPath).copy(displayPath);
    await File(source.thumbnailPath).copy(thumbnailPath);
    return PhotoItem(
      id: newId,
      entryId: source.entryId,
      projectId: source.projectId,
      originalPath: originalPath,
      displayPath: displayPath,
      thumbnailPath: thumbnailPath,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      isSequenceFrame: source.isSequenceFrame,
    );
  }

  Future<void> deletePhotoFiles(PhotoItem photo) async {
    for (final path in {
      photo.originalPath,
      photo.displayPath,
      photo.thumbnailPath,
    }) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> deleteProjectDirectory(String projectId) async {
    await initialize();
    final directory = Directory(projectDirectory(projectId));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<Directory?> stageProjectDirectoryForDeletion(String projectId) async {
    await initialize();
    final directory = Directory(projectDirectory(projectId));
    if (!await directory.exists()) return null;

    final stagedPath = p.join(
      projectsRoot,
      '${projectId}_deleting_${DateTime.now().microsecondsSinceEpoch}',
    );
    return directory.rename(stagedPath);
  }

  Future<void> restoreStagedProjectDirectory({
    required Directory stagedDirectory,
    required String projectId,
  }) async {
    await initialize();
    if (!await stagedDirectory.exists()) return;
    final directory = Directory(projectDirectory(projectId));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await stagedDirectory.rename(directory.path);
  }

  Future<void> deleteStagedProjectDirectory(Directory? stagedDirectory) async {
    await initialize();
    if (stagedDirectory != null && await stagedDirectory.exists()) {
      await stagedDirectory.delete(recursive: true);
    }
  }

  Future<String> createExportPath(String fileName) async {
    await initialize();
    await Directory(exportsRoot).create(recursive: true);
    return p.join(exportsRoot, fileName);
  }

  Future<void> clearExports() async {
    await initialize();
    final directory = Directory(exportsRoot);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
  }
}
