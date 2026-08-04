import 'package:flutter/widgets.dart';

import '../data/models/app_settings.dart';
import '../data/services/ad_service.dart';
import '../data/services/file_storage_service.dart';
import '../data/services/reminder_service.dart';
import '../data/services/settings_service.dart';

class AppState extends ChangeNotifier {
  AppState({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  AppSettings _settings = const AppSettings();
  bool _initialized = false;

  AppSettings get settings => _settings;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    await FileStorageService().initialize();
    _settings = await _settingsService.load();
    // Optional services must never prevent access to local projects.
    try {
      await AdService.instance.initialize();
    } catch (_) {
      // The banner can retry later; the app remains fully usable offline.
    }
    try {
      await ReminderService.instance.initialize();
    } catch (_) {
      // A notification setup failure must not block the local gallery.
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _settingsService.save(settings);
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found.');
    return scope!.notifier!;
  }
}
