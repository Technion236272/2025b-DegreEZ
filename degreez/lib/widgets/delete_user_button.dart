import 'package:degreez/pages/deleting_account_page.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteUserButton extends StatefulWidget {
  const DeleteUserButton({super.key});

  @override
  State<DeleteUserButton> createState() => _DeleteUserButtonState();
}

class _DeleteUserButtonState extends State<DeleteUserButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<CourseProvider, LogInNotifier,StudentProvider>(
      builder: (context, courseProvider, logInNotifier,studentProvider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.read<ThemeProvider>().errorColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {confirmationPopUp();},
            icon: Icon(Icons.delete_forever, color: Colors.white),
            label: Text('Delete Account Permanently'),
          ),
        );
      },
    );
  }

  confirmationPopUp(){
    return showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Are you sure?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.read<ThemeProvider>().errorColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'This action cannot be undone.\n\n'
            'If you proceed, your account will be permanently deleted along with all associated data.',
            style: TextStyle(
              fontSize: 14,
              color: context.read<ThemeProvider>().textPrimary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cancel and close the dialog
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.read<ThemeProvider>().secondaryColor,
              ),
            ),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
            onPressed: () async {
              Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DeletingAccountPage(),
    ));
              final rootNavigator = Navigator.of(context, rootNavigator: true);

              await context.read<CourseProvider>().deleteStudentAndCourses(context.read<StudentProvider>().student!.id);

              await context.read<LogInNotifier>().deleteUser();

              rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
  }
}