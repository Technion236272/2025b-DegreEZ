// lib/widgets/ai_import_dialogs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/ai_import_models.dart';

/// Collection of dialog widgets for AI import functionality
/// Separates UI components from business logic
class AiImportDialogs {
    /// Shows the initial AI import dialog with instructions
  static void showAiImportDialog(
    BuildContext context, {
    required VoidCallback onStartImport,
  }) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => AlertDialog(
          backgroundColor: themeProvider.mainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: themeProvider.primaryColor,
                size: 20,
              ),
              Text(
                'AI Grade Sheet Import',
                style: TextStyle(color: themeProvider.textPrimary),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '1. Go to your SAP account and request your grade sheet. (תעודת ציונים)\n'
                  '2. Once its approved you will have a version in english and in hebrew, select the english version of your grade sheet and save it in your drive / phone\n'
                  '3. import it here so the AI can extract course information automatically\n'
                  '4. Review and import the extracted courses',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ensure good lighting and clear text for best results',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onStartImport();
              },
              style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
      }
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
    }),
                  ),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Start Import'),
            ),
          ],
        ),
      ),
    );
  }
  /// Shows the image source selection dialog
  static void showImageSourceDialog(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => AlertDialog(
          backgroundColor: themeProvider.mainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Image Source',
            style: TextStyle(color: themeProvider.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: themeProvider.primaryColor,
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(color: themeProvider.textPrimary),
                ),
                subtitle: Text(
                  'Take a new photo',
                  style: TextStyle(color: themeProvider.textSecondary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onCamera();
                },
              ),
              Divider(color: themeProvider.borderPrimary),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: themeProvider.primaryColor,
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(color: themeProvider.textPrimary),
                ),
                subtitle: Text(
                  'Choose from existing photos',
                  style: TextStyle(color: themeProvider.textSecondary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onGallery();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// Shows the image analysis loading dialog
  static void showAnalysisDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => AlertDialog(
          backgroundColor: themeProvider.mainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: themeProvider.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Analyzing Image...',
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI is extracting course information from your grade sheet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }  /// Shows the results confirmation dialog
  static void showResultsDialog(
    BuildContext context, {
    required ImportSummary result,
    required Function(ImportSummary) onConfirm,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => AlertDialog(
          backgroundColor: themeProvider.mainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Import Results',
            style: TextStyle(color: themeProvider.textPrimary),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(result, themeProvider),
                const SizedBox(height: 16),
                if (result.results.isNotEmpty) ...[
                  Text(
                    'Import Results:',
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: result.results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildCourseCard(result.results[index], themeProvider);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.textSecondary),
              ),
            ),
            if (result.totalSuccess == 0)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(
                  'Try Again',
                  style: TextStyle(color: themeProvider.primaryColor),
                ),
              ),
            if (result.totalSuccess > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm(result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: themeProvider.cardColor,
                ),
                child: Text('Import ${result.totalSuccess} Courses'),
              ),
          ],
        ),      ),
    );
  }

  /// Helper method to build summary section
  static Widget _buildSummarySection(ImportSummary result, ThemeProvider themeProvider) {
    final successColor = themeProvider.isDarkMode ? Colors.green.shade400 : Colors.green.shade600;
    final errorColor = themeProvider.isDarkMode ? Colors.red.shade400 : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.totalSuccess > 0
          ? successColor.withValues(alpha: 0.1)
          : errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.totalSuccess > 0
            ? successColor.withValues(alpha: 0.3)
            : errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.totalSuccess > 0 ? Icons.check_circle : Icons.warning,
            color: result.totalSuccess > 0 ? successColor : errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.totalSuccess > 0
                    ? 'Successfully processed ${result.totalSuccess} courses'
                    : 'No courses could be processed',
                  style: TextStyle(
                    color: result.totalSuccess > 0 ? successColor : errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (result.failed > 0)
                  Text(
                    '${result.failed} items had issues',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /// Helper method to build course cards
  static Widget _buildCourseCard(CourseAdditionResult course, ThemeProvider themeProvider) {
    final successColor = themeProvider.isDarkMode ? Colors.green.shade400 : Colors.green.shade600;
    final errorColor = themeProvider.isDarkMode ? Colors.red.shade400 : Colors.red.shade600;
    final warningColor = themeProvider.isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: course.isSuccess 
            ? successColor.withValues(alpha: 0.3)
            : errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                course.isSuccess ? Icons.check_circle : Icons.error,
                color: course.isSuccess ? successColor : errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.courseName,
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (course.wasUpdated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'UPDATED',
                    style: TextStyle(
                      color: warningColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Course ID: ${course.courseId}',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Semester: ${course.semesterName}',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 12,
            ),
          ),
          if (!course.isSuccess && course.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Error: ${course.errorMessage}',
                style: TextStyle(
                  color: errorColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
