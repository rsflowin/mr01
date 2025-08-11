import 'package:flutter/material.dart';

class LocaleService {
  LocaleService._internal();
  static final LocaleService instance = LocaleService._internal();

  // null means "follow system"
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

  final List<Locale> supportedLocales = const [
    Locale('en'),
    Locale('ko'),
  ];

  void setLocale(Locale? locale) {
    localeNotifier.value = locale;
  }
}
