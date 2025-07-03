// lib/mixins/modern_design_mixin.dart - Mixin for modern borderless design

import 'package:flutter/material.dart';
import '../color/color_palette.dart';

/// Mixin that provides modern, borderless design helpers
mixin ModernDesignMixin {
  
  /// Returns a borderless container decoration
  BoxDecoration get borderlessContainer => const BoxDecoration(
    // No border radius, no borders - completely seamless
  );

  /// Returns a modern button style without borders
  ButtonStyle get borderlessButtonStyle => ElevatedButton.styleFrom(
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero, // Completely flat
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  /// Returns a modern card style without borders
  Widget borderlessCard({
    required Widget child,
    Color? backgroundColor,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: AppColorsDarkMode.seamlessDecoration(
        backgroundColor: backgroundColor,
        elevation: elevation ?? 1.0,
      ),
      child: child,
    );
  }

  /// Returns a modern list tile without borders
  Widget borderlessListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: AppColorsDarkMode.blendedDecoration(
        backgroundColor: backgroundColor,
      ),
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Returns a completely flat, borderless input decoration
  InputDecoration get borderlessInputDecoration => const InputDecoration(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  /// Returns a modern dialog style without borders
  Widget borderlessDialog({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: AppColorsDarkMode.modernCardDecoration(
        backgroundColor: AppColorsDarkMode.surfaceColor,
      ),
      child: child,
    );
  }

  /// Returns a seamless app bar style
  PreferredSizeWidget borderlessAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: 0, // No shadow
      backgroundColor: AppColorsDarkMode.mainColor,
      shape: null, // Remove any shape/border
    );
  }

  /// Returns a modern floating action button without borders
  Widget borderlessFAB({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: AppColorsDarkMode.seamlessDecoration(
        backgroundColor: backgroundColor ?? AppColorsDarkMode.primaryColor,
        elevation: 2.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
