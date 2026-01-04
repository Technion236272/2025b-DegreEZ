import 'package:degreez/providers/feedback_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedbackPopup extends StatefulWidget {
  const FeedbackPopup({super.key});

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
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
    final feedbackNotifier = Provider.of<FeedbackNotifier>(context);

    return AlertDialog(
      backgroundColor: themeProvider.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Send Feedback',
        style: TextStyle(color: themeProvider.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            textFormFieldWithStyle(
              controller: _titleController,
              label: 'Title',
              example: 'What is your feedback about?',
              context: context,
            ),
            const SizedBox(height: 16),
            textFormFieldWithStyle(
              controller: _descriptionController,
              label: 'Description',
              example: 'Tell us your thoughts...',
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
            backgroundColor: themeProvider.successColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: feedbackNotifier.isLoading
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

                  await feedbackNotifier.sendFeedback(
                    context: context,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );
                  
                  if (mounted) Navigator.pop(context);
                },
          child: feedbackNotifier.isLoading
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
