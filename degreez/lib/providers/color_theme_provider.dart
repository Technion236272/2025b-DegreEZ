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
  }  // Colorful color system (refined vibrant colors)
  Color _getColorfulCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      // Vibrant colors for easy distinction, refined for sophistication
      const Color(0xFF4CAF50), // Material Green
      const Color(0xFFFF9800), // Material Orange
      const Color(0xFFF44336), // Material Red
      const Color(0xFF2196F3), // Material Blue
      const Color(0xFF9C27B0), // Material Purple
      const Color(0xFFFFC107), // Material Amber
      const Color(0xFF00BCD4), // Material Cyan
      const Color(0xFFFF5722), // Material Deep Orange
      const Color(0xFF795548), // Material Brown
      const Color(0xFF607D8B), // Material Blue Grey
      const Color(0xFF8BC34A), // Material Light Green
      const Color(0xFFE91E63), // Material Pink
      const Color(0xFF3F51B5), // Material Indigo
      const Color(0xFF009688), // Material Teal
      const Color(0xFFCDDC39), // Material Lime
      // Additional sophisticated colors that complement the theme
      const Color(0xFF5D7B8A), // Muted blue-gray (harmonizes with Payne's Gray)
      const Color(0xFF8A6B5D), // Warm brown-gray
      const Color(0xFF6B8A5D), // Sage green
      const Color(0xFF8A5D6B), // Muted rose
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
