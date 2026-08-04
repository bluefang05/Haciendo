import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/progress_entry_titles.dart';
import '../../core/widgets/ad_banner_slot.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/photo_item.dart';
import '../../data/models/progress_entry.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/export_service.dart';
import '../../data/services/file_storage_service.dart';
import '../../data/services/reminder_service.dart';
import '../entry/entry_editor_screen.dart';
import '../sequence/sequence_capture_screen.dart';
import '../project_views/before_after_screen.dart';
import '../project_views/gallery_screen.dart';
import '../project_views/presentation_screen.dart';
import 'project_editor_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final ExportService _exportService = ExportService();
  final FileStorageService _storage = FileStorageService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final ScrollController _scrollController = ScrollController();
  final List<ProgressEntry> _entries = [];
  final Map<String, List<PhotoItem>> _photos = {};
  Project? _project;
  bool _loading = false;
  bool _hasMore = true;
  bool _quickPhotoBusy = false;
  int _quickPhotoSessionCount = 0;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadEntries();
    }
  }

  Future<void> _refresh() async {
    final project = await _repository.getProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _project = project;
      _entries.clear();
      _photos.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final pageSize = AppStateScope.of(context).settings.pageSize;
    final page = await _repository.getEntries(
      widget.projectId,
      limit: pageSize,
      offset: _offset,
    );
    final photosByEntry = await _repository.getPhotosForEntries(
      page.map((entry) => entry.id).toList(),
    );
    if (!mounted) return;
    setState(() {
      _photos.addAll(photosByEntry);
      _entries.addAll(page);
      _offset += page.length;
      _hasMore = page.length == pageSize;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final result = await Navigator.of(context).push<ProgressEntry>(
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(projectId: widget.projectId),
      ),
    );
    if (result != null) await _refresh();
  }

  Future<void> _quickAddPhoto({bool keepSession = false}) async {
    if (_quickPhotoBusy) return;
    setState(() {
      _quickPhotoBusy = true;
      if (!keepSession) _quickPhotoSessionCount = 0;
    });
    final storagePreference =
        AppStateScope.of(context).settings.storagePreference;
    final importedPhotos = <PhotoItem>[];
    var busyVisible = false;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      if (file == null || !mounted) return;
      _showBusy();
      busyVisible = true;
      final now = DateTime.now();
      final entry = ProgressEntry(
        id: _uuid.v4(),
        projectId: widget.projectId,
        title: '',
        description: '',
        materials: '',
        createdAt: now,
        takenAt: now,
        sortOrder: 0,
      );
      final photo = await _storage.importPhoto(
        sourcePath: file.path,
        projectId: widget.projectId,
        entryId: entry.id,
        sortOrder: 0,
        preference: storagePreference,
      );
      importedPhotos.add(photo);
      await _repository.createEntryWithPhotos(entry: entry, photos: [photo]);
      await _refresh();
      if (!mounted) return;
      _quickPhotoSessionCount++;
      Navigator.of(context, rootNavigator: true).pop();
      busyVisible = false;
      setState(() => _quickPhotoBusy = false);
      await _showQuickPhotoSavedSheet();
    } catch (error) {
      for (final photo in importedPhotos) {
        await _storage.deletePhotoFiles(photo);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.t('error')}: $error')),
        );
      }
    } finally {
      if (mounted && busyVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted && _quickPhotoBusy) setState(() => _quickPhotoBusy = false);
    }
  }

  Future<void> _showQuickPhotoSavedSheet() async {
    final takeAnother = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(context.l10n.t('progressSaved')),
                subtitle: Text(
                  context.l10n
                      .t('quickPhotoSessionCount')
                      .replaceFirst('{count}', '$_quickPhotoSessionCount'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(context.l10n.t('takeAnother')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.t('finish')),
              ),
            ],
          ),
        ),
      ),
    );
    if (takeAnother == true && mounted) {
      await _quickAddPhoto(keepSession: true);
    }
  }

  Future<void> _deleteEntry(ProgressEntry entry) async {
    await _repository.moveEntryToTrash(entry);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.t('progressDeleted')),
        action: SnackBarAction(
          label: context.l10n.t('undo'),
          onPressed: () async {
            await _repository.restoreEntry(entry);
            await _refresh();
          },
        ),
      ),
    );
  }

  Future<void> _openSequence() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SequenceCaptureScreen(projectId: widget.projectId),
      ),
    );
    await _refresh();
  }

  Future<void> _openGallery() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectGalleryScreen(projectId: widget.projectId),
      ),
    );
  }

  Future<void> _openPresentation() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresentationScreen(projectId: widget.projectId),
      ),
    );
  }

  Future<void> _openBeforeAfter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeforeAfterScreen(projectId: widget.projectId),
      ),
    );
  }

  Future<void> _editProject() async {
    final project = _project;
    if (project == null) return;
    await Navigator.of(context).push<Project>(
      MaterialPageRoute(builder: (_) => ProjectEditorScreen(project: project)),
    );
    await _refresh();
  }

  Future<void> _moveToTrash() async {
    final project = _project;
    if (project == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('delete')),
        content: Text(context.l10n.t('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.moveProjectToTrash(project);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showExport() async {
    final exportLabels = {
      'history': context.l10n.t('history'),
      'tutorial': context.l10n.t('tutorial'),
      'album': context.l10n.t('album'),
      'beforeAfter': context.l10n.t('beforeAfter'),
      'before': context.l10n.t('before'),
      'after': context.l10n.t('after'),
      'materials': context.l10n.t('materials'),
      'noImage': context.l10n.t('noImage'),
    };
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(context.l10n.t('history')),
              onTap: () => Navigator.pop(context, 'history'),
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: Text(context.l10n.t('tutorial')),
              onTap: () => Navigator.pop(context, 'tutorial'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: Text(context.l10n.t('album')),
              onTap: () => Navigator.pop(context, 'album'),
            ),
            ListTile(
              leading: const Icon(Icons.compare),
              title: Text(context.l10n.t('beforeAfter')),
              onTap: () => Navigator.pop(context, 'beforeAfter'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: Text(context.l10n.t('shareProcess')),
              subtitle: Text(context.l10n.t('shareProcessSubtitle')),
              onTap: () => Navigator.pop(context, 'shareProcess'),
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(context.l10n.t('backup')),
              subtitle: Text(context.l10n.t('restorableInHaciendo')),
              onTap: () => Navigator.pop(context, 'backup'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: Text(context.l10n.t('shareZip')),
              subtitle: Text(context.l10n.t('privateExcluded')),
              onTap: () => Navigator.pop(context, 'shareZip'),
            ),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;
    ProcessShareQuality shareQuality = ProcessShareQuality.original;
    if (selection == 'shareProcess') {
      final chosenQuality = await _chooseShareProcessQuality();
      if (chosenQuality == null) return;
      shareQuality = chosenQuality;
    }
    _showBusy();
    try {
      switch (selection) {
        case 'history':
          await _exportService.sharePdf(
            projectId: widget.projectId,
            mode: PdfExportMode.history,
            labels: exportLabels,
          );
          break;
        case 'tutorial':
          await _exportService.sharePdf(
            projectId: widget.projectId,
            mode: PdfExportMode.tutorial,
            labels: exportLabels,
          );
          break;
        case 'album':
          await _exportService.sharePdf(
            projectId: widget.projectId,
            mode: PdfExportMode.album,
            labels: exportLabels,
          );
          break;
        case 'beforeAfter':
          await _exportService.sharePdf(
            projectId: widget.projectId,
            mode: PdfExportMode.beforeAfter,
            labels: exportLabels,
          );
          break;
        case 'shareProcess':
          await _exportService.shareProcessPhotos(
            widget.projectId,
            quality: shareQuality,
          );
          break;
        case 'backup':
          await _exportService.shareBackup(widget.projectId);
          break;
        case 'shareZip':
          await _exportService.shareShareableZip(
            widget.projectId,
            labels: exportLabels,
          );
          break;
      }
    } catch (error) {
      if (mounted) {
        final message = error is ExportServiceException
            ? context.l10n.t(error.messageKey)
            : '${context.l10n.t('error')}: $error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<ProcessShareQuality?> _chooseShareProcessQuality() {
    return showModalBottomSheet<ProcessShareQuality>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.t('shareProcessQualityTitle')),
                subtitle: Text(context.l10n.t('shareProcessQualitySubtitle')),
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined),
                title: Text(context.l10n.t('shareOriginalPhotos')),
                subtitle: Text(context.l10n.t('shareOriginalPhotosSubtitle')),
                onTap: () => Navigator.pop(
                  context,
                  ProcessShareQuality.original,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.compress_outlined),
                title: Text(context.l10n.t('shareCompressedPhotos')),
                subtitle:
                    Text(context.l10n.t('shareCompressedPhotosSubtitle')),
                onTap: () => Navigator.pop(
                  context,
                  ProcessShareQuality.compressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scheduleReminder() async {
    final project = _project;
    if (project == null) return;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ReminderService.instance.requestPermission();
    await ReminderService.instance.schedule(
      id: project.id.hashCode & 0x7fffffff,
      dateTime: dateTime,
      projectName: project.name,
    );
    final updated = project.copyWith(
      reminderAt: dateTime,
      reminderEnabled: true,
      updatedAt: DateTime.now(),
    );
    await _repository.upsertProject(updated);
    if (!mounted) return;
    setState(() => _project = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n
              .t('reminderScheduled')
              .replaceFirst('{date}', _dateTime(dateTime)),
        ),
      ),
    );
  }

  void _showBusy() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final settings = AppStateScope.of(context).settings;
    if (project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            onPressed: _openGallery,
            tooltip: context.l10n.t('gallery'),
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            onPressed: _showExport,
            tooltip: context.l10n.t('export'),
            icon: const Icon(Icons.ios_share_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'presentation') _openPresentation();
              if (value == 'compare') _openBeforeAfter();
              if (value == 'edit') _editProject();
              if (value == 'reminder') _scheduleReminder();
              if (value == 'delete') _moveToTrash();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'presentation',
                child: Text(context.l10n.t('presentation')),
              ),
              PopupMenuItem(
                value: 'compare',
                child: Text(context.l10n.t('beforeAfter')),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'edit', child: Text(context.l10n.t('editProject'))),
              PopupMenuItem(
                  value: 'reminder', child: Text(context.l10n.t('reminder'))),
              PopupMenuItem(
                  value: 'delete', child: Text(context.l10n.t('delete'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _ProjectHeader(project: project)),
                  if (_entries.isEmpty && !_loading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.add_photo_alternate_outlined,
                        message: context.l10n.t('noEntries'),
                        action: FilledButton.icon(
                          onPressed: _addEntry,
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.t('addProgress')),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: _entries.length + (_loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _entries.length) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final entry = _entries[index];
                          return _EntryCard(
                            entry: entry,
                            entryIndex: index,
                            photos: _photos[entry.id] ?? const [],
                            onEdit: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EntryEditorScreen(
                                    projectId: widget.projectId,
                                    entry: entry,
                                  ),
                                ),
                              );
                              await _refresh();
                            },
                            onDelete: () => _deleteEntry(entry),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdBannerSlot(enabled: settings.showAds),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'quickPhoto',
            onPressed: _quickPhotoBusy ? null : _quickAddPhoto,
            tooltip: context.l10n.t('quickPhoto'),
            child: const Icon(Icons.camera_alt_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'sequence',
            onPressed: _openSequence,
            tooltip: context.l10n.t('sequence'),
            child: const Icon(Icons.movie_creation_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'progress',
            onPressed: _addEntry,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(context.l10n.t('addProgress')),
          ),
        ],
      ),
    );
  }

  String _dateTime(DateTime value) =>
      '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(label: Text(_status(context, project.status))),
                  const Spacer(),
                  if (project.isProtected) const Icon(Icons.lock_outline),
                  if (project.isFavorite) const Icon(Icons.favorite),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(project.description),
              ],
              if (project.reminderEnabled && project.reminderAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${project.reminderAt!.day}/${project.reminderAt!.month}/${project.reminderAt!.year}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _status(BuildContext context, ProjectStatus status) =>
      switch (status) {
        ProjectStatus.idea => context.l10n.t('idea'),
        ProjectStatus.inProgress => context.l10n.t('inProgress'),
        ProjectStatus.paused => context.l10n.t('paused'),
        ProjectStatus.completed => context.l10n.t('completed'),
        ProjectStatus.archived => context.l10n.t('archived'),
      };
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.entryIndex,
    required this.photos,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgressEntry entry;
  final int entryIndex;
  final List<PhotoItem> photos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (entry.isMilestone) const Icon(Icons.star, size: 20),
                    if (entry.isMilestone) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        progressEntryTitle(entry, entryIndex),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (entry.isPrivate)
                      const Icon(Icons.visibility_off_outlined, size: 19),
                    if (entry.isSequence)
                      const Icon(Icons.movie_outlined, size: 19),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(context.l10n.t('delete')),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${entry.takenAt.day}/${entry.takenAt.month}/${entry.takenAt.year}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.description),
                ],
                if (entry.materials.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${context.l10n.t('materials')}: ${entry.materials}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(photos[index].thumbnailPath),
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          cacheWidth: 390,
                          errorBuilder: (_, __, ___) => Container(
                            width: 130,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
