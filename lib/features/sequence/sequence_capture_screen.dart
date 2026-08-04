import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/file_names.dart';
import '../../data/models/photo_item.dart';
import '../../data/models/progress_entry.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/file_storage_service.dart';
import '../../data/services/platform_service.dart';

class SequenceCaptureScreen extends StatefulWidget {
  const SequenceCaptureScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<SequenceCaptureScreen> createState() => _SequenceCaptureScreenState();
}

class _SequenceCaptureScreenState extends State<SequenceCaptureScreen>
    with WidgetsBindingObserver {
  final ProjectRepository _repository = ProjectRepository();
  final FileStorageService _storage = FileStorageService();
  CameraController? _controller;
  ProgressEntry? _entry;
  List<PhotoItem> _frames = [];
  double _onionOpacity = .35;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      camera.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initialize() async {
    final sequenceTitle = context.l10n.t('sequence');
    final sequenceDescription = context.l10n.t('sequenceDescription');
    await _storage.initialize();
    final entries = await _repository.getAllEntries(widget.projectId);
    _entry = entries.where((entry) => entry.isSequence).firstOrNull;
    _entry ??= await _repository.createEntry(
      projectId: widget.projectId,
      title: sequenceTitle,
      description: sequenceDescription,
      isSequence: true,
    );
    _frames = await _repository.getPhotosForEntry(_entry!.id);
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (mounted) setState(() => _busy = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera available.');
      final back = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back);
      final selected = back.isEmpty ? cameras.first : back.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _busy = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _capture() async {
    final camera = _controller;
    final entry = _entry;
    if (camera == null ||
        entry == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      return;
    }
    final storagePreference =
        AppStateScope.of(context).settings.storagePreference;
    setState(() => _busy = true);
    try {
      final file = await camera.takePicture();
      final photo = await _storage.importPhoto(
        sourcePath: file.path,
        projectId: widget.projectId,
        entryId: entry.id,
        sortOrder: _frames.length,
        preference: storagePreference,
        isSequenceFrame: true,
      );
      await _repository.addPhoto(photo);
      if (!mounted) return;
      setState(() {
        _frames = [..._frames, photo];
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _delete(PhotoItem frame) async {
    await _repository.deletePhoto(frame.id);
    await _storage.deletePhotoFiles(frame);
    setState(() => _frames.remove(frame));
    await _repository.reorderPhotos(_frames);
  }

  Future<void> _duplicate(PhotoItem frame) async {
    final newFrame = await _storage.duplicatePhoto(
      source: frame,
      newId: const Uuid().v4(),
      sortOrder: _frames.indexOf(frame) + 1,
    );
    await _repository.addPhoto(newFrame);
    final index = _frames.indexOf(frame) + 1;
    setState(() => _frames.insert(index, newFrame));
    await _repository.reorderPhotos(_frames);
  }

  Future<void> _preview() async {
    if (_frames.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SequencePreviewScreen(frames: _frames)),
    );
  }

  Future<void> _exportFrames() async {
    if (_frames.isEmpty) return;
    final project = await _repository.getProject(widget.projectId);
    final path = await _storage.createExportPath(
      'Haciendo_${safeFileName(project?.name ?? 'secuencia')}_fotogramas.zip',
    );
    final encoder = ZipFileEncoder();
    encoder.create(path);
    for (var i = 0; i < _frames.length; i++) {
      final file = File(_frames[i].displayPath);
      if (!await file.exists()) continue;
      await encoder.addFile(
          file, 'frame_${(i + 1).toString().padLeft(5, '0')}.jpg');
    }
    encoder.close();
    await PlatformService.instance.shareFiles(
      [path],
      mimeType: 'application/zip',
      subject: 'Fotogramas de Haciendo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final camera = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.l10n.t('sequence')),
        actions: [
          IconButton(
            onPressed: _frames.isEmpty ? null : _preview,
            icon: const Icon(Icons.play_arrow),
            tooltip: context.l10n.t('preview'),
          ),
          IconButton(
            onPressed: _frames.isEmpty ? null : _exportFrames,
            icon: const Icon(Icons.folder_zip_outlined),
            tooltip: context.l10n.t('export'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (camera != null && camera.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: camera.value.aspectRatio,
                      child: CameraPreview(camera),
                    ),
                  )
                else if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                if (_frames.isNotEmpty && _onionOpacity > 0)
                  IgnorePointer(
                    child: Opacity(
                      opacity: _onionOpacity,
                      child: Image.file(
                        File(_frames.last.displayPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 8,
                  child: Card(
                    color: Colors.black54,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.layers, color: Colors.white),
                        Expanded(
                          child: Slider(
                            value: _onionOpacity,
                            min: 0,
                            max: .8,
                            onChanged: (value) =>
                                setState(() => _onionOpacity = value),
                          ),
                        ),
                        Text('${(_onionOpacity * 100).round()}%',
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 82,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _frames.length,
                    onReorderItem: (oldIndex, newIndex) async {
                      setState(() {
                        final item = _frames.removeAt(oldIndex);
                        _frames.insert(newIndex, item);
                      });
                      await _repository.reorderPhotos(_frames);
                    },
                    itemBuilder: (context, index) {
                      final frame = _frames[index];
                      return GestureDetector(
                        key: ValueKey(frame.id),
                        onLongPress: () => _showFrameMenu(frame),
                        child: Container(
                          width: 74,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(File(frame.thumbnailPath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            color: Colors.black54,
                            child: Text('${index + 1}',
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${_frames.length} ${context.l10n.t('frames')}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 20),
                    FloatingActionButton.large(
                      heroTag: 'capture',
                      onPressed: _busy ? null : _capture,
                      child: _busy
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.camera_alt, size: 34),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFrameMenu(PhotoItem frame) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.t('duplicateFrame')),
              onTap: () => Navigator.pop(context, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.t('delete')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'duplicate') await _duplicate(frame);
    if (action == 'delete') await _delete(frame);
  }
}

class SequencePreviewScreen extends StatefulWidget {
  const SequencePreviewScreen({super.key, required this.frames});

  final List<PhotoItem> frames;

  @override
  State<SequencePreviewScreen> createState() => _SequencePreviewScreenState();
}

class _SequencePreviewScreenState extends State<SequencePreviewScreen> {
  Timer? _timer;
  int _index = 0;
  double _fps = 6;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_playing || widget.frames.length < 2) return;
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / _fps).round()),
      (_) => setState(() => _index = (_index + 1) % widget.frames.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(context.l10n.t('preview'))),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(
                File(widget.frames[_index].displayPath),
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton.filled(
                    onPressed: () {
                      setState(() => _playing = !_playing);
                      _restartTimer();
                    },
                    icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fps,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      label: '${_fps.round()} fps',
                      onChanged: (value) {
                        setState(() => _fps = value);
                        _restartTimer();
                      },
                    ),
                  ),
                  Text('${_fps.round()} fps',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
