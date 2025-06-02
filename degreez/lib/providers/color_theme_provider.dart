// lib/providers/color_theme_provider.dart - New provider for color scheme switching

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../color/color_palette.dart';

enum ColorThemeMode {
  colorful,    // New soft colorful system
  classic,     // Original color palette system
}

class ColorThemeProvider with ChangeNotifier {
  ColorThemeMode _currentMode = ColorThemeMode.colorful;
  late CourseCardColorPalette _classicPalette;

  ColorThemeProvider() {
    _classicPalette = CourseCardColorPalette2();
    _loadSavedTheme();
  }

  ColorThemeMode get currentMode => _currentMode;
  bool get isColorful => _currentMode == ColorThemeMode.colorful;
  bool get isClassic => _currentMode == ColorThemeMode.classic;

  // Load saved theme preference
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('color_theme_mode');
      if (savedMode != null) {
        _currentMode = ColorThemeMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ColorThemeMode.colorful,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading color theme: $e');
    }
  }

  // Save theme preference
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('color_theme_mode', _currentMode.name);
    } catch (e) {
      debugPrint('Error saving color theme: $e');
    }
  }

  // Toggle between color modes
  Future<void> toggleColorMode() async {
    _currentMode = _currentMode == ColorThemeMode.colorful 
        ? ColorThemeMode.classic 
        : ColorThemeMode.colorful;
    await _saveTheme();
    notifyListeners();
  }

  // Set specific color mode
  Future<void> setColorMode(ColorThemeMode mode) async {
    if (_currentMode != mode) {
      _currentMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  // Get course color based on current theme
  Color getCourseColor(String courseId) {
    switch (_currentMode) {
      case ColorThemeMode.colorful:
        return _getColorfulCourseColor(courseId);
      case ColorThemeMode.classic:
        return _classicPalette.cardBG(courseId);
    }
  }

  // Colorful color system (new soft colors)
  Color _getColorfulCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.pink.shade300,      // Soft pink
      Colors.blue.shade400,      // Soft blue
      Colors.green.shade400,     // Soft green
      Colors.orange.shade400,    // Soft orange
      Colors.purple.shade400,    // Soft purple
      Colors.teal.shade400,      // Soft teal
      Colors.indigo.shade400,    // Soft indigo
      Colors.red.shade400,       // Soft red
    ];
    return colors[hash.abs() % colors.length];
  }

  // Get theme name for display
  String get currentThemeName {
    switch (_currentMode) {
      case ColorThemeMode.colorful:
        return 'Colorful Theme';
      case ColorThemeMode.classic:
        return 'Classic Theme';
    }
  }

  // Get theme icon
  IconData get currentThemeIcon {
    switch (_currentMode) {
      case ColorThemeMode.colorful:
        return Icons.palette;
      case ColorThemeMode.classic:
        return Icons.style;
    }
  }
}
