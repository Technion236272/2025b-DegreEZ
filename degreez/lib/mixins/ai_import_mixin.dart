// lib/mixins/ai_import_mixin.dart

import 'package:flutter/material.dart';
import '../services/ai_import_service.dart';
import '../services/diagram_ai_agent.dart';
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
      
      // Process the import using the service
      final summary = await AiImportService.processAiImport(context);
      
      if (summary.totalCourses == 0) {
        // User cancelled or no courses found
        showSnackBar('Import cancelled by user.');
        return;
      }
      
      if (summary.totalSuccess > 0) {
        showSnackBar(
          'Successfully processed ${summary.totalSuccess} courses!',
          isSuccess: true,
        );
        
        // Trigger UI update if callback is provided
        onImportCompleted();
        
        // Show results dialog
        final aiAgent = DiagramAiAgent();
        AiImportDialogs.showImportResultsDialog(context, summary, aiAgent);
      } else {
        showSnackBar('No courses were successfully processed.', isError: true);
        
        // Still show results dialog for failed imports
        final aiAgent = DiagramAiAgent();
        AiImportDialogs.showImportResultsDialog(context, summary, aiAgent);
      }
      
    } catch (e) {
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
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
