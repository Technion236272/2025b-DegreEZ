// lib/mixins/ai_import_mixin.dart

import 'package:flutter/material.dart';
import '../services/ai_import_service.dart';
import '../widgets/ai_import_dialogs.dart';

/// Mixin to provide AI import functionality to any StatefulWidget
/// This separates the AI import logic from the main page logic
mixin AiImportMixin<T extends StatefulWidget> on State<T> {
  
  /// Shows the AI import dialog and handles the complete import process
  void showAiImportDialog() {
    AiImportDialogs.showAiImportDialog(
      context,
      onStartImport: startAiImport,
    );
  }

  /// Starts the AI import process
  void startAiImport() async {
    try {
      showSnackBar('Starting AI grade sheet import...', isLoading: true);
      // Show visual loading dialog
      AiImportDialogs.showAnalysisDialog(context);
      
      // Process the import using the service
      final summary = await AiImportService.processAiImport(context);
      
      // Debug: Print summary details
      print('AI Import Summary: \u001b[38;5;10m${summary.toString()}\u001b[0m');
      print('Total courses: ${summary.totalCourses}');
      print('Total success: ${summary.totalSuccess}');
      print('Successfully added: ${summary.successfullyAdded}');
      print('Successfully updated: ${summary.successfullyUpdated}');
      print('Failed: ${summary.failed}');
      print('Results count: ${summary.results.length}');
      
      // Close the loading dialog if still mounted
      if (mounted) Navigator.of(context).pop();
      
      if (summary.totalCourses == 0) {
        // User cancelled or no courses found
        showSnackBar('Import cancelled by user.');
        return;
      }
      
      // Always show the results dialog if we have any courses processed
      if (summary.totalCourses > 0) {
        if (summary.totalSuccess > 0) {
          showSnackBar(
            'Successfully processed ${summary.totalSuccess} courses!',
            isSuccess: true,
          );
          // Trigger UI update if callback is provided
          onImportCompleted();
        } else {
          showSnackBar('No courses were successfully processed.', isError: true);
        }
        
        // Show results dialog for any import attempt
        if (mounted) {
          print('Showing results dialog...');
          print('Context valid: \u001b[38;5;10m${context.mounted}\u001b[0m');
          print('Widget mounted: $mounted');
          
          // Add a small delay to ensure the context is ready
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted && context.mounted) {
            try {
              // Show the modern, scrollable results dialog
              AiImportDialogs.showModernResultsDialog(
                context,
                result: summary,
                onOk: () {
                  showSnackBar('Results acknowledged.', isSuccess: true);
                },
              );
              print('Modern dialog showed successfully');
            } catch (e) {
              print('Error showing dialog: $e');
              showSnackBar('Error showing results dialog: $e', isError: true);
            }
          } else {
            print('Context or widget no longer valid after delay');
          }
        } else {
          print('Cannot show dialog: widget not mounted');
        }
      }
      
    } catch (e) {
      print('Error during AI import: ${e.toString()}');
      showSnackBar('Error during AI import: ${e.toString()}', isError: true);
    }
  }

  /// Called when import is completed successfully
  /// Override this method in your widget to handle post-import actions
  void onImportCompleted() {
    // Default implementation - can be overridden
    if (mounted) {
      setState(() {
        // Trigger UI refresh
      });
    }
  }

  /// Shows a snackbar with different styles based on context
  void showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isLoading = false,
  }) {
    if (!mounted) return;

    Color backgroundColor;
    Color textColor = Colors.white;
    IconData? icon;

    if (isError) {
      backgroundColor = Colors.red;
      icon = Icons.error;
    } else if (isSuccess) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isLoading) {
      backgroundColor = Colors.blue;
      icon = Icons.hourglass_empty;
    } else {
      backgroundColor = Colors.grey[800]!;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message, style: TextStyle(color: textColor))),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isLoading ? 2 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
