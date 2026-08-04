import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/text_limits.dart';
import '../../data/models/photo_item.dart';
import '../../data/models/progress_entry.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/file_storage_service.dart';

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({
    super.key,
    required this.projectId,
    this.entry,
  });

  final String projectId;
  final ProgressEntry? entry;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final FileStorageService _storage = FileStorageService();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _materials;
  final List<String> _pendingPaths = [];
  bool _private = false;
  bool _milestone = false;
  bool _saving = false;
  bool _quickSaving = false;
  late DateTime _takenAt;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _description = TextEditingController(text: widget.entry?.description ?? '');
    _materials = TextEditingController(text: widget.entry?.materials ?? '');
    _private = widget.entry?.isPrivate ?? false;
    _milestone = widget.entry?.isMilestone ?? false;
    _takenAt = widget.entry?.takenAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _materials.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 100);
    if (!mounted) return;
    setState(() => _pendingPaths.addAll(files.map((file) => file.path)));
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (file == null || !mounted) return;
    setState(() => _pendingPaths.add(file.path));
  }

  Future<void> _quickTakePhotoAndSave() async {
    if (_saving) return;
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    if (file == null || !mounted) return;
    setState(() {
      _pendingPaths.add(file.path);
      _quickSaving = true;
    });
    await _save();
  }

  Future<void> _quickPickGalleryAndSave() async {
    if (_saving) return;
    final files = await _picker.pickMultiImage(imageQuality: 100);
    if (files.isEmpty || !mounted) return;
    setState(() {
      _pendingPaths.addAll(files.map((file) => file.path));
      _quickSaving = true;
    });
    await _save();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _takenAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final wasQuickSaving = _quickSaving;
    final preference = AppStateScope.of(context).settings.storagePreference;
    setState(() => _saving = true);
    final importedPhotos = <PhotoItem>[];
    try {
      final ProgressEntry entry;
      if (widget.entry == null) {
        final now = DateTime.now();
        final newEntry = ProgressEntry(
          id: _uuid.v4(),
          projectId: widget.projectId,
          title: trimToLimit(_title.text, TextLimits.title),
          description: trimToLimit(_description.text, TextLimits.description),
          materials: trimToLimit(_materials.text, TextLimits.materials),
          createdAt: now,
          takenAt: _takenAt,
          sortOrder: 0,
          isPrivate: _private,
          isMilestone: _milestone,
        );
        for (var index = 0; index < _pendingPaths.length; index++) {
          final photo = await _storage.importPhoto(
            sourcePath: _pendingPaths[index],
            projectId: widget.projectId,
            entryId: newEntry.id,
            sortOrder: index,
            preference: preference,
          );
          importedPhotos.add(photo);
        }
        entry = await _repository.createEntryWithPhotos(
          entry: newEntry,
          photos: importedPhotos,
        );
      } else {
        entry = widget.entry!.copyWith(
          title: trimToLimit(_title.text, TextLimits.title),
          description: trimToLimit(_description.text, TextLimits.description),
          materials: trimToLimit(_materials.text, TextLimits.materials),
          takenAt: _takenAt,
          isPrivate: _private,
          isMilestone: _milestone,
        );
        await _repository.upsertEntry(entry);
        final existing = await _repository.getPhotosForEntry(entry.id);
        for (var index = 0; index < _pendingPaths.length; index++) {
          final photo = await _storage.importPhoto(
            sourcePath: _pendingPaths[index],
            projectId: widget.projectId,
            entryId: entry.id,
            sortOrder: existing.length + index,
            preference: preference,
          );
          importedPhotos.add(photo);
          await _repository.addPhoto(photo);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(entry);
    } catch (error) {
      for (final photo in importedPhotos) {
        await _storage.deletePhotoFiles(photo);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _quickSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.t('error')}: $error')),
      );
    } finally {
      if (mounted && !wasQuickSaving) {
        setState(() => _quickSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('addProgress'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (widget.entry == null) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _quickTakePhotoAndSave,
                      icon: _saving && _quickSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(l10n.t('quickPhoto')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _saving ? null : _quickPickGalleryAndSave,
                    tooltip: l10n.t('quickGallery'),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.t('quickProgressHint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _title,
              maxLength: TextLimits.title,
              inputFormatters: [
                LengthLimitingTextInputFormatter(TextLimits.title),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.t('title')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 8,
              maxLength: TextLimits.description,
              inputFormatters: [
                LengthLimitingTextInputFormatter(TextLimits.description),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.t('description')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _materials,
              minLines: 2,
              maxLines: 5,
              maxLength: TextLimits.materials,
              inputFormatters: [
                LengthLimitingTextInputFormatter(TextLimits.materials),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.t('materials')),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.t('date')),
              subtitle: Text(
                '${_takenAt.day.toString().padLeft(2, '0')}/'
                '${_takenAt.month.toString().padLeft(2, '0')}/${_takenAt.year} '
                '${_takenAt.hour.toString().padLeft(2, '0')}:'
                '${_takenAt.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _private,
              onChanged: (value) => setState(() => _private = value),
              title: Text(l10n.t('private')),
              secondary: const Icon(Icons.visibility_off_outlined),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _milestone,
              onChanged: (value) => setState(() => _milestone = value),
              title: Text(l10n.t('milestone')),
              secondary: const Icon(Icons.star_outline),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l10n.t('camera')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.t('gallery')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_pendingPaths.isNotEmpty)
              SizedBox(
                height: 116,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingPaths.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final value = _pendingPaths.removeAt(oldIndex);
                      _pendingPaths.insert(newIndex, value);
                    });
                  },
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(_pendingPaths[index]),
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_pendingPaths[index]),
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                            cacheWidth: 320,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _pendingPaths.removeAt(index)),
                            icon: const Icon(Icons.close, size: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
