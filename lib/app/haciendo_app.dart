import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../data/models/app_settings.dart';
import '../features/home/home_screen.dart';
import 'app_state.dart';

class HaciendoApp extends StatelessWidget {
  const HaciendoApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final settings = state.settings;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Haciendo',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: switch (settings.themePreference) {
              ThemePreference.system => ThemeMode.system,
              ThemePreference.light => ThemeMode.light,
              ThemePreference.dark => ThemeMode.dark,
            },
            locale: settings.localeCode == AppSettings.systemLocaleCode
                ? null
                : AppLocalizations.resolveLocale(Locale(settings.localeCode)),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: state.initialized
                ? const HomeScreen()
                : const _SplashScreen(),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/branding/icon_haciendo_1024.png'),
              width: 120,
              height: 120,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
