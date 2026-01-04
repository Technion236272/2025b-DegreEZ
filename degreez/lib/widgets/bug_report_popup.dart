import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BugReportPopup extends StatefulWidget {
  const BugReportPopup({super.key});

  @override
  State<BugReportPopup> createState() => _BugReportPopupState();
}

class _BugReportPopupState extends State<BugReportPopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bugReportNotifier = Provider.of<BugReportNotifier>(context);

    return AlertDialog(
      backgroundColor: themeProvider.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Report a Bug',
        style: TextStyle(color: themeProvider.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            textFormFieldWithStyle(
              controller: _titleController,
              label: 'Title',
              example: 'Brief description of the issue',
              context: context,
            ),
            const SizedBox(height: 16),
            textFormFieldWithStyle(
              controller: _descriptionController,
              label: 'Description',
              example: 'Please describe what happened...',
              lineNum: 5,
              context: context,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: themeProvider.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: bugReportNotifier.isLoading
              ? null
              : () async {
                  if (_titleController.text.trim().isEmpty ||
                      _descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please fill in all fields'),
                        backgroundColor: themeProvider.errorColor,
                      ),
                    );
                    return;
                  }

                  await bugReportNotifier.reportBug(
                    context: context,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );
                  
                  if (mounted) Navigator.pop(context);
                },
          child: bugReportNotifier.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
