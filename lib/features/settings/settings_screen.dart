import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/l10n/app_localizations.dart';
import '../../data/models/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final settings = state.settings;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: settings.localeCode,
            decoration: InputDecoration(labelText: context.l10n.t('language')),
            items: [
              DropdownMenuItem(
                value: AppSettings.systemLocaleCode,
                child: Text(context.l10n.t('system')),
              ),
              const DropdownMenuItem(value: 'es', child: Text('Español')),
              const DropdownMenuItem(value: 'en', child: Text('English')),
              const DropdownMenuItem(value: 'pt', child: Text('Português')),
              const DropdownMenuItem(value: 'fr', child: Text('Français')),
              const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            ],
            onChanged: (value) {
              if (value != null) {
                state.updateSettings(settings.copyWith(localeCode: value));
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ThemePreference>(
            initialValue: settings.themePreference,
            decoration: InputDecoration(labelText: context.l10n.t('theme')),
            items: [
              DropdownMenuItem(
                value: ThemePreference.system,
                child: Text(context.l10n.t('system')),
              ),
              DropdownMenuItem(
                value: ThemePreference.light,
                child: Text(context.l10n.t('light')),
              ),
              DropdownMenuItem(
                value: ThemePreference.dark,
                child: Text(context.l10n.t('dark')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                state.updateSettings(settings.copyWith(themePreference: value));
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<StoragePreference>(
            initialValue: settings.storagePreference,
            decoration: InputDecoration(labelText: context.l10n.t('storage')),
            items: [
              DropdownMenuItem(
                value: StoragePreference.original,
                child: Text(context.l10n.t('original')),
              ),
              DropdownMenuItem(
                value: StoragePreference.highQuality,
                child: Text(context.l10n.t('highQuality')),
              ),
              DropdownMenuItem(
                value: StoragePreference.saveSpace,
                child: Text(context.l10n.t('saveSpace')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                state.updateSettings(
                  settings.copyWith(storagePreference: value),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.t('storagePreferenceHelp')),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.t('adPlacementHelp')),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: settings.pageSize,
            decoration:
                InputDecoration(labelText: context.l10n.t('itemsPerPage')),
            items: const [
              DropdownMenuItem(value: 12, child: Text('12')),
              DropdownMenuItem(value: 24, child: Text('24')),
              DropdownMenuItem(value: 48, child: Text('48')),
            ],
            onChanged: (value) {
              if (value != null) {
                state.updateSettings(settings.copyWith(pageSize: value));
              }
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.t('appFullName'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Enmanuel Apps · Android API 21+'),
                  const SizedBox(height: 6),
                  Text(context.l10n.t('localPrivacyHelp')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
