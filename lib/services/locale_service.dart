import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks and persists the app's display language (English / Hindi / Kannada).
/// Falls back to English until a saved choice loads, and to English for any
/// device locale we don't ship a translation for.
class LocaleService extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
