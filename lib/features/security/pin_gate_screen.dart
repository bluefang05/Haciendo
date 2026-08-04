import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/project.dart';
import '../../data/services/pin_service.dart';

class PinGateScreen extends StatefulWidget {
  const PinGateScreen({
    super.key,
    required this.project,
    required this.child,
  });

  final Project project;
  final Widget child;

  @override
  State<PinGateScreen> createState() => _PinGateScreenState();
}

class _PinGateScreenState extends State<PinGateScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final PinService _pinService = const PinService();
  bool _unlocked = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_unlocked && mounted) {
        setState(() {
          _unlocked = false;
          _controller.clear();
          _wrong = false;
        });
      }
    }
  }

  void _unlock() {
    final stored = widget.project.pinHash;
    if (stored == null) {
      setState(() => _unlocked = true);
      return;
    }
    final valid = _pinService.verify(
      projectId: widget.project.id,
      pin: _controller.text,
      storedHash: stored,
    );
    setState(() {
      _unlocked = valid;
      _wrong = !valid;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(context.l10n.t('enterPin'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    onSubmitted: (_) => _unlock(),
                    decoration: InputDecoration(
                      errorText: _wrong ? context.l10n.t('wrongPin') : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _unlock,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text(context.l10n.t('unlock')),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'El PIN protege el acceso dentro de la app. No cifra los archivos del dispositivo.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
