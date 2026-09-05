import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks and persists the app's theme mode (System / Light / Dark).
///
/// Same shape as [LocaleService] — falls back to a default (System) until
/// the saved choice loads, then updates and persists on every change.
///
/// NOTE (scope): this wires up the real switch and a real dark [ThemeData]
/// (see AppTheme.dark in app_theme.dart), so Material's own chrome — default
/// AppBars, dialogs, snackbars, switches, the base text theme — responds
/// immediately. Most screens in this app set their colors directly from the
/// [AppColors] constants rather than through `Theme.of(context)`, though, so
/// they won't visually change yet; converting them screen-by-screen to read
/// from the theme is separate, follow-up work.
class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final parsed = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
    if (parsed != null && parsed != _mode) {
      _mode = parsed;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
