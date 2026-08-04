import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/core/l10n/app_localizations.dart';
import 'package:haciendo/data/models/app_settings.dart';

void main() {
  test('resolveLocale keeps supported languages and falls back to Spanish', () {
    expect(AppLocalizations.resolveLocale(const Locale('en')).languageCode, 'en');
    expect(AppLocalizations.resolveLocale(const Locale('pt')).languageCode, 'pt');
    expect(AppLocalizations.resolveLocale(const Locale('it')).languageCode, 'es');
    expect(AppLocalizations.resolveLocale(null).languageCode, 'es');
  });

  test('system locale code is explicit and not a real language code', () {
    expect(AppSettings.systemLocaleCode, 'system');
    expect(
      AppLocalizations.isSupportedLanguageCode(AppSettings.systemLocaleCode),
      isFalse,
    );
  });

  test('new settings strings exist in every supported language', () {
    const keys = [
      'appFullName',
      'storagePreferenceHelp',
      'adPlacementHelp',
      'itemsPerPage',
      'localPrivacyHelp',
      'shareProcessQualityTitle',
      'shareOriginalPhotos',
      'shareCompressedPhotos',
    ];

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations.forLocale(locale);
      for (final key in keys) {
        expect(l10n.t(key), isNot(key), reason: '${locale.languageCode}: $key');
      }
    }
  });
}
