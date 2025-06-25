// lib/providers/theme_provider.dart - Enhanced theme provider for light/dark mode switching

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../color/color_palette.dart';

enum AppThemeMode {
  light,
  dark,
  system, // Follow system theme
}

enum ColorThemeMode {
  colorful,    // Colorful system
  classic,     // Original color palette system
}

class ThemeProvider with ChangeNotifier {
  AppThemeMode _currentThemeMode = AppThemeMode.dark;
  ColorThemeMode _currentColorMode = ColorThemeMode.colorful;
  
  // Keep track of system brightness for system mode
  Brightness _systemBrightness = Brightness.dark;

  ThemeProvider() {
    _loadSavedTheme();
  }

  // Getters
  AppThemeMode get currentThemeMode => _currentThemeMode;
  ColorThemeMode get currentColorMode => _currentColorMode;
  Brightness get systemBrightness => _systemBrightness;
  
  bool get isDarkMode {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }
  
  bool get isLightMode => !isDarkMode;
  bool get isSystemMode => _currentThemeMode == AppThemeMode.system;
  bool get isColorful => _currentColorMode == ColorThemeMode.colorful;
  bool get isClassic => _currentColorMode == ColorThemeMode.classic;

  // Update system brightness (call this from main app when system changes)
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      if (_currentThemeMode == AppThemeMode.system) {
        notifyListeners();
      }
    }
  }

  // Load saved theme preference
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final savedThemeMode = prefs.getString('app_theme_mode');
      if (savedThemeMode != null) {
        _currentThemeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeMode,
          orElse: () => AppThemeMode.dark,
        );
      }
      
      // Load color mode
      final savedColorMode = prefs.getString('color_theme_mode');
      if (savedColorMode != null) {
        _currentColorMode = ColorThemeMode.values.firstWhere(
          (mode) => mode.name == savedColorMode,
          orElse: () => ColorThemeMode.colorful,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  // Save theme preference
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_mode', _currentThemeMode.name);
      await prefs.setString('color_theme_mode', _currentColorMode.name);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Set specific theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentThemeMode != mode) {
      _currentThemeMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  // Toggle between light and dark (ignores system mode)
  Future<void> toggleLightDark() async {
    final newMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  // Set specific color mode
  Future<void> setColorMode(ColorThemeMode mode) async {
    if (_currentColorMode != mode) {
      _currentColorMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  // Toggle between color modes
  Future<void> toggleColorMode() async {
    _currentColorMode = _currentColorMode == ColorThemeMode.colorful 
        ? ColorThemeMode.classic 
        : ColorThemeMode.colorful;
    await _saveTheme();
    notifyListeners();
  }

  // Get current app colors based on theme mode
  Type get currentAppColors {
    return isDarkMode ? AppColorsDarkMode : AppColorsLightMode;
  }
  // Helper methods to get colors dynamically
  Color get mainColor => isDarkMode ? AppColorsDarkMode.mainColor : AppColorsLightMode.mainColor;
  Color get surfaceColor => isDarkMode ? AppColorsDarkMode.surfaceColor : AppColorsLightMode.surfaceColor;
  Color get cardColor => isDarkMode ? AppColorsDarkMode.cardColor : AppColorsLightMode.cardColor;
  Color get primaryColor => isDarkMode ? AppColorsDarkMode.primaryColor : AppColorsLightMode.primaryColor;
  Color get secondaryColor => isDarkMode ? AppColorsDarkMode.secondaryColor : AppColorsLightMode.secondaryColor;
  Color get accentColor => isDarkMode ? AppColorsDarkMode.accentColor : AppColorsLightMode.accentColor;
  Color get textPrimary => isDarkMode ? AppColorsDarkMode.textPrimary : AppColorsLightMode.textPrimary;
  Color get textSecondary => isDarkMode ? AppColorsDarkMode.textSecondary : AppColorsLightMode.textSecondary;
  Color get borderPrimary => isDarkMode ? AppColorsDarkMode.borderPrimary : AppColorsLightMode.borderPrimary;
    // State colors
  Color get successColor => isDarkMode ? AppColorsDarkMode.successColor : AppColorsLightMode.successColor;
  Color get errorColor => isDarkMode ? AppColorsDarkMode.errorColor : AppColorsLightMode.errorColor;
  Color get warningColor => isDarkMode ? AppColorsDarkMode.warningColor : AppColorsLightMode.warningColor;
  
  // Grade colors based on percentage
  Color getGradeColor(double grade) {
    if (grade >= 80) return successColor; // Green for 80+
    if (grade >= 70) return warningColor; // Orange for 70-79
    if (grade >= 55) return primaryColor; // Blue for 55-69
    return errorColor; // Red for below 55
  }

  // Get course color based on current color theme
  Color getCourseColor(String courseId) {
    switch (_currentColorMode) {
      case ColorThemeMode.colorful:
        return _getColorfulCourseColor(courseId);
      case ColorThemeMode.classic:
        return _getClassicCourseColor(courseId);
    }
  }

  // Colorful color system - Bright, vibrant colors for modern look
  Color _getColorfulCourseColor(String courseId) {
    final hash = courseId.hashCode;
    
    // Bright, vibrant colors that work well in both themes
    final colors = isDarkMode ? [
      // Dark theme - bright, saturated colors for contrast
      const Color(0xFF00E676), // Bright Green
      const Color(0xFFFF6D00), // Bright Orange
      const Color(0xFFFF1744), // Bright Red
      const Color(0xFF2979FF), // Bright Blue
      const Color(0xFFD500F9), // Bright Purple
      const Color(0xFFFFD600), // Bright Yellow
      const Color(0xFF00E5FF), // Bright Cyan
      const Color(0xFFFF3D00), // Bright Deep Orange
      const Color(0xFF795548), // Material Brown
      const Color(0xFF607D8B), // Material Blue Grey
      const Color(0xFF64DD17), // Bright Light Green
      const Color(0xFFE91E63), // Bright Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF1DE9B6), // Bright Teal
      const Color(0xFFC6FF00), // Bright Lime
      const Color(0xFFFF9100), // Bright Amber
      const Color(0xFF651FFF), // Bright Deep Purple
      const Color(0xFF00BCD4), // Cyan
    ] : [
      // Light theme - vibrant but slightly toned down for readability
      const Color(0xFF00C853), // Vibrant Green
      const Color(0xFFFF5722), // Vibrant Orange
      const Color(0xFFE53935), // Vibrant Red
      const Color(0xFF1E88E5), // Vibrant Blue
      const Color(0xFF8E24AA), // Vibrant Purple
      const Color(0xFFFBC02D), // Vibrant Yellow
      const Color(0xFF00ACC1), // Vibrant Cyan
      const Color(0xFFD84315), // Vibrant Deep Orange
      const Color(0xFF6D4C41), // Brown
      const Color(0xFF546E7A), // Blue Grey
      const Color(0xFF43A047), // Light Green
      const Color(0xFFAD1457), // Pink
      const Color(0xFF3949AB), // Indigo
      const Color(0xFF00897B), // Teal
      const Color(0xFF827717), // Lime
      const Color(0xFFFF8F00), // Amber
      const Color(0xFF5E35B1), // Deep Purple
      const Color(0xFF0097A7), // Cyan variant
    ];
    
    return colors[hash.abs() % colors.length];
  }

  // Classic color system - Professional, muted colors inspired by traditional academia
  Color _getClassicCourseColor(String courseId) {
    final hash = courseId.hashCode;
    
    // Professional, muted colors that work well in academic contexts
    final colors = isDarkMode ? [
      // Dark theme - sophisticated, muted colors
      const Color(0xFF5D7B8A), // Muted blue-gray
      const Color(0xFF8A6B5D), // Warm brown-gray
      const Color(0xFF6B8A5D), // Sage green
      const Color(0xFF8A5D6B), // Muted rose
      const Color(0xFF7A5D8A), // Muted purple-gray
      const Color(0xFF5D8A7A), // Teal-gray
      const Color(0xFF8A7A5D), // Olive-gray
      const Color(0xFF6B5D8A), // Purple-gray
      const Color(0xFF8A8A5D), // Yellow-gray
      const Color(0xFF5D6B8A), // Blue-purple-gray
      const Color(0xFF7A8A5D), // Green-yellow-gray
      const Color(0xFF8A5D7A), // Pink-gray
      const Color(0xFF5D8A8A), // Cyan-gray
      const Color(0xFF8A6B7A), // Rose-brown
      const Color(0xFF6B7A8A), // Steel blue-gray
    ] : [
      // Light theme - classic, professional colors
      const Color(0xFF37474F), // Dark blue-gray
      const Color(0xFF5D4037), // Dark brown
      const Color(0xFF2E7D32), // Forest green
      const Color(0xFF7B1FA2), // Deep purple
      const Color(0xFF1565C0), // Deep blue
      const Color(0xFFBF360C), // Deep orange
      const Color(0xFF00695C), // Deep teal
      const Color(0xFF4A148C), // Deep purple variant
      const Color(0xFF827717), // Olive
      const Color(0xFF01579B), // Light blue variant
      const Color(0xFF33691E), // Light green variant
      const Color(0xFF880E4F), // Deep pink
      const Color(0xFF006064), // Cyan variant
      const Color(0xFF3E2723), // Brown variant
      const Color(0xFF263238), // Blue grey variant
    ];
    
    return colors[hash.abs() % colors.length];
  }

  // Get Flutter ThemeData based on current settings
  ThemeData get themeData {
    if (isDarkMode) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColorsDarkMode.mainColor,
        canvasColor: AppColorsDarkMode.mainColor,
        cardColor: AppColorsDarkMode.cardColor,
        colorScheme: const ColorScheme.dark(
          surface: AppColorsDarkMode.mainColor,
          primary: AppColorsDarkMode.primaryColor,
          secondary: AppColorsDarkMode.secondaryColor,
          onPrimary: AppColorsDarkMode.accentColor,
          onSecondary: AppColorsDarkMode.accentColor,
          onSurface: AppColorsDarkMode.textPrimary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColorsDarkMode.secondaryColor,
          foregroundColor: AppColorsDarkMode.accentColor,
          elevation: 8,
        ),
        iconTheme: const IconThemeData(
          color: AppColorsDarkMode.secondaryColor,
        ),
        primaryIconTheme: const IconThemeData(
          color: AppColorsDarkMode.secondaryColor,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: const TextStyle(color: AppColorsDarkMode.textPrimary),
          bodyMedium: const TextStyle(color: AppColorsDarkMode.textPrimary),
          bodySmall: const TextStyle(color: AppColorsDarkMode.textSecondary),
          headlineLarge: const TextStyle(color: AppColorsDarkMode.textPrimary),
          headlineMedium: const TextStyle(color: AppColorsDarkMode.textPrimary),
          headlineSmall: const TextStyle(color: AppColorsDarkMode.textPrimary),
          titleLarge: const TextStyle(color: AppColorsDarkMode.textPrimary),
          titleMedium: const TextStyle(color: AppColorsDarkMode.textPrimary),
          titleSmall: const TextStyle(color: AppColorsDarkMode.textSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorsDarkMode.mainColor,
          foregroundColor: AppColorsDarkMode.textPrimary,
          iconTheme: IconThemeData(color: AppColorsDarkMode.textPrimary),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColorsDarkMode.mainColor,
          modalBackgroundColor: AppColorsDarkMode.mainColor,
          elevation: 0,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColorsDarkMode.cardColor,
          elevation: 4,
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColorsLightMode.mainColor,
        canvasColor: AppColorsLightMode.mainColor,
        cardColor: AppColorsLightMode.cardColor,
        colorScheme: const ColorScheme.light(
          surface: AppColorsLightMode.mainColor,
          primary: AppColorsLightMode.primaryColor,
          secondary: AppColorsLightMode.secondaryColor,
          onPrimary: AppColorsLightMode.surfaceColor,
          onSecondary: AppColorsLightMode.surfaceColor,
          onSurface: AppColorsLightMode.textPrimary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColorsLightMode.primaryColor,
          foregroundColor: AppColorsLightMode.surfaceColor,
          elevation: 8,
        ),
        iconTheme: const IconThemeData(
          color: AppColorsLightMode.textSecondary,
        ),
        primaryIconTheme: const IconThemeData(
          color: AppColorsLightMode.primaryColor,
        ),
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyLarge: const TextStyle(color: AppColorsLightMode.textPrimary),
          bodyMedium: const TextStyle(color: AppColorsLightMode.textPrimary),
          bodySmall: const TextStyle(color: AppColorsLightMode.textSecondary),
          headlineLarge: const TextStyle(color: AppColorsLightMode.textPrimary),
          headlineMedium: const TextStyle(color: AppColorsLightMode.textPrimary),
          headlineSmall: const TextStyle(color: AppColorsLightMode.textPrimary),
          titleLarge: const TextStyle(color: AppColorsLightMode.textPrimary),
          titleMedium: const TextStyle(color: AppColorsLightMode.textPrimary),
          titleSmall: const TextStyle(color: AppColorsLightMode.textSecondary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorsLightMode.surfaceColor,
          foregroundColor: AppColorsLightMode.textPrimary,
          iconTheme: IconThemeData(color: AppColorsLightMode.textPrimary),
          elevation: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColorsLightMode.surfaceColor,
          modalBackgroundColor: AppColorsLightMode.surfaceColor,
          elevation: 8,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColorsLightMode.surfaceColor,
          elevation: 4,
        ),
      );
    }
  }

  // Get theme name for display
  String get currentThemeName {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.dark:
        return 'Dark Theme';
      case AppThemeMode.system:
        return 'System Theme';
    }
  }

  // Get color theme name for display
  String get currentColorThemeName {
    switch (_currentColorMode) {
      case ColorThemeMode.colorful:
        return 'Colorful';
      case ColorThemeMode.classic:
        return 'Classic';
    }
  }

  // Get theme icon
  IconData get currentThemeIcon {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  // Get color theme icon
  IconData get currentColorThemeIcon {
    switch (_currentColorMode) {
      case ColorThemeMode.colorful:
        return Icons.palette;
      case ColorThemeMode.classic:
        return Icons.style;
    }
  }
}
