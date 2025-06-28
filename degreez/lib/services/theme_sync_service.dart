// lib/services/theme_sync_service.dart - Service to sync theme preferences

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';

class ThemeSyncService {
  /// Sync student's theme preference with the theme provider when they log in
  static Future<void> syncStudentThemePreference(BuildContext context) async {
    try {
      final studentProvider = context.read<StudentProvider>();
      final themeProvider = context.read<ThemeProvider>();
      
      if (studentProvider.hasStudent) {
        await studentProvider.loadAndApplyThemePreference(themeProvider);
      }
    } catch (e) {
      debugPrint('Error syncing student theme preference: $e');
    }
  }
  
  /// Update student's theme preference when they change it in the app
  static Future<void> updateStudentThemePreference(
    BuildContext context,
    AppThemeMode themeMode,
  ) async {
    try {
      final studentProvider = context.read<StudentProvider>();
      
      if (studentProvider.hasStudent) {
        final student = studentProvider.student!;
        await studentProvider.updateStudentProfile(
          name: student.name,
          major: student.major,
          preferences: student.preferences,
          faculty: student.faculty,
          catalog: student.catalog,
          semester: student.semester,
          themeMode: themeMode.name,
        );
      }
    } catch (e) {
      debugPrint('Error updating student theme preference: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }
}
