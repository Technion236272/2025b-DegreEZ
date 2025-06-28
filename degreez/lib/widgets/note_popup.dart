import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool> notePopup(
  BuildContext context,
  StudentCourse course,
  String semesterName,
  String? startNote,
  VoidCallback? onCourseUpdated,
) async {
  final controller = TextEditingController(text: startNote ?? '');
  final notifierStudent = context.read<StudentProvider>();
  final notifierCourse = context.read<CourseProvider>();
  debugPrint('Note: startNote:$startNote');

  await showDialog(
    context: context,
    builder: (_) {
      //controller.text = startNote ?? '';
      return SimpleDialog(
        backgroundColor: context.read<ThemeProvider>().accentColor,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                "Note",
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: CustomPaint(
              painter: LinePainter(lineHeight: 30, distanceToBaseline: 10),
              child: TextField(
                controller: controller,
                cursorColor: context.read<ThemeProvider>().textPrimary,
                decoration: InputDecoration(
                  hoverColor: context.read<ThemeProvider>().textPrimary,
                  border: InputBorder.none,
                  hintText: 'type here to add a note ...',
                  hintStyle: TextStyle(color: context.read<ThemeProvider>().textPrimary.withAlpha(200)),
                ),
                style: TextStyle(
                  color: context.read<ThemeProvider>().textPrimary,
                  fontSize: 18,
                ),
                maxLines: 10,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: context.read<ThemeProvider>().primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeProvider>().primaryColor,
                  ),
                  onPressed: () async {
                    final studentProvider = Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    );
                    final studentId = studentProvider.student!.id;

                    await Provider.of<CourseProvider>(
                      context,
                      listen: false,
                    ).updateCourseNote(
                      studentId,
                      semesterName,
                      course.courseId,
                      controller.text,
                    );
                    if (onCourseUpdated != null) {
                      onCourseUpdated(); // ✅ refresh immediately before closing
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(color: context.read<ThemeProvider>().mainColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  notifierCourse.updateCourseNote(
    notifierStudent.student!.id,
    semesterName,
    course.courseId,
    controller.text,
  );

  course.note = controller.text;

  debugPrint(
    'Note: semesterKey:$semesterName, courseId:${course.courseId}, note:${controller.text});',
  );

  return controller.text != '';
}

class LinePainter extends CustomPainter {
  final double distanceToBaseline;
  final double lineHeight;

  /// If your `TextField` has any content-padding,
  /// the top value will need to be added here
  final double offsetY;

  LinePainter({
    required this.distanceToBaseline,
    required this.lineHeight,
    this.offsetY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColorsDarkMode.accentColor;
    final initialOffset = offsetY + distanceToBaseline;
    for (double y = initialOffset; y < size.height; y = y + lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    if (oldDelegate.distanceToBaseline != distanceToBaseline ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.offsetY != offsetY) {
      return true;
    }

    return false;
  }
}
