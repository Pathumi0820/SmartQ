import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'darkModeEnabled';

  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    _isDarkMode =
        preferences.getBool(_themeKey) ?? false;

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;

    _isDarkMode = enabled;

    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _themeKey,
      enabled,
    );

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}