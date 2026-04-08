import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = const Color(0xFF6C63FF); // Default Purple

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
  }

  void changeSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('seedColor', color.value);
  }

  void _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDark = prefs.getBool('isDark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    
    int? colorValue = prefs.getInt('seedColor');
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }
    notifyListeners();
  }
}
