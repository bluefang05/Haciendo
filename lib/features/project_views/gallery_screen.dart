import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/ad_banner_slot.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/photo_item.dart';
import '../../data/repositories/project_repository.dart';

class ProjectGalleryScreen extends StatefulWidget {
  const ProjectGalleryScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectGalleryScreen> createState() => _ProjectGalleryScreenState();
}

class _ProjectGalleryScreenState extends State<ProjectGalleryScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final ScrollController _scrollController = ScrollController();
  final List<PhotoItem> _photos = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() => _loading = true);
    if (reset) {
      _offset = 0;
      _hasMore = true;
    }
    final pageSize = AppStateScope.of(context).settings.pageSize;
    final page = await _repository.getProjectPhotosPage(
      widget.projectId,
      limit: pageSize,
      offset: _offset,
      includePrivate: true,
    );
    if (!mounted) return;
    setState(() {
      if (reset) _photos.clear();
      _photos.addAll(page);
      _offset += page.length;
      _hasMore = page.length == pageSize;
      _loading = false;
    });
  }

  Future<void> _openViewer(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photos: _photos,
          initialIndex: index,
          hasMore: _hasMore,
          loadMore: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppStateScope.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('gallery'))),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _photos.isEmpty && !_loading
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * .7,
                    child: EmptyState(
                      icon: Icons.photo_library_outlined,
                      message: context.l10n.t('galleryEmpty'),
                    ),
                  ),
                ],
              )
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 700 ? 5 : 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _photos.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _photos.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final photo = _photos[index];
                  return InkWell(
                    onTap: () => _openViewer(index),
                    child: Hero(
                      tag: 'gallery-${photo.id}',
                      child: Image.file(
                        File(photo.thumbnailPath),
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: AdBannerSlot(enabled: settings.showAds),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.hasMore,
    required this.loadMore,
  });

  final List<PhotoItem> photos;
  final int initialIndex;
  final bool hasMore;
  final Future<void> Function({bool reset}) loadMore;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPageChanged(int value) async {
    setState(() => _index = value);
    if (widget.hasMore && value >= widget.photos.length - 3) {
      await widget.loadMore();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${_index + 1} / ${widget.photos.length}${widget.hasMore ? '+' : ''}',
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return InteractiveViewer(
            minScale: .8,
            maxScale: 5,
            child: Center(
              child: Hero(
                tag: 'gallery-${photo.id}',
                child: Image.file(
                  File(photo.displayPath),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
