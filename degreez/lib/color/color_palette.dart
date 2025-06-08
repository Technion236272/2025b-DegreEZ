import 'package:flutter/material.dart';

class AppColorsDarkMode {
  // Main background colors - inspired by the dark theme in the image
  static const Color mainColor = Color(0xFF121212); // Rich dark background
  static const Color surfaceColor = Color(0xFF1E1E1E); // Card/surface background
  static const Color cardColor = Color(0xFF2A2A2A); // Elevated card background
  
  // Primary orange/coral accent - main brand color from the image
  static const Color primaryColor = Color(0xFFFF6B35); // Vibrant orange accent
  static const Color primaryColorDim = Color(0xAAFF6B35); // Semi-transparent primary
  static const Color primaryColorLight = Color(0xFFFF8A65); // Lighter variant
  
  // Secondary warm colors - supporting the orange theme
  static const Color secondaryColor = Color(0xFFFFAB91); // Warm peach
  static const Color secondaryColorDim = Color(0x99FFAB91);
  static const Color secondaryColorDimDD = Color(0xDDFFAB91);
  static const Color secondaryColorExtremelyDim = Color(0x44FFAB91);
  
  // Accent colors - darker warm tones
  static const Color accentColor = Color(0xFF3E2723); // Deep brown
  static const Color accentColorDark = Color(0xFF2D1C1C); // Deep brown
  static const Color accentColorDarker = Color(0xFF4F3834); // Deep brown
  static const Color accentColorDim = Color(0xCC3E2723);
  static const Color accentColorLight = Color(0xFF5D4037); // Medium brown
  static const Color accentColorExtremelyDim = Color(0x445D4037); // Medium brown
    // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFFB0B0B0); // Muted text
  static const Color textTertiary = Color(0xFF808080); // Subtle text
  
  // Border and shade colors - inspired by the subtle borders in the design
  static const Color borderPrimary = Color(0xFF3A3A3A); // Subtle border for cards
  static const Color borderSecondary = Color(0xFF2F2F2F); // Even more subtle border
  static const Color borderAccent = Color(0x33FF6B35); // Orange border with transparency
  static const Color shadowColor = Color(0x1A000000); // Soft shadow
  static const Color shadowColorStrong = Color(0xAA000000); // Stronger shadow for elevated elements
  
  // Overlay colors for subtle effects
  static const Color overlayLight = Color(0x0AFFFFFF); // Light overlay (4% white)
  static const Color overlayMedium = Color(0x1AFFFFFF); // Medium overlay (10% white)
  static const Color overlayDark = Color(0x0A000000); // Dark overlay (4% black)
  
  // Divider colors for subtle separation
  static const Color dividerColor = secondaryColor; // Subtle divider
  static const Color dividerColorLight = Color(0xFF404040); // Slightly lighter divider
  
  // State colors
  static const Color errorColor = Color(0xFFE57373); // Soft red error
  static const Color errorColorDim = Color(0xCCE57373);
  static const Color successColor = Color(0xFF81C784); // Soft green success
  static const Color warningColor = Color(0xFFFFB74D); // Warm warning yellow
  
  static const Color bug = accentColor; // Warm warning yellow
  // Convenience methods for creating subtle effects like in the design image
  
  /// Creates a subtle border decoration for cards and containers
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    bool elevated = false,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardColor,
      borderRadius: BorderRadius.circular(12),
      border: withBorder ? Border.all(
        color: borderPrimary,
        width: 0.5,
      ) : null,
      boxShadow: elevated ? [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: shadowColorStrong,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ] : null,
    );
  }
  
  /// Creates a subtle surface decoration for elevated elements
  static BoxDecoration surfaceDecoration({
    bool withAccentBorder = false,
  }) {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: withAccentBorder ? borderAccent : borderSecondary,
        width: withAccentBorder ? 1.0 : 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // Previous color scheme - kept as backup
  // static const Color secondaryColor = Color(0xFFFCBAAD);
  // static const Color secondaryColorDim = Color(0xAAFCBAAD);
  // static const Color secondaryColorDimDD = Color(0xDDFCBAAD);
  // static const Color accentColor = Color(0xFF41221C);
  // static const Color accentColorDim = Color(0xCC41221C);
  // static const Color errorColor = Color(0xFFA0221C);
  // static const Color errorColorDim = Color(0xCCA0221C);
}


class CourseCardColorPalette{
  int? _id;
  final Color _topBarBG = Colors.black;
  final Color _topBarText = Colors.black;
  final Color _topBarMarkBG = Colors.black;
  final Color _topBarMarkText = Colors.black;
  final Color _cardFG = Colors.black;
  final Color _cardFGdim = Colors.black;
  final Color _cardBG = Colors.black;
  
  get id => _id;
  get topBarBG => _topBarBG;
  get topBarText => _topBarText;
  get topBarMarkBG => _topBarMarkBG;
  get topBarMarkText => _topBarMarkText;
  get cardFG => _cardFG;
  get cardFGdim => _cardFGdim;

  Color cardBG([String? courseId]){
    return _cardBG;
    }

  CourseCardColorPalette(){
    _id = 0;
  }
}


class CourseCardColorPalette1 extends CourseCardColorPalette
{
  CourseCardColorPalette1(){
    _id = 1;
  }
  @override
  get topBarBG => AppColorsDarkMode.accentColor;

  @override
  get topBarText => AppColorsDarkMode.secondaryColor;

  @override
  get topBarMarkBG => AppColorsDarkMode.secondaryColorDimDD;

  @override
  get topBarMarkText => AppColorsDarkMode.accentColor;

  @override
  Color cardBG([String? courseId]){
    return AppColorsDarkMode.secondaryColor;
    }

  @override
  get cardFG => AppColorsDarkMode.accentColor;
  
  @override
  get cardFGdim => Color(0x4441221C);
  
}

class CourseCardColorPalette2 extends CourseCardColorPalette
{
  CourseCardColorPalette2(){
    _id = 2;
  }
  @override
  get topBarBG => AppColorsDarkMode.accentColorDim;

  @override
  get topBarText => AppColorsDarkMode.secondaryColor;

  @override
  get topBarMarkBG => AppColorsDarkMode.secondaryColorDimDD;

  @override
  get topBarMarkText => AppColorsDarkMode.accentColor;

  @override
  Color cardBG([String? courseId]){
    return _getCourseColor(courseId!);
    }

  @override
  get cardFG => AppColorsDarkMode.secondaryColor;

   @override
  get cardFGdim => Color(0x44FCBAAD);
  

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      const Color(0xFFFF6B35), // Primary orange
      const Color(0xFFFF8A65), // Light orange
      const Color(0xFFFFAB40), // Amber orange
      const Color(0xFFFF7043), // Deep orange
      // const Color(0xFFBF360C), // Dark orange
      const Color(0xFF8D6E63), // Brown
      const Color(0xFF6D4C41), // Dark brown
      const Color(0xFF5D4037), // Deep brown
      const Color(0xFF4E342E), // Very dark brown
      const Color(0xFF795548), // Medium brown
      const Color(0xFFA1887F), // Light brown
      const Color(0xFFD7CCC8), // Very light brown
      const Color(0xFFFFE0B2), // Light amber
      const Color(0xFFFFCC02), // Warm yellow
      const Color(0xFFFFA726), // Orange amber
      const Color(0xFFFF9800), // Standard orange
      const Color(0xFFFF5722), // Vivid orange
      const Color(0xFFFFC107), // Bright yellow
      const Color(0xFFFFE082), // Light yellow
      const Color(0xFFFFF176), // Pale yellow
      const Color(0xFFFFF9C4), // Very light yellow
      const Color(0xFFFFF3E0), // Creamy white
      const Color(0xFFFFF8E1), // Light cream
      const Color(0xFFFFFDE7), // Very light cream
      const Color(0xFFFFF9C4), // Pale cream
    ];
    return colors[hash.abs() % colors.length];
  }
}