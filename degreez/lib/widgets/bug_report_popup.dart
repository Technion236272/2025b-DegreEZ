import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BugReportButton extends StatefulWidget {
  const BugReportButton({super.key});

  @override
  State<BugReportButton> createState() => _BugReportButtonState();
}

class _BugReportButtonState extends State<BugReportButton> {  @override
  Widget build(BuildContext context) {
    return Consumer2<BugReportNotifier, ThemeProvider>(
      builder: (context, bugReportNotifier, themeProvider, _) {
        return SizedBox(
          width: double.infinity,
          child:
              bugReportNotifier.isLoading
                  ? LinearProgressIndicator()
                  : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor,
                      foregroundColor: themeProvider.isDarkMode 
                        ? AppColorsDarkMode.bug 
                        : AppColorsLightMode.bug,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await bugReportPopup(context, bugReportNotifier);
                    },
                    icon: Icon(Icons.bug_report, color: themeProvider.isDarkMode 
                      ? AppColorsDarkMode.bug 
                      : AppColorsLightMode.bug),
                    label: Text('Report a Bug'),
                  ),
        );
      },
    );
  }
}

Future<void> bugReportPopup(BuildContext context, BugReportNotifier notifier) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      notifier.isLoading ? debugPrint('BUG SUCCESS') : debugPrint('BUG FAILED');
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
                        content: Text('Please enter a bug title'),
                        backgroundColor: themeProvider.isDarkMode 
                            ? AppColorsDarkMode.errorColor 
                            : AppColorsLightMode.errorColor,
                      ),
                    );
                    return;
                  }

                  if (descriptionController.text.trim().isEmpty) {                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a bug description'),
                        backgroundColor: themeProvider.isDarkMode 
                            ? AppColorsDarkMode.errorColor 
                            : AppColorsLightMode.errorColor,
                      ),
                    );
                    return;
                  }

                  String title = titleController.text.trim();
                  String description = descriptionController.text.trim();

                  await notifier.reportBug(
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
              'Report a Bug',
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
                    'Help us improve by reporting bugs you encounter.',
                    style: TextStyle(
                      fontSize: 14, 
                      color: themeProvider.textSecondary
                    ),
                  ),
                  textFormFieldWithStyle(
                    context: dialogContext,
                    label: 'Bug Title',
                    controller: titleController,
                    example: 'Brief description of the issue',
                  ),

                  textFormFieldWithStyle(
                    context: dialogContext,
                    label: 'Description',
                    controller: descriptionController,
                    example: 'Detailed description of the bug...',
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
