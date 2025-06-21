// lib/widgets/ai_import_dialogs.dart

import 'package:flutter/material.dart';
import '../color/color_palette.dart';
import '../models/ai_import_models.dart';
import '../services/diagram_ai_agent.dart';

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
        backgroundColor: AppColorsDarkMode.cardColor,
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
                'Import your courses automatically from a grade sheet or transcript PDF.',
                style: TextStyle(color: AppColorsDarkMode.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorsDarkMode.borderPrimary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        color: AppColorsDarkMode.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Select a PDF grade sheet or transcript\n'
                      '2. AI extracts course information automatically\n'
                      '3. Review and import the extracted courses',
                      style: TextStyle(
                        color: AppColorsDarkMode.textSecondary,
                        fontSize: 12,
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStartImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('Start Import'),
          ),
        ],
      ),
    );
  }

  /// Shows the import results dialog with summary and detailed results
  static void showImportResultsDialog(
    BuildContext context,
    ImportSummary summary,
    DiagramAiAgent aiAgent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              summary.totalSuccess > 0 ? Icons.check_circle : Icons.warning,
              color: summary.totalSuccess > 0 
                  ? AppColorsDarkMode.successColor 
                  : AppColorsDarkMode.warningColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Import Results',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Statistics
              _buildSummarySection(summary),
              const SizedBox(height: 16),
              
              // Course Results List
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColorsDarkMode.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detailed Results:',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildResultsBySemester(summary.results),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          if (summary.failed > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showFailedCoursesDialog(
                  context,
                  summary.results.where((r) => !r.isSuccess).toList(),
                  summary,
                  aiAgent,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsDarkMode.primaryColor,
                foregroundColor: AppColorsDarkMode.textPrimary,
              ),
              child: const Text('Review Failed'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showRawJsonDialog(context, aiAgent, summary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.surfaceColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('View Raw Data'),
          ),
        ],
      ),
    );
  }

  /// Shows detailed failed courses dialog
  static void showFailedCoursesDialog(
    BuildContext context,
    List<CourseAdditionResult> failedResults,
    ImportSummary summary,
    DiagramAiAgent aiAgent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColorsDarkMode.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Failed Courses (${failedResults.length})',
                  style: TextStyle(color: AppColorsDarkMode.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildBreadcrumb(['Import Results', 'Failed Courses']),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following courses could not be imported:',
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: failedResults.map((result) => 
                      _buildFailedCourseCard(result)
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showImportResultsDialog(context, summary, aiAgent);
            },
            icon: Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColorsDarkMode.textPrimary,
            ),
            label: Text(
              'Back to Summary',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows raw JSON data dialog
  static void showRawJsonDialog(
    BuildContext context,
    DiagramAiAgent aiAgent,
    ImportSummary summary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: AppColorsDarkMode.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extracted JSON Data',
                  style: TextStyle(color: AppColorsDarkMode.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildBreadcrumb(['Import Results', 'Raw Data']),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
          child: Container(
            decoration: BoxDecoration(
              color: AppColorsDarkMode.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColorsDarkMode.borderPrimary),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                aiAgent.exportAsJson(),
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showImportResultsDialog(context, summary, aiAgent);
            },
            icon: Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColorsDarkMode.textPrimary,
            ),
            label: Text(
              'Back to Summary',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Private helper methods

  static Widget _buildSummarySection(ImportSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorsDarkMode.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColorsDarkMode.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Import Summary',
                style: TextStyle(
                  color: AppColorsDarkMode.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip('Total Courses', summary.totalCourses.toString(), AppColorsDarkMode.primaryColor),
              const SizedBox(width: 8),
              _buildSummaryChip('Added', summary.successfullyAdded.toString(), AppColorsDarkMode.successColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryChip('Updated', summary.successfullyUpdated.toString(), AppColorsDarkMode.warningColor),
              const SizedBox(width: 8),
              _buildSummaryChip('Failed', summary.failed.toString(), AppColorsDarkMode.errorColor),
            ],
          ),
          if (summary.semestersAdded > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryChip('New Semesters', summary.semestersAdded.toString(), AppColorsDarkMode.secondaryColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBreadcrumb(List<String> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) Icon(
            Icons.chevron_right,
            color: AppColorsDarkMode.textSecondary,
            size: 16,
          ),
          Text(
            items[i],
            style: TextStyle(
              color: AppColorsDarkMode.textSecondary,
              fontSize: 12,
              fontWeight: i == items.length - 1 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  static Widget _buildFailedCourseCard(CourseAdditionResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorsDarkMode.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppColorsDarkMode.errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.courseId}: ${result.courseName}',
                  style: TextStyle(
                    color: AppColorsDarkMode.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColorsDarkMode.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                result.semesterName,
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (result.errorMessage != null && result.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.surfaceColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColorsDarkMode.warningColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      result.errorMessage!,
                      style: TextStyle(
                        color: AppColorsDarkMode.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<Widget> _buildResultsBySemester(List<CourseAdditionResult> results) {
    final Map<String, List<CourseAdditionResult>> resultsBySemester = {};
    
    for (final result in results) {
      resultsBySemester.putIfAbsent(result.semesterName, () => []);
      resultsBySemester[result.semesterName]!.add(result);
    }

    // Sort semesters chronologically by year and season
    final sortedEntries = _sortSemestersByYear(resultsBySemester);

    return sortedEntries.map((entry) {
      final semesterName = entry.key;
      final semesterResults = entry.value;
      final successCount = semesterResults.where((r) => r.isSuccess).length;
      final failedCount = semesterResults.length - successCount;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorsDarkMode.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorsDarkMode.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColorsDarkMode.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semesterName,
                        style: TextStyle(
                          color: AppColorsDarkMode.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${semesterResults.length} course${semesterResults.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColorsDarkMode.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (successCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$successCount ✓',
                      style: TextStyle(
                        color: AppColorsDarkMode.successColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (failedCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$failedCount ✗',
                      style: TextStyle(
                        color: AppColorsDarkMode.errorColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...semesterResults.map((result) => _buildCourseResultCard(result)),
          ],
        ),
      );
    }).toList();
  }

  static Widget _buildCourseResultCard(CourseAdditionResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: result.isSuccess 
            ? AppColorsDarkMode.successColor.withOpacity(0.1)
            : AppColorsDarkMode.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: result.isSuccess 
              ? AppColorsDarkMode.successColor.withOpacity(0.3)
              : AppColorsDarkMode.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.error,
            color: result.isSuccess ? AppColorsDarkMode.successColor : AppColorsDarkMode.errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.courseId}: ${result.courseName}',
                  style: TextStyle(
                    color: AppColorsDarkMode.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (result.errorMessage != null && result.errorMessage!.isNotEmpty)
                  Text(
                    result.errorMessage!,
                    style: TextStyle(
                      color: result.isSuccess 
                          ? AppColorsDarkMode.textSecondary
                          : AppColorsDarkMode.errorColor,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (result.wasUpdated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Updated',
                style: TextStyle(
                  color: AppColorsDarkMode.warningColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (result.isSuccess)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Added',
                style: TextStyle(
                  color: AppColorsDarkMode.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<MapEntry<String, List<CourseAdditionResult>>> _sortSemestersByYear(
    Map<String, List<CourseAdditionResult>> resultsBySemester
  ) {
    final entries = resultsBySemester.entries.toList();
    
    entries.sort((a, b) {
      final semesterA = a.key;
      final semesterB = b.key;
      
      // Extract year and season from semester name (e.g., "Winter 2023-2024", "Spring 2024")
      final partsA = semesterA.split(' ');
      final partsB = semesterB.split(' ');
      
      if (partsA.length < 2 || partsB.length < 2) return 0;
      
      final seasonA = partsA[0];
      final yearStrA = partsA[1];
      final seasonB = partsB[0];
      final yearStrB = partsB[1];
      
      // Extract year for comparison
      int yearA, yearB;
      
      if (yearStrA.contains('-')) {
        // Winter format: "2023-2024" -> use the second year (2024)
        yearA = int.tryParse(yearStrA.split('-').last) ?? 0;
      } else {
        // Spring/Summer format: "2024" -> use as is
        yearA = int.tryParse(yearStrA) ?? 0;
      }
      
      if (yearStrB.contains('-')) {
        yearB = int.tryParse(yearStrB.split('-').last) ?? 0;
      } else {
        yearB = int.tryParse(yearStrB) ?? 0;
      }
      
      // Compare by year first
      if (yearA != yearB) {
        return yearA.compareTo(yearB);
      }
      
      // If same year, compare by season order: Winter -> Spring -> Summer
      final seasonOrder = {'Winter': 1, 'Spring': 2, 'Summer': 3};
      final orderA = seasonOrder[seasonA] ?? 4;
      final orderB = seasonOrder[seasonB] ?? 4;
      
      return orderA.compareTo(orderB);
    });
    
    return entries;
  }
}
