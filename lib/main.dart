import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';
import 'services/locale_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MazeReignsApp());
}

class MazeReignsApp extends StatefulWidget {
  const MazeReignsApp({super.key});

  @override
  State<MazeReignsApp> createState() => _MazeReignsAppState();
}

class _MazeReignsAppState extends State<MazeReignsApp> {
  final LocaleService _localeService = LocaleService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: _localeService.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Maze Reigns',
          theme: AppTheme.darkTheme,
          home: const MainMenuScreen(),
          debugShowCheckedModeBanner: false,
          supportedLocales: _localeService.supportedLocales,
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (deviceLocale, supported) {
            if (locale != null) return locale;
            if (deviceLocale == null) return const Locale('en');
            for (final l in supported) {
              if (l.languageCode == deviceLocale.languageCode) {
                return l;
              }
            }
            return const Locale('en');
          },
        );
      },
    );
  }
}

