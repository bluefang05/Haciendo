import 'package:sqflite/sqflite.dart';

import '../../core/l10n/app_localizations.dart';
import '../db/app_database.dart';
import '../models/app_settings.dart';

class SettingsService {
  SettingsService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<AppSettings> load() async {
    final db = await _database.database;
    final rows = await db.query('settings');
    final values = <String, String>{
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
    return AppSettings(
      localeCode: _localeCode(values['locale']),
      themePreference: _enumValue(
        ThemePreference.values,
        values['theme'],
        ThemePreference.system,
      ),
      storagePreference: _enumValue(
        StoragePreference.values,
        values['storage'],
        StoragePreference.original,
      ),
      showAds: values['show_ads'] != 'false',
      pageSize: int.tryParse(values['page_size'] ?? '') ?? 24,
    );
  }

  Future<void> save(AppSettings settings) async {
    final db = await _database.database;
    final values = {
      'locale': settings.localeCode,
      'theme': settings.themePreference.name,
      'storage': settings.storagePreference.name,
      'show_ads': settings.showAds.toString(),
      'page_size': settings.pageSize.toString(),
    };
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  String _localeCode(String? value) {
    if (value == AppSettings.systemLocaleCode) return value!;
    if (value != null && AppLocalizations.isSupportedLanguageCode(value)) {
      return value;
    }
    return AppSettings.systemLocaleCode;
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
