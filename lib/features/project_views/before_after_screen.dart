import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/photo_item.dart';
import '../../data/repositories/project_repository.dart';

class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  final ProjectRepository _repository = ProjectRepository();
  PhotoItem? _first;
  PhotoItem? _last;
  bool _loading = true;
  double _split = .5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repository.getProjectEdgePhoto(widget.projectId, first: true),
      _repository.getProjectEdgePhoto(widget.projectId, first: false),
    ]);
    if (!mounted) return;
    setState(() {
      _first = results[0];
      _last = results[1];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_first == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.t('beforeAfter'))),
        body: EmptyState(
          icon: Icons.compare_outlined,
          message: context.l10n.t('beforeAfterEmpty'),
        ),
      );
    }
    final after = _last ?? _first!;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('beforeAfter'))),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(after.displayPath), fit: BoxFit.contain),
                ClipRect(
                  clipper: _HorizontalClipper(_split),
                  child: Image.file(
                    File(_first!.displayPath),
                    fit: BoxFit.contain,
                  ),
                ),
                Align(
                  alignment: Alignment(_split * 2 - 1, 0),
                  child: Container(width: 3, color: Colors.white),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(context.l10n.t('before')),
                  Expanded(
                    child: Slider(
                      value: _split,
                      onChanged: (value) => setState(() => _split = value),
                    ),
                  ),
                  Text(context.l10n.t('after')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalClipper extends CustomClipper<Rect> {
  const _HorizontalClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_HorizontalClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
