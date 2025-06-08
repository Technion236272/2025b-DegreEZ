import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/feedback_notifier.dart';
import 'package:degreez/widgets/text_form_field_WithStyle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedbackButton extends StatefulWidget {
  const FeedbackButton({super.key});

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackNotifier>(
      builder: (context, feedbackNotifier, _) {
        return SizedBox(
          width: double.infinity,
          child:
              feedbackNotifier.isLoading
                  ? LinearProgressIndicator()
                  : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDarkMode.secondaryColor,
                      foregroundColor: AppColorsDarkMode.accentColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await feedbackPopup(context, feedbackNotifier);
                    },
                    icon: Icon(Icons.feedback_rounded,color: AppColorsDarkMode.accentColor,),
                    label: Text('Share Your Feedback'),
                  ),
        );
      },
    );
  }
}

Future<void> feedbackPopup(BuildContext context, FeedbackNotifier notifier) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      notifier.isLoading ? debugPrint('BUG SUCCESS') : debugPrint('BUG FAILED');
      return AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel',style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your feedback'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              String title = titleController.text.trim();
              String description = descriptionController.text.trim();

              await notifier.sendFeedback(
                context: context,
                title: title,
                description: description,
              );

              // Close dialog after successful submission
              if (notifier.status == true) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Submit',style: TextStyle(
                    color: AppColorsDarkMode.secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),),
          ),
        ],
        title: const Text('Send Feedback'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help us improve by sharing your feedback',
                style: TextStyle(fontSize: 14, color: AppColorsDarkMode.secondaryColor),
              ),
              textFormFieldWithStyle(
                label: 'Title',
                controller: titleController,
                example: 'Title for the feedback',
              ),

              textFormFieldWithStyle(
                label: 'Description',
                controller: descriptionController,
                example: 'Enter your feedback here',
                lineNum: 5,
              ),
            ],
          ),
        ),
      );
    },
  );
}
