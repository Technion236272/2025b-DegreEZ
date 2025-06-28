import 'package:flutter/material.dart';

/// Enhanced color palette architecture for easy theme switching and maintainability
/// 
/// USAGE GUIDE:
/// 1. Use AppColorsDarkMode.colorName throughout your app (maintains backward compatibility)
/// 2. To switch to a different palette, change the implementation of AppColorsDarkMode
/// 3. All decoration methods are included for consistent styling
/// 4. Color names follow semantic conventions for easy understanding
/// 
/// FUTURE PALETTE CHANGES:
/// - Create a new class implementing the same structure as AppColorsDarkMode
/// - Replace the implementation or add palette switching logic
/// - All app colors will automatically update

class AppColorsDarkMode {
  // =============================================================================
  // MAIN BACKGROUND COLORS - Sophisticated Dark Theme
  // =============================================================================
  // Based on elegant Eerie Black + Payne's Gray + Powder Blue color scheme
  
  /// Primary background - Eerie Black for elegant dark foundation
  static const Color mainColor = Color(0xFF17191B);
  
  /// Secondary surface - Slightly lighter than main, creates subtle layering
  static const Color surfaceColor = Color(0xFF1F2123);
  
  /// Card background - Elevated elements with clear hierarchy
  static const Color cardColor = Color(0xFF242628);
  
  // =============================================================================
  // PRIMARY COLORS - Payne's Gray Accent System
  // =============================================================================
  
  /// Main primary color - Payne's Gray, sophisticated blue accent
  static const Color primaryColor = Color(0xFF1F3D56);
  
  /// Semi-transparent primary for overlays and hover states
  static const Color primaryColorDim = Color(0xAA306780);
  
  /// Light primary - Powder Blue, soft and refined
  static const Color primaryColorLight = Color(0xFFB8C7D6);
  
  // =============================================================================
  // SECONDARY COLORS - Supporting the sophisticated theme
  // =============================================================================
  
  /// Main secondary - Powder Blue for text and UI elements
  static const Color secondaryColor = Color(0xFFB8C7D6);
  
  /// Medium transparency secondary
  static const Color secondaryColorDim = Color(0x99B8C7D6);
  
  /// High opacity secondary for prominent elements
  static const Color secondaryColorDimDD = Color(0xDDB8C7D6);
  
  /// Very subtle secondary for background effects
  static const Color secondaryColorExtremelyDim = Color(0x44B8C7D6);
  
  // =============================================================================
  // ACCENT COLORS - Refined blue tones for highlights and emphasis
  // =============================================================================
  
  /// Main accent - Payne's Gray for buttons and active states
  static const Color accentColor = Color(0xFF306780);
  
  /// Darker accent variations
  static const Color accentColorDark = Color(0xFF25525F);
  static const Color accentColorDarker = Color(0xFF1A3D47);
  
  /// Semi-transparent accent
  static const Color accentColorDim = Color(0xCC306780);
  
  /// Lighter accent variations
  static const Color accentColorLight = Color(0xFF4A8099);
  static const Color accentColorExtremelyDim = Color(0x444A8099);
  
  // =============================================================================
  // TEXT COLORS - Hierarchical text system
  // =============================================================================
  
  /// Primary text - White for main content
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - Muted for supporting content
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  /// Tertiary text - Subtle for hints and labels
  static const Color textTertiary = Color(0xFF808080);
  
  // =============================================================================
  // BORDER AND SHADE COLORS - Refined to complement Eerie Black
  // =============================================================================
  
  /// Primary borders - Harmonious with Eerie Black family
  static const Color borderPrimary = Color(0xFF2C2E30);
  
  /// Secondary borders - More subtle, stays within theme
  static const Color borderSecondary = Color(0xFF212325);
  
  /// Accent borders - Payne's Gray with transparency
  static const Color borderAccent = Color(0x33306780);
  
  /// Soft shadow for subtle depth
  static const Color shadowColor = Color(0x1A000000);
  
  /// Stronger shadow for elevated elements
  static const Color shadowColorStrong = Color(0xAA000000);
  
  // =============================================================================
  // OVERLAY COLORS - For subtle layering effects
  // =============================================================================
  
  /// Light overlay (4% white) for subtle highlights
  static const Color overlayLight = Color(0x0AFFFFFF);
  
  /// Medium overlay (10% white) for hover states
  static const Color overlayMedium = Color(0x1AFFFFFF);
  
  /// Dark overlay (4% black) for subtle shadows
  static const Color overlayDark = Color(0x0A000000);
  
  // =============================================================================
  // DIVIDER COLORS - For subtle content separation
  // =============================================================================
  
  /// Main divider - More subtle than direct secondary color
  static const Color dividerColor = Color(0xFF3A4147);
  
  /// Lighter divider for less prominent separations
  static const Color dividerColorLight = Color(0xFF4A525A);
  
  // =============================================================================
  // STATE COLORS - Semantic colors for different states
  // =============================================================================
  
  /// Error color - Soft red that fits the sophisticated theme
  static const Color errorColor = Color(0xFFE57373);
  
  /// Semi-transparent error
  static const Color errorColorDim = Color(0xCCE57373);
  
  /// Success color - Uses Powder Blue to maintain theme consistency
  static const Color successColor = Color(0xFFB8C7D6);
  
  /// Warning color - Warm yellow that complements the blue palette
  static const Color warningColor = Color(0xFFFFB74D);
  
  /// Bug/debug color - Uses accent color
  static const Color bug = accentColor;  
  // =============================================================================
  // CONVENIENCE DECORATION METHODS - For consistent modern styling
  // =============================================================================
  
  /// Creates a modern borderless decoration for cards and containers
  /// Perfect for the seamless, modern UI aesthetic
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    bool elevated = false,
    bool withBorder = false, // Default false for modern borderless look
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsDarkMode.cardColor,
      borderRadius: BorderRadius.circular(0), // Removed rounded corners for seamless blend
      border: withBorder ? Border.all(
        color: AppColorsDarkMode.borderPrimary,
        width: 0.5,
      ) : null,
      boxShadow: elevated ? [
        BoxShadow(
          color: AppColorsDarkMode.shadowColor,
          blurRadius: 12, // Increased blur for softer shadows
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: AppColorsDarkMode.shadowColorStrong,
          blurRadius: 24, // Larger blur for depth without harsh edges
          offset: const Offset(0, 6),
        ),
      ] : null,
    );
  }
  
  /// Creates a modern borderless surface decoration for elevated elements
  static BoxDecoration surfaceDecoration({
    bool withAccentBorder = false,
  }) {
    return BoxDecoration(
      color: AppColorsDarkMode.surfaceColor,
      borderRadius: BorderRadius.circular(0), // Removed rounded corners
      border: withAccentBorder ? Border.all(
        color: AppColorsDarkMode.borderAccent,
        width: 0, // Removed border width for seamless look
      ) : null,
      boxShadow: [
        BoxShadow(
          color: AppColorsDarkMode.shadowColor,
          blurRadius: 8, // Softer shadow
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  /// Creates a completely seamless decoration with subtle elevation
  static BoxDecoration seamlessDecoration({
    Color? backgroundColor,
    double elevation = 1.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsDarkMode.surfaceColor,
      boxShadow: [
        BoxShadow(
          color: AppColorsDarkMode.shadowColor,
          blurRadius: elevation * 4,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  /// Creates a blended decoration that transitions smoothly with background
  static BoxDecoration blendedDecoration({
    Color? backgroundColor,
    double opacity = 0.8,
  }) {
    int opacityInt = (opacity*255).floor(); 
    return BoxDecoration(
      color: (backgroundColor ?? AppColorsDarkMode.cardColor).withAlpha(opacityInt),
      // No borders, no radius - completely seamless
      boxShadow: [
        BoxShadow(
          color: AppColorsDarkMode.shadowColor.withAlpha(128),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Creates a modern card decoration with very minimal styling
  static BoxDecoration modernCardDecoration({
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsDarkMode.cardColor,
      // Minimal shadow for subtle depth
      boxShadow: [
        BoxShadow(
          color: AppColorsDarkMode.shadowColor.withAlpha(76),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // =============================================================================
  // THEME DOCUMENTATION AND PALETTE CHANGE GUIDE
  // =============================================================================
  
  /// To change the entire app's color palette:
  /// 
  /// METHOD 1 - Direct replacement:
  /// Replace the color values in this class with your new palette
  /// 
  /// METHOD 2 - Multiple palettes:
  /// Create additional classes (e.g., AppColorsLightMode, AppColorsCustom)
  /// with the same structure and switch between them
  /// 
  /// METHOD 3 - Dynamic switching:
  /// Use a provider/service to switch between different palette instances
  /// 
  /// NAMING CONVENTIONS:
  /// - mainColor: Primary background
  /// - surfaceColor: Secondary surfaces
  /// - cardColor: Elevated cards/containers
  /// - primaryColor: Main brand color
  /// - secondaryColor: Supporting colors
  /// - accentColor: Emphasis and highlights
  /// - Suffixes: Dim (transparent), Light/Dark (variants)
    // Previous color scheme kept as reference for easy rollback
  // static const Color secondaryColor = Color(0xFFFCBAAD);
  // static const Color accentColor = Color(0xFF41221C);
  // static const Color errorColor = Color(0xFFA0221C);
}


/// Light theme color palette - mirrors AppColorsDarkMode structure for consistency
/// Based on clean whites, soft grays, and refined accent colors
class AppColorsLightMode {
  // =============================================================================
  // MAIN BACKGROUND COLORS - Clean Light Theme
  // =============================================================================
  
  /// Primary background - Clean white for bright foundation
  static const Color mainColor = Color(0xFFFAFAFA);
  
  /// Secondary surface - Slightly darker for subtle layering
  static const Color surfaceColor = Color(0xFFFFFFFF);
  
  /// Card background - Elevated elements with clear hierarchy
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // =============================================================================
  // PRIMARY COLORS - Light Mode Green Accent System
  // =============================================================================
  
  /// Main primary color - Forest Green for good contrast and natural feel
  static const Color primaryColor = Color(0xFF2E5F41);
  
  /// Semi-transparent primary for overlays
  static const Color primaryColorDim = Color(0xAA2E5F41);
  
  /// Light primary - Soft mint green for backgrounds
  static const Color primaryColorLight = Color(0xFF86EFAC);
  
  // =============================================================================
  // SECONDARY COLORS - Supporting the light theme
  // =============================================================================
  
  /// Main secondary - Dark gray for text and UI elements
  static const Color secondaryColor = Color(0xFF51A768);
  
  /// Medium transparency secondary
  static const Color secondaryColorDim = Color(0x9951A768);
  
  /// High opacity secondary for prominent elements
  static const Color secondaryColorDimDD = Color(0xDD51A768);
  
  /// Very subtle secondary for background effects
  static const Color secondaryColorExtremelyDim = Color(0x4451A768);
  
  // =============================================================================
  // ACCENT COLORS - Light mode green accents for highlights and emphasis
  // =============================================================================
  
  /// Main accent - Emerald green for buttons and active states
// Base color (used as the seed for the tonal palette)
static const Color accentColor = Color(0xFFE1FADA); // Base - very light green

// Darker variations (darker tones from same palette)
static const Color accentColorDark = Color(0xFFB6E2B1);   // Tone ~60
static const Color accentColorDarker = Color(0xFF74C57A); // Tone ~40

// Lighter variant (closer to white)
static const Color accentColorLight = Color(0xFFF4FFF1);  // Tone ~98

// Transparent / dimmed versions
static const Color accentColorDim = Color(0xCCE1FADA);    // 80% opacity
static const Color accentColorExtremelyDim = Color(0x44E1FADA); // 27% opacity


  // =============================================================================
  // TEXT COLORS - Hierarchical text system for light mode
  // =============================================================================
  
  /// Primary text - Very dark gray for main content (darker than before)
  static const Color textPrimary = Color(0xFF0F172A);
  
  /// Secondary text - Dark gray for supporting content (darker than before)
  static const Color textSecondary = Color(0xFF334155);
  
  /// Tertiary text - Medium gray for hints and labels (darker than before)
  static const Color textTertiary = Color(0xFF64748B);
  
  // =============================================================================
  // BORDER AND SHADE COLORS - Light mode borders
  // =============================================================================
  
  /// Primary borders - Light sage green
  static const Color borderPrimary = primaryColor;
  
  /// Secondary borders - Very light mint
  static const Color borderSecondary = Color(0xFFECFDF5);
  
  /// Drawer background - Very light green tint
  static const Color drawerColor = Color(0xFFFAFAFA);
  
  /// Drawer header - Soft green
  static const Color drawerHeaderColor = Color(0xFF86EFAC);
  
  /// Error and warning borders (keep existing)
  static const Color borderError = Color(0xFFFCA5A5);
  static const Color borderWarning = Color(0xFFFDE68A);
  static const Color borderSuccess = Color(0xFFA7F3D0);
  
  // =============================================================================
  // SEMANTIC COLORS - Status indicators for light mode
  // =============================================================================
  
  /// Success states - Green tones
  static const Color successColor = Color(0xFF10B981);
  static const Color successColorLight = Color(0xFFD1FAE5);
  static const Color successColorDark = Color(0xFF047857);
  
  /// Warning states - Amber tones
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningColorLight = Color(0xFFFEF3C7);
  static const Color warningColorDark = Color(0xFFD97706);
  
  /// Error states - Red tones
  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorColorLight = Color(0xFFFEE2E2);
  static const Color errorColorDark = Color(0xFFDC2626);
  
  /// Info states - Green tones (to match theme)
  static const Color infoColor = Color(0xFF10B981);
  static const Color infoColorLight = Color(0xFFD1FAE5);
  static const Color infoColorDark = Color(0xFF1D4ED8);
  
  // =============================================================================
  // SHADOW AND OVERLAY COLORS - Light mode shadows
  // =============================================================================
  
  /// Primary shadow color
  static const Color shadowColor = Color(0xAA000000);
  
  /// Overlay colors for modals and dialogs
  static const Color overlayColor = Color(0x80000000);
  static const Color overlayColorLight = Color(0x40000000);

    static const Color bug = mainColor;  

  
  // =============================================================================
  // DECORATION METHODS - Light mode specific decorations
  // =============================================================================
  
  /// Creates a standard card decoration for light mode
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    double borderRadius = 12.0,
    double elevation = 2.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsLightMode.cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColorsLightMode.borderSecondary,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColorsLightMode.shadowColor,
          blurRadius: elevation * 2,
          offset: Offset(0, elevation / 2),
        ),
      ],
    );
  }
  
  /// Creates an elevated surface decoration
  static BoxDecoration elevatedDecoration({
    Color? backgroundColor,
    double borderRadius = 16.0,
    double elevation = 4.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsLightMode.surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColorsLightMode.shadowColor,
          blurRadius: elevation * 3,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }
  
  /// Creates a subtle border decoration
  static BoxDecoration borderDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 8.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColorsLightMode.surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColorsLightMode.borderPrimary,
        width: 1.0,
      ),
    );
  }
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
  Color topBarBG([bool isDarkMode = false]) => _topBarBG;
  Color topBarText([bool isDarkMode = false]) => _topBarText;
  Color topBarMarkBG([bool isDarkMode = false]) => _topBarMarkBG;
  Color topBarMarkText([bool isDarkMode = false]) => _topBarMarkText;
  
  // Make these theme-aware too
  Color cardFG([bool isDarkMode = false]) => _cardFG;
  Color cardFGdim([bool isDarkMode = false]) => _cardFGdim;

  Color cardBG([String? courseId, bool isDarkMode = false]){
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
  Color topBarBG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.primaryColor // Dark theme: Blue accent
    : AppColorsLightMode.accentColorDarker; // Light theme: Green primary

  @override
  Color topBarText([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textPrimary // Dark theme: White text
    : AppColorsLightMode.textPrimary; // Light theme: White text

  @override
  Color topBarMarkBG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.accentColorLight // Dark theme: Light blue
    : AppColorsLightMode.accentColorLight; // Light theme: Light mint green

  @override
  Color topBarMarkText([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.mainColor // Dark theme: White text
    : AppColorsLightMode.textPrimary; // Light theme: Dark green

  @override
  Color cardBG([String? courseId, bool isDarkMode = false]){
    return isDarkMode 
      ? AppColorsDarkMode.secondaryColor // Dark theme: Same as drawer header background (powder blue)
      : AppColorsLightMode.accentColor; // Light theme: Very light mint green background (current color)
    }

  @override
  Color cardFG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.mainColor // Dark theme: White text for contrast against powder blue
    : AppColorsLightMode.textPrimary; // Light theme: Dark green text

  @override
  Color cardFGdim([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textSecondary // Dark theme: Light gray text for dim contrast
    : AppColorsLightMode.textSecondary.withAlpha(50); // Light theme: Semi-transparent dark green
  
}

class CourseCardColorPalette2 extends CourseCardColorPalette
{
  CourseCardColorPalette2(){
    _id = 2;
  }
  @override
  Color topBarBG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.accentColor // Dark theme: Blue accent
    : AppColorsLightMode.accentColor; // Light theme: Emerald green

  @override
  Color topBarText([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textPrimary // Dark theme: White text
    : AppColorsLightMode.cardColor; // Light theme: White text

  @override
  Color topBarMarkBG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.primaryColorLight // Dark theme: Powder blue
    : AppColorsLightMode.primaryColorLight; // Light theme: Light mint green

  @override
  Color topBarMarkText([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textPrimary // Dark theme: White text
    : AppColorsLightMode.accentColorDark; // Light theme: Dark green

  @override
  Color cardBG([String? courseId, bool isDarkMode = false]){
    return _getCourseColor(courseId!, isDarkMode);
    }

  @override
  Color cardFG([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textPrimary // Dark theme: White text for contrast against powder blue
    : AppColorsLightMode.accentColorDark; // Light theme: Dark green text

  @override
  Color cardFGdim([bool isDarkMode = false]) => isDarkMode 
    ? AppColorsDarkMode.textSecondary // Dark theme: Light gray text for dim contrast
    : AppColorsLightMode.accentColorExtremelyDim; // Light theme: Semi-transparent dark green

  Color _getCourseColor(String courseId, bool isDarkMode) {
    final hash = courseId.hashCode;
    
    // Light mode colors - using theme's light green tones
    final lightColors = [
      AppColorsLightMode.borderSuccess, // Very light mint
      AppColorsLightMode.borderSecondary, // Light green border
      AppColorsLightMode.successColorLight, // Light success color
      AppColorsLightMode.primaryColorLight, // Light primary
      // Additional light theme compatible colors
      const Color(0xFFECFDF5), // Very Light Mint
      const Color(0xFFD1FAE5), // Light Sage Green
      const Color(0xFFBBF7D0), // Soft Mint
      const Color(0xFFA7F3D0), // Light Green
      const Color(0xFF86EFAC), // Mint Green
      const Color(0xFFF0FDF4), // Extremely Light Green
    ];
    
    // Dark mode colors - using variations of the drawer header background color (powder blue)
    final darkColors = [
      AppColorsDarkMode.secondaryColor, // Same as drawer header background (powder blue)
      AppColorsDarkMode.secondaryColorDim, // Semi-transparent powder blue
      AppColorsDarkMode.secondaryColorDimDD, // High opacity powder blue
      AppColorsDarkMode.primaryColorLight, // Light primary (also powder blue)
      // Subtle variations of the powder blue color for visual distinction
      const Color(0xFFADB9C6), // Slightly darker powder blue
      const Color(0xFFC3CDD7), // Slightly lighter powder blue
      const Color(0xFFB0C5D4), // With a hint more blue
      const Color(0xFFBFC9D8), // Lighter variant
      const Color(0xFFA8BDD0), // With more blue tone
      const Color(0xFFB5C4D3), // Balanced variant
    ];
    
    final colors = isDarkMode ? darkColors : lightColors;
    return colors[hash.abs() % colors.length];
  }
}