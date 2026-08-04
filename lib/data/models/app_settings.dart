enum ThemePreference { system, light, dark }
enum StoragePreference { original, highQuality, saveSpace }

class AppSettings {
  const AppSettings({
    this.localeCode = systemLocaleCode,
    this.themePreference = ThemePreference.system,
    this.storagePreference = StoragePreference.original,
    this.showAds = true,
    this.pageSize = 24,
  });

  final String localeCode;
  final ThemePreference themePreference;
  final StoragePreference storagePreference;
  final bool showAds;
  final int pageSize;

  static const String systemLocaleCode = 'system';

  AppSettings copyWith({
    String? localeCode,
    ThemePreference? themePreference,
    StoragePreference? storagePreference,
    bool? showAds,
    int? pageSize,
  }) =>
      AppSettings(
        localeCode: localeCode ?? this.localeCode,
        themePreference: themePreference ?? this.themePreference,
        storagePreference: storagePreference ?? this.storagePreference,
        showAds: showAds ?? this.showAds,
        pageSize: pageSize ?? this.pageSize,
      );
}
