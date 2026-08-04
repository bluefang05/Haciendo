import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/ad_banner_slot.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/photo_item.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/import_service.dart';
import '../project/project_detail_screen.dart';
import '../project/project_editor_screen.dart';
import '../security/pin_gate_screen.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<Project> _projects = [];
  final Map<String, Future<PhotoItem?>> _coverPhotoFutures = {};
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  int _loadGeneration = 0;
  bool _reloadAfterCurrentLoad = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) {
      if (reset) _reloadAfterCurrentLoad = true;
      return;
    }
    if (!reset && !_hasMore) return;
    final generation = ++_loadGeneration;
    final query = _searchController.text;
    setState(() => _loading = true);
    if (reset) {
      _offset = 0;
      _hasMore = true;
    }
    final pageSize = AppStateScope.of(context).settings.pageSize;
    final result = await _repository.getProjects(
      limit: pageSize,
      offset: _offset,
      query: query,
    );
    if (!mounted) return;
    if (generation != _loadGeneration || query != _searchController.text) {
      setState(() => _loading = false);
      await _load(reset: true);
      return;
    }
    setState(() {
      if (reset) {
        _projects.clear();
        _coverPhotoFutures.clear();
      }
      _projects.addAll(result);
      _offset += result.length;
      _hasMore = result.length == pageSize;
      _loading = false;
    });
    if (_reloadAfterCurrentLoad) {
      _reloadAfterCurrentLoad = false;
      await _load(reset: true);
    }
  }

  void _queueSearchLoad() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<PhotoItem?>? _coverPhotoFuture(Project project) {
    final coverPhotoId = project.coverPhotoId;
    if (coverPhotoId == null) return null;
    return _coverPhotoFutures.putIfAbsent(
      coverPhotoId,
      () => _repository.getPhoto(coverPhotoId),
    );
  }

  Future<void> _createProject() async {
    final project = await Navigator.of(context).push<Project>(
      MaterialPageRoute(builder: (_) => const ProjectEditorScreen()),
    );
    if (project != null) {
      await _load(reset: true);
      if (!mounted) return;
      await _openProject(project);
    }
  }

  Future<void> _openProject(Project project) async {
    Widget screen = ProjectDetailScreen(projectId: project.id);
    if (project.isProtected) {
      screen = PinGateScreen(project: project, child: screen);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    await _load(reset: true);
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !File(path).existsSync()) return;
    if (!mounted) return;
    final importMode = await showDialog<BackupImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('importBackup')),
        content: Text(context.l10n.t('importBackupModeHelp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, BackupImportMode.replace),
            child: Text(context.l10n.t('replaceIfExists')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, BackupImportMode.copy),
            child: Text(context.l10n.t('createCopy')),
          ),
        ],
      ),
    );
    if (importMode == null || !mounted) return;
    _showBusy(context.l10n.t('loading'));
    try {
      final project = await ImportService().importBackup(
        path,
        mode: importMode,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _load(reset: true);
      if (!mounted) return;
      await _openProject(project);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.t('error')}: $error')),
      );
    }
  }

  void _showBusy(String text) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = AppStateScope.of(context).settings;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('appName')),
            Text(l10n.t('tagline'),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'import') await _importBackup();
              if (value == 'trash' && context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
                await _load(reset: true);
              }
              if (value == 'settings' && context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'import', child: Text(l10n.t('importBackup'))),
              PopupMenuItem(value: 'trash', child: Text(l10n.t('trash'))),
              PopupMenuItem(value: 'settings', child: Text(l10n.t('settings'))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _searchController,
              leading: const Icon(Icons.search),
              hintText: l10n.t('search'),
              onChanged: (_) => _queueSearchLoad(),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _load(reset: true);
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _projects.isEmpty && !_loading
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * .55,
                          child: EmptyState(
                            icon: Icons.layers_outlined,
                            message: l10n.t('emptyProjects'),
                            action: FilledButton.icon(
                              onPressed: _createProject,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.t('newProject')),
                            ),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .78,
                      ),
                      itemCount: _projects.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _projects.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _ProjectCard(
                          project: _projects[index],
                          coverPhotoFuture: _coverPhotoFuture(_projects[index]),
                          onTap: () => _openProject(_projects[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AdBannerSlot(enabled: settings.showAds),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: Text(l10n.t('newProject')),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.coverPhotoFuture,
    required this.onTap,
  });

  final Project project;
  final Future<PhotoItem?>? coverPhotoFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: coverPhotoFuture == null
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.layers_outlined, size: 54),
                    )
                  : FutureBuilder(
                      future: coverPhotoFuture,
                      builder: (context, snapshot) {
                        final photo = snapshot.data;
                        if (photo == null) {
                          return const Center(
                              child: Icon(Icons.image_outlined, size: 48));
                        }
                        return Image.file(
                          File(photo.thumbnailPath),
                          fit: BoxFit.cover,
                          cacheWidth: 480,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined)),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (project.isProtected)
                        const Icon(Icons.lock_outline, size: 18),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(_statusLabel(context, project.status),
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, ProjectStatus status) =>
      switch (status) {
        ProjectStatus.idea => context.l10n.t('idea'),
        ProjectStatus.inProgress => context.l10n.t('inProgress'),
        ProjectStatus.paused => context.l10n.t('paused'),
        ProjectStatus.completed => context.l10n.t('completed'),
        ProjectStatus.archived => context.l10n.t('archived'),
      };
}
