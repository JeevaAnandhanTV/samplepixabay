import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the selected [ThemeMode] (system -> light -> dark).
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    final saved = _prefs.getString(_key);
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> cycle() async {
    _mode = switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    await _prefs.setString(_key, _mode.name);
  }
}
