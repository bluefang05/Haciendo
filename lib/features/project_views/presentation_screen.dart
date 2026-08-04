import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/progress_entry_titles.dart';
import '../../data/models/photo_item.dart';
import '../../data/models/progress_entry.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final PageController _pageController = PageController();
  final List<PhotoItem> _photos = [];
  final Map<String, ProgressEntry> _entries = {};
  Project? _project;
  int _index = 0;
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _showNotes = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;
    setState(() {
      if (reset) {
        _loading = true;
        _offset = 0;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
    });
    final pageSize = AppStateScope.of(context).settings.pageSize;
    final page = await _repository.getPresentationPage(
      widget.projectId,
      limit: pageSize,
      offset: reset ? 0 : _offset,
    );
    if (!mounted) return;
    setState(() {
      _project = page?.project;
      if (reset) {
        _photos.clear();
        _entries.clear();
      }
      if (page != null) {
        _photos.addAll(page.photos);
        _entries
            .addEntries(page.entries.map((entry) => MapEntry(entry.id, entry)));
        _offset += page.photos.length;
        _hasMore = page.photos.length == pageSize;
      } else {
        _hasMore = false;
      }
      _loading = false;
      _loadingMore = false;
    });
  }

  void _onPageChanged(int value) {
    setState(() => _index = value);
    if (value >= _photos.length - 3) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    if (_loading && project == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(project?.name ?? context.l10n.t('presentation')),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showNotes = !_showNotes),
            icon: Icon(_showNotes ? Icons.notes : Icons.notes_outlined),
            tooltip: context.l10n.t('toggleNotes'),
          ),
        ],
      ),
      body: _photos.isEmpty
          ? Center(
              child: Text(
                context.l10n.t('noPublicPhotos'),
                style: const TextStyle(color: Colors.white),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                final entry = _entries[photo.entryId];
                final entryIndex = _entries.values.toList().indexWhere(
                      (item) => item.id == photo.entryId,
                    );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    InteractiveViewer(
                      child: Image.file(
                        File(photo.displayPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (_showNotes && entry != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _NotesOverlay(
                          entry: entry,
                          entryIndex: entryIndex < 0 ? 0 : entryIndex,
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            '${_index + 1}/${_photos.length}${_hasMore ? '+' : ''}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _NotesOverlay extends StatelessWidget {
  const _NotesOverlay({required this.entry, required this.entryIndex});
  final ProgressEntry entry;
  final int entryIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: Colors.black.withValues(alpha: .72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progressEntryTitle(entry, entryIndex),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            if (entry.description.isNotEmpty)
              Text(
                entry.description,
                style: const TextStyle(color: Colors.white),
              ),
            if (entry.materials.isNotEmpty)
              Text(
                '${context.l10n.t('materials')}: ${entry.materials}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}
