import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/file_storage_service.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  static const int _pageSize = 30;

  final ProjectRepository _repository = ProjectRepository();
  final FileStorageService _storage = FileStorageService();
  final ScrollController _scrollController = ScrollController();
  final List<Project> _projects = [];
  final Set<String> _busyProjectIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _load();
    }
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
    final projects = await _repository.getProjects(
      limit: _pageSize,
      offset: reset ? 0 : _offset,
      deleted: true,
    );
    if (!mounted) return;
    setState(() {
      if (reset) _projects.clear();
      _projects.addAll(projects);
      _offset += projects.length;
      _hasMore = projects.length == _pageSize;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _restore(Project project) async {
    if (_busyProjectIds.contains(project.id)) return;
    setState(() => _busyProjectIds.add(project.id));
    try {
      await _repository.restoreProject(project);
      await _load(reset: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.t('error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busyProjectIds.remove(project.id));
    }
  }

  Future<void> _deleteForever(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteForever')),
        content: Text(context.l10n.t('deleteForeverWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.t('deleteForever')),
          ),
        ],
      ),
    );
    if (confirmed != true || _busyProjectIds.contains(project.id)) return;
    setState(() => _busyProjectIds.add(project.id));
    Directory? stagedDirectory;
    var databaseDeleted = false;
    try {
      stagedDirectory = await _storage.stageProjectDirectoryForDeletion(
        project.id,
      );
      await _repository.deleteProjectPermanently(project.id);
      databaseDeleted = true;
      await _storage.deleteStagedProjectDirectory(stagedDirectory);
      await _load(reset: true);
    } catch (error) {
      if (!databaseDeleted && stagedDirectory != null) {
        await _storage.restoreStagedProjectDirectory(
          stagedDirectory: stagedDirectory,
          projectId: project.id,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.t('error')}: $error')),
      );
    } finally {
      if (mounted) setState(() => _busyProjectIds.remove(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('trash'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? EmptyState(
                  icon: Icons.delete_outline,
                  message: context.l10n.t('trashEmpty'),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= _projects.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final project = _projects[index];
                    final isBusy = _busyProjectIds.contains(project.id);
                    return Card(
                      child: ListTile(
                        leading: isBusy
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.folder_outlined),
                        title: Text(project.name),
                        subtitle: Text(project.deletedAt == null
                            ? ''
                            : '${project.deletedAt!.day}/${project.deletedAt!.month}/${project.deletedAt!.year}'),
                        trailing: PopupMenuButton<String>(
                          enabled: !isBusy,
                          onSelected: (value) {
                            if (value == 'restore') _restore(project);
                            if (value == 'delete') _deleteForever(project);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restore',
                              child: Text(context.l10n.t('restore')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.t('deleteForever')),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
