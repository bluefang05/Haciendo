import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/text_limits.dart';
import '../../data/models/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/pin_service.dart';

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({super.key, this.project});

  final Project? project;

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final PinService _pinService = const PinService();
  late final TextEditingController _name;
  late final TextEditingController _description;
  ProjectStatus _status = ProjectStatus.idea;
  ProjectType _type = ProjectType.standard;
  String? _newPin;
  bool _removePin = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project?.name ?? '');
    _description =
        TextEditingController(text: widget.project?.description ?? '');
    _status = widget.project?.status ?? ProjectStatus.idea;
    _type = widget.project?.type ?? ProjectType.standard;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    Project result;
    if (widget.project == null) {
      result = await _repository.createProject(
        name: _name.text,
        description: _description.text,
        type: _type,
      );
      result = result.copyWith(status: _status);
    } else {
      result = widget.project!.copyWith(
        name: trimToLimit(_name.text, TextLimits.title),
        description: trimToLimit(_description.text, TextLimits.description),
        status: _status,
        type: _type,
        updatedAt: DateTime.now(),
      );
    }
    if (_removePin) result = result.copyWith(clearPinHash: true);
    if (_newPin != null) {
      result =
          result.copyWith(pinHash: _pinService.hashPin(result.id, _newPin!));
    }
    await _repository.upsertProject(result);
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _configurePin() async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('setPin')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 8,
          decoration: const InputDecoration(hintText: '4–8 dígitos'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (RegExp(r'^\d{4,8}$').hasMatch(controller.text)) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text(context.l10n.t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin != null) {
      setState(() {
        _newPin = pin;
        _removePin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null
            ? l10n.t('newProject')
            : widget.project!.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextField(
              controller: _name,
              autofocus: widget.project == null,
              maxLength: TextLimits.title,
              inputFormatters: [
                LengthLimitingTextInputFormatter(TextLimits.title),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.t('projectName')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 7,
              maxLength: TextLimits.description,
              inputFormatters: [
                LengthLimitingTextInputFormatter(TextLimits.description),
              ],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.t('description')),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l10n.t('status')),
              items: ProjectStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(context, status)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 14),
            SegmentedButton<ProjectType>(
              segments: [
                ButtonSegment(
                  value: ProjectType.standard,
                  icon: const Icon(Icons.layers_outlined),
                  label: Text(l10n.t('project')),
                ),
                ButtonSegment(
                  value: ProjectType.sequence,
                  icon: const Icon(Icons.movie_creation_outlined),
                  label: Text(l10n.t('sequence')),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.t('pin')),
              subtitle: Text(
                _removePin
                    ? 'Sin PIN'
                    : _newPin != null || widget.project?.isProtected == true
                        ? 'Protegido'
                        : 'Opcional · privacidad práctica',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                      onPressed: _configurePin, icon: const Icon(Icons.edit)),
                  if (widget.project?.isProtected == true || _newPin != null)
                    IconButton(
                      onPressed: () => setState(() {
                        _removePin = true;
                        _newPin = null;
                      }),
                      icon: const Icon(Icons.lock_open_outlined),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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

  String _statusLabel(BuildContext context, ProjectStatus status) =>
      switch (status) {
        ProjectStatus.idea => context.l10n.t('idea'),
        ProjectStatus.inProgress => context.l10n.t('inProgress'),
        ProjectStatus.paused => context.l10n.t('paused'),
        ProjectStatus.completed => context.l10n.t('completed'),
        ProjectStatus.archived => context.l10n.t('archived'),
      };
}
