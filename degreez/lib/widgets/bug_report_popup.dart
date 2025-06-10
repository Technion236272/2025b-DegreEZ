import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BugReportButton extends StatefulWidget {
  const BugReportButton({super.key});

  @override
  State<BugReportButton> createState() => _BugReportButtonState();
}

class _BugReportButtonState extends State<BugReportButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BugReportNotifier>(
      builder: (context, bugReportNotifier, _) {
        return SizedBox(
          width: double.infinity,
          child:
              bugReportNotifier.isLoading
                  ? LinearProgressIndicator()
                  : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDarkMode.secondaryColor,
                      foregroundColor: AppColorsDarkMode.bug,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await bugReportPopup(context, bugReportNotifier);
                    },
                    icon: Icon(Icons.bug_report,color: AppColorsDarkMode.bug,),
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
                    content: Text('Please enter a bug title'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a bug description'),
                    backgroundColor: Colors.red,
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
        title: const Text('Report a Bug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help us improve by reporting bugs you encounter.',
                style: TextStyle(fontSize: 14, color: AppColorsDarkMode.secondaryColor),
              ),
              textFormFieldWithStyle(
                label: 'Bug Title',
                controller: titleController,
                example: 'Brief description of the issue',
              ),

              textFormFieldWithStyle(
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
}
