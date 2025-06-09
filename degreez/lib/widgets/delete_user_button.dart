import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
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
              backgroundColor: AppColorsDarkMode.errorColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final rootNavigator = Navigator.of(context, rootNavigator: true);

              await courseProvider.deleteStudentAndCourses(studentProvider.student!.id);
              await logInNotifier.deleteUser();

              rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: Icon(Icons.delete_forever, color: Colors.white),
            label: Text('Delete User Permanently'),
          ),
        );
      },
    );
  }
}