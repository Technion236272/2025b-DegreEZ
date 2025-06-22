// lib/widgets/ai_import_dialogs.dart

import 'package:flutter/material.dart';
import '../color/color_palette.dart';
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.smart_toy,
              color: AppColorsDarkMode.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Grade Sheet Import',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Follow these steps to import your grade sheet:',
                style: TextStyle(color: AppColorsDarkMode.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildStep(1, 'Take a photo of your grade sheet or select from gallery'),
              _buildStep(2, 'AI will analyze the image and extract course data'),
              _buildStep(3, 'Review and confirm the detected courses'),
              _buildStep(4, 'Add courses to your study plan'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorsDarkMode.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColorsDarkMode.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ensure good lighting and clear text for best results',
                        style: TextStyle(
                          color: AppColorsDarkMode.primaryColor,
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
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onStartImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.cardColor,
            ),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Start Import'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Image Source',
          style: TextStyle(color: AppColorsDarkMode.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: AppColorsDarkMode.primaryColor,
              ),
              title: Text(
                'Camera',
                style: TextStyle(color: AppColorsDarkMode.textPrimary),
              ),
              subtitle: Text(
                'Take a new photo',
                style: TextStyle(color: AppColorsDarkMode.textSecondary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onCamera();
              },
            ),
            const Divider(color: AppColorsDarkMode.borderPrimary),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: AppColorsDarkMode.primaryColor,
              ),
              title: Text(
                'Gallery',
                style: TextStyle(color: AppColorsDarkMode.textPrimary),
              ),
              subtitle: Text(
                'Choose from existing photos',
                style: TextStyle(color: AppColorsDarkMode.textSecondary),
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
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the image analysis loading dialog
  static void showAnalysisDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: AppColorsDarkMode.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Analyzing Image...',
                style: TextStyle(
                  color: AppColorsDarkMode.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI is extracting course information from your grade sheet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// Shows the results confirmation dialog
  static void showResultsDialog(
    BuildContext context, {
    required ImportSummary result,
    required Function(ImportSummary) onConfirm,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Import Results',
          style: TextStyle(color: AppColorsDarkMode.textPrimary),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummarySection(result),
              const SizedBox(height: 16),
              if (result.results.isNotEmpty) ...[
                Text(
                  'Import Results:',
                  style: TextStyle(
                    color: AppColorsDarkMode.textPrimary,
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
                      return _buildCourseCard(result.results[index]);
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
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
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
                style: TextStyle(color: AppColorsDarkMode.primaryColor),
              ),
            ),
          if (result.totalSuccess > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm(result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsDarkMode.primaryColor,
                foregroundColor: AppColorsDarkMode.cardColor,
              ),
              child: Text('View ${result.totalSuccess} Added'),
            ),
        ],
      ),
    );
  }

  /// Helper method to build step indicators
  static Widget _buildStep(int number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColorsDarkMode.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorsDarkMode.primaryColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: AppColorsDarkMode.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: AppColorsDarkMode.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Helper method to build summary section
  static Widget _buildSummarySection(ImportSummary result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.totalSuccess > 0
          ? AppColorsDarkMode.successColor.withValues(alpha: 0.1)
          : AppColorsDarkMode.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.totalSuccess > 0
            ? AppColorsDarkMode.successColor.withValues(alpha: 0.3)
            : AppColorsDarkMode.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.totalSuccess > 0 ? Icons.check_circle : Icons.warning,
            color: result.totalSuccess > 0
              ? AppColorsDarkMode.successColor 
              : AppColorsDarkMode.errorColor,
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
                    color: result.totalSuccess > 0
                      ? AppColorsDarkMode.successColor 
                      : AppColorsDarkMode.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (result.failed > 0)
                  Text(
                    '${result.failed} items had issues',
                    style: TextStyle(
                      color: AppColorsDarkMode.errorColor,
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
  static Widget _buildCourseCard(CourseAdditionResult course) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: course.isSuccess 
            ? AppColorsDarkMode.successColor.withValues(alpha: 0.3)
            : AppColorsDarkMode.errorColor.withValues(alpha: 0.3),
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
                color: course.isSuccess 
                  ? AppColorsDarkMode.successColor
                  : AppColorsDarkMode.errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.courseName,
                  style: TextStyle(
                    color: AppColorsDarkMode.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (course.wasUpdated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColorsDarkMode.warningColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'UPDATED',
                    style: TextStyle(
                      color: AppColorsDarkMode.warningColor,
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
              color: AppColorsDarkMode.textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Semester: ${course.semesterName}',
            style: TextStyle(
              color: AppColorsDarkMode.textSecondary,
              fontSize: 12,
            ),
          ),
          if (!course.isSuccess && course.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Error: ${course.errorMessage}',
                style: TextStyle(
                  color: AppColorsDarkMode.errorColor,
                  fontSize: 12,
                ),
              ),
            ),        ],
      ),
    );
  }
}
