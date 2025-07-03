import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/feedback_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedbackButton extends StatefulWidget {
  const FeedbackButton({super.key});

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {  @override
  Widget build(BuildContext context) {
    return Consumer2<FeedbackNotifier, ThemeProvider>(
      builder: (context, feedbackNotifier, themeProvider, _) {
        return SizedBox(
          width: double.infinity,
          child:
              feedbackNotifier.isLoading
                  ? LinearProgressIndicator()
                  : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor,
                      foregroundColor: themeProvider.mainColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await feedbackPopup(context, feedbackNotifier);
                    },
                    icon: Icon(Icons.feedback_rounded),
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
    builder: (BuildContext dialogContext) {
      notifier.isLoading ? debugPrint('FEEDBACK SUCCESS') : debugPrint('FEEDBACK FAILED');
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.surfaceColor,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },                child: Text('Cancel', style: TextStyle(
                  color: themeProvider.textSecondary
                )),
              ),
              TextButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
      }
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
    }),
                  ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a title'),
                        backgroundColor: themeProvider.isDarkMode 
                            ? AppColorsDarkMode.errorColor 
                            : AppColorsLightMode.errorColor,
                      ),
                    );
                    return;
                  }

                  if (descriptionController.text.trim().isEmpty) {                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter your feedback'),
                        backgroundColor: themeProvider.isDarkMode 
                            ? AppColorsDarkMode.errorColor 
                            : AppColorsLightMode.errorColor,
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
                  if (notifier.status == true && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text('Submit', style: TextStyle(
                  color: themeProvider.primaryColor,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ],
            title: Text(
              'Send Feedback',
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  Text(
                    'Help us improve by sharing your feedback',
                    style: TextStyle(
                      fontSize: 14, 
                      color: themeProvider.textSecondary
                    ),
                  ),
                  textFormFieldWithStyle(
                    context: dialogContext,
                    label: 'Title',
                    controller: titleController,
                    example: 'Title for the feedback',
                  ),

                  textFormFieldWithStyle(
                    context: dialogContext,
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
    },
  );
}
