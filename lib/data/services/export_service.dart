import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/file_names.dart';
import '../../core/utils/progress_entry_titles.dart';
import '../models/photo_item.dart';
import '../models/progress_entry.dart';
import '../models/project_bundle.dart';
import '../repositories/project_repository.dart';
import 'file_storage_service.dart';
import 'platform_service.dart';

enum PdfExportMode { history, tutorial, album, beforeAfter }

enum ProcessShareQuality { original, compressed }

class ExportServiceException implements Exception {
  const ExportServiceException(this.messageKey);

  final String messageKey;
}

class ExportService {
  ExportService({
    ProjectRepository? repository,
    FileStorageService? storage,
    PlatformService? platform,
  })  : _repository = repository ?? ProjectRepository(),
        _storage = storage ?? FileStorageService(),
        _platform = platform ?? PlatformService.instance;

  final ProjectRepository _repository;
  final FileStorageService _storage;
  final PlatformService _platform;

  Future<String> createPdf({
    required String projectId,
    required PdfExportMode mode,
    bool includePrivate = false,
    Map<String, String>? labels,
  }) async {
    final bundle = await _repository.getBundle(
      projectId,
      includePrivate: includePrivate,
    );
    if (bundle == null) throw StateError('Project not found.');
    final pdf = pw.Document(
      title: bundle.project.name,
      author: 'Haciendo - Enmanuel Apps',
      subject: 'Proceso en fotos',
    );

    switch (mode) {
      case PdfExportMode.history:
        await _addHistory(pdf, bundle, labels: labels);
        break;
      case PdfExportMode.tutorial:
        await _addTutorial(pdf, bundle, labels: labels);
        break;
      case PdfExportMode.album:
        await _addAlbum(pdf, bundle, labels: labels);
        break;
      case PdfExportMode.beforeAfter:
        await _addBeforeAfter(pdf, bundle, labels: labels);
        break;
    }

    final suffix = mode.name;
    final path = await _storage.createExportPath(
      'Haciendo_${safeFileName(bundle.project.name)}_$suffix.pdf',
    );
    await File(path).writeAsBytes(await pdf.save(), flush: true);
    return path;
  }

  Future<void> sharePdf({
    required String projectId,
    required PdfExportMode mode,
    bool includePrivate = false,
    Map<String, String>? labels,
  }) async {
    final path = await createPdf(
      projectId: projectId,
      mode: mode,
      includePrivate: includePrivate,
      labels: labels,
    );
    await _platform.shareFiles(
      [path],
      mimeType: 'application/pdf',
      subject: 'Haciendo: proceso en fotos',
    );
  }

  Future<String> createBackup(String projectId) async {
    final bundle = await _repository.getBundle(projectId, includePrivate: true);
    if (bundle == null) throw StateError('Project not found.');

    final path = await _storage.createExportPath(
      'Haciendo_${safeFileName(bundle.project.name)}_respaldo.zip',
    );
    final encoder = ZipFileEncoder();
    encoder.create(path);

    final photoManifest = <Map<String, Object?>>[];
    for (final photo in bundle.photos) {
      final source = File(photo.originalPath);
      if (!await source.exists()) continue;
      final extension = p.extension(photo.originalPath).isEmpty
          ? '.jpg'
          : p.extension(photo.originalPath);
      final name = 'images/${photo.id}$extension';
      await encoder.addFile(source, name);
      photoManifest.add(photo.toJson(fileName: name));
    }

    final manifest = {
      'format': 'com.enmanuelapps.haciendo.backup',
      'schemaVersion': 1,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'project': {
        ...bundle.project.toJson(),
        'pinHash': bundle.project.pinHash,
      },
      'entries': bundle.entries.map((entry) => entry.toJson()).toList(),
      'photos': photoManifest,
    };
    final manifestPath = await _storage.createExportPath('backup.json');
    final manifestFile = File(manifestPath);
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    await encoder.addFile(manifestFile, 'backup.json');
    encoder.close();
    await manifestFile.delete();
    return path;
  }

  Future<void> shareBackup(String projectId) async {
    final path = await createBackup(projectId);
    await _platform.shareFiles(
      [path],
      mimeType: 'application/zip',
      subject: 'Respaldo de Haciendo',
    );
  }

  Future<String> createShareableZip(
    String projectId, {
    Map<String, String>? labels,
  }) async {
    final bundle =
        await _repository.getBundle(projectId, includePrivate: false);
    if (bundle == null) throw StateError('Project not found.');
    final path = await _storage.createExportPath(
      'Haciendo_${safeFileName(bundle.project.name)}_imagenes.zip',
    );
    final encoder = ZipFileEncoder();
    encoder.create(path);
    var index = 1;
    for (final photo in bundle.photos) {
      final file = File(photo.displayPath);
      if (!await file.exists()) continue;
      final name = 'foto_${index.toString().padLeft(4, '0')}.jpg';
      await encoder.addFile(file, name);
      index++;
    }
    final notesFile = File(await _storage.createExportPath('notas.txt'));
    await notesFile.writeAsString(_plainText(bundle, labels: labels),
        flush: true);
    await encoder.addFile(notesFile, 'notas.txt');
    encoder.close();
    await notesFile.delete();
    return path;
  }

  Future<void> shareShareableZip(
    String projectId, {
    Map<String, String>? labels,
  }) async {
    final path = await createShareableZip(projectId, labels: labels);
    await _platform.shareFiles(
      [path],
      mimeType: 'application/zip',
      subject: 'Haciendo: proceso en fotos',
    );
  }

  static const int quickSharePhotoLimit = 24;

  Future<int> shareProcessPhotos(
    String projectId, {
    int limit = quickSharePhotoLimit,
    ProcessShareQuality quality = ProcessShareQuality.original,
  }) async {
    final project = await _repository.getProject(projectId);
    if (project == null) throw StateError('Project not found.');
    final photos = await _repository.getProjectPhotosPage(
      projectId,
      limit: limit,
      offset: 0,
      includePrivate: false,
    );
    final paths = <String>[];
    final baseName = safeFileName(project.name);
    var index = 1;
    for (final photo in photos) {
      final file = File(
        quality == ProcessShareQuality.original
            ? photo.originalPath
            : photo.displayPath,
      );
      if (!await file.exists()) continue;
      final extension = quality == ProcessShareQuality.original
          ? (p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path))
          : '.jpg';
      final sharePath = await _storage.createExportPath(
        '${baseName}_${index.toString().padLeft(4, '0')}$extension',
      );
      if (quality == ProcessShareQuality.compressed) {
        await _createCompressedShareImageCopy(
          sourcePath: file.path,
          targetPath: sharePath,
        );
      } else {
        await file.copy(sharePath);
      }
      paths.add(sharePath);
      index++;
    }
    if (paths.isEmpty) throw const ExportServiceException('noPhotosToShare');
    await _platform.shareFiles(
      paths,
      mimeType: 'image/*',
      subject: 'Haciendo: ${project.name}',
      text: project.description.isEmpty
          ? 'Haciendo: proceso en fotos'
          : project.description,
    );
    return paths.length;
  }

  Future<void> _createCompressedShareImageCopy({
    required String sourcePath,
    required String targetPath,
  }) async {
    await Isolate.run(() {
      final sourceFile = File(sourcePath);
      final bytes = sourceFile.readAsBytesSync();
      final rawDecoded = img.decodeImage(bytes);
      if (rawDecoded == null) {
        sourceFile.copySync(targetPath);
        return;
      }
      final decoded = img.bakeOrientation(rawDecoded);
      const maxSide = 1600;
      final shareImage = decoded.width > maxSide || decoded.height > maxSide
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxSide : null,
              height: decoded.height > decoded.width ? maxSide : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      File(targetPath).writeAsBytesSync(
        img.encodeJpg(shareImage, quality: 82),
        flush: true,
      );
    });
  }

  Future<void> _addHistory(
    pw.Document pdf,
    ProjectBundle bundle, {
    Map<String, String>? labels,
  }) async {
    final photosByEntry = _photosByEntry(bundle.photos);
    final content = <pw.Widget>[_projectIntro(bundle)];
    for (var index = 0; index < bundle.entries.length; index++) {
      final entry = bundle.entries[index];
      content.addAll([
        pw.SizedBox(height: 18),
        _entryText(entry, index, labels: labels),
        pw.SizedBox(height: 8),
        ...await _photoWidgets(photosByEntry[entry.id].orEmpty),
      ]);
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _header(bundle.project.name, labels?['history'] ?? 'Historia'),
        footer: _footer,
        build: (context) => content,
      ),
    );
  }

  Future<void> _addTutorial(
    pw.Document pdf,
    ProjectBundle bundle, {
    Map<String, String>? labels,
  }) async {
    final photosByEntry = _photosByEntry(bundle.photos);
    final content = <pw.Widget>[_projectIntro(bundle)];
    for (var index = 0; index < bundle.entries.length; index++) {
      final entry = bundle.entries[index];
      content.addAll([
        pw.SizedBox(height: 18),
        pw.Text(
          progressEntryTitle(entry, index),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (entry.description.isNotEmpty) pw.Text(entry.description),
        if (entry.materials.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Text(
              '${labels?['materials'] ?? 'Materiales'}: ${entry.materials}',
            ),
          ),
        pw.SizedBox(height: 8),
        ...await _photoWidgets(photosByEntry[entry.id].orEmpty),
      ]);
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _header(bundle.project.name, labels?['tutorial'] ?? 'Tutorial'),
        footer: _footer,
        build: (context) => content,
      ),
    );
  }

  Future<void> _addAlbum(
    pw.Document pdf,
    ProjectBundle bundle, {
    Map<String, String>? labels,
  }) async {
    final images = <pw.Widget>[];
    for (final photo in bundle.photos) {
      final widget = await _imageWidget(photo, fit: pw.BoxFit.cover);
      if (widget != null) {
        images.add(pw.Container(
          height: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: widget,
        ));
      }
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) =>
            _header(bundle.project.name, labels?['album'] ?? 'Album'),
        footer: _footer,
        build: (context) => [
          pw.Wrap(spacing: 10, runSpacing: 10, children: images),
        ],
      ),
    );
  }

  Future<void> _addBeforeAfter(
    pw.Document pdf,
    ProjectBundle bundle, {
    Map<String, String>? labels,
  }) async {
    final photos = bundle.photos;
    final first = photos.isEmpty ? null : await _imageWidget(photos.first);
    final last = photos.length < 2 ? first : await _imageWidget(photos.last);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(
              bundle.project.name,
              labels?['beforeAfter'] ?? 'Antes y despues',
            ),
            pw.SizedBox(height: 20),
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _labeledImage(
                      labels?['before'] ?? 'Antes',
                      first,
                      labels: labels,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _labeledImage(
                      labels?['after'] ?? 'Despues',
                      last,
                      labels: labels,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<PhotoItem>> _photosByEntry(List<PhotoItem> photos) {
    final result = <String, List<PhotoItem>>{};
    for (final photo in photos) {
      result.putIfAbsent(photo.entryId, () => []).add(photo);
    }
    return result;
  }

  Future<List<pw.Widget>> _photoWidgets(List<PhotoItem> photos) async {
    final widgets = <pw.Widget>[];
    for (final photo in photos) {
      final file = File(photo.displayPath);
      if (!await file.exists()) continue;
      final memory = pw.MemoryImage(await _pdfImageBytes(file.path));
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Container(
          constraints: const pw.BoxConstraints(maxHeight: 420),
          child: pw.Image(memory, fit: pw.BoxFit.contain),
        ),
      ));
    }
    return widgets;
  }

  Future<pw.Widget?> _imageWidget(
    PhotoItem photo, {
    pw.BoxFit fit = pw.BoxFit.contain,
  }) async {
    final file = File(photo.displayPath);
    if (!await file.exists()) return null;
    return pw.Image(pw.MemoryImage(await _pdfImageBytes(file.path)), fit: fit);
  }

  Future<Uint8List> _pdfImageBytes(String path) async {
    return Isolate.run(() {
      final bytes = File(path).readAsBytesSync();
      final rawDecoded = img.decodeImage(bytes);
      if (rawDecoded == null) return bytes;
      final decoded = img.bakeOrientation(rawDecoded);
      const maxSide = 1200;
      final pdfImage = decoded.width > maxSide || decoded.height > maxSide
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? maxSide : null,
              height: decoded.height > decoded.width ? maxSide : null,
              interpolation: img.Interpolation.average,
            )
          : decoded;
      return Uint8List.fromList(img.encodeJpg(pdfImage, quality: 78));
    });
  }

  pw.Widget _labeledImage(
    String label,
    pw.Widget? image, {
    Map<String, String>? labels,
  }) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(label,
              textAlign: pw.TextAlign.center,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: image ??
                  pw.Center(child: pw.Text(labels?['noImage'] ?? 'Sin imagen')),
            ),
          ),
        ],
      );

  pw.Widget _header(String projectName, String mode) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            projectName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Haciendo · $mode', style: const pw.TextStyle(fontSize: 10)),
        ],
      );

  pw.Widget _footer(pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );

  pw.Widget _projectIntro(ProjectBundle bundle) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 12),
          pw.Text(
            bundle.project.name,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          if (bundle.project.description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(bundle.project.description),
            ),
          pw.SizedBox(height: 8),
          pw.Text(
              '${bundle.entries.length} avances · ${bundle.photos.length} fotos'),
        ],
      );

  pw.Widget _entryText(
    ProgressEntry entry,
    int entryIndex, {
    Map<String, String>? labels,
  }) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            progressEntryTitle(entry, entryIndex),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(_date(entry.takenAt),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          if (entry.description.isNotEmpty) pw.Text(entry.description),
          if (entry.materials.isNotEmpty)
            pw.Text(
                '${labels?['materials'] ?? 'Materiales'}: ${entry.materials}'),
        ],
      );

  String _plainText(ProjectBundle bundle, {Map<String, String>? labels}) {
    final buffer = StringBuffer()
      ..writeln(bundle.project.name)
      ..writeln(bundle.project.description)
      ..writeln();
    for (var i = 0; i < bundle.entries.length; i++) {
      final entry = bundle.entries[i];
      buffer.writeln('${i + 1}. ${progressEntryTitle(entry, i)}');
      buffer.writeln(_date(entry.takenAt));
      if (entry.description.isNotEmpty) buffer.writeln(entry.description);
      if (entry.materials.isNotEmpty) {
        buffer.writeln(
          '${labels?['materials'] ?? 'Materiales'}: ${entry.materials}',
        );
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

extension _EmptyPhotos on List<PhotoItem>? {
  List<PhotoItem> get orEmpty => this ?? const [];
}
