// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }
  
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemeToPrefs();
    notifyListeners();
  }
  
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // If there's an error loading preferences, use default theme
      _isDarkMode = false;
    }
  }
  
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Silently handle save errors
    }
  }
  
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF5E35B1), // Deep Purple 600
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5E35B1),
      primary: const Color(0xFF5E35B1),
      secondary: const Color(0xFF7E57C2), // Deep Purple 400
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF5E35B1),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
  
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF7E57C2), // Deep Purple 400 (lighter for dark mode)
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7E57C2),
      primary: const Color(0xFF7E57C2),
      secondary: const Color(0xFF9575CD), // Deep Purple 300
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7E57C2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}