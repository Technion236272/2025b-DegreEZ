import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';
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
        backgroundColor: AppColorsDarkMode.secondaryColor,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Center(
              child: Text(
                "Note",
                style: TextStyle(color: AppColorsDarkMode.accentColor),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: CustomPaint(
              painter: LinePainter(lineHeight: 30, distanceToBaseline: 10),
              child: TextField(
                controller: controller,
                cursorColor: AppColorsDarkMode.accentColor,
                decoration: InputDecoration(
                  hoverColor: AppColorsDarkMode.accentColor,
                  border: InputBorder.none,
                  hintText: 'type here to add a note ...',
                  hintStyle: TextStyle(color: AppColorsDarkMode.accentColorDim),
                ),
                style: TextStyle(
                  color: AppColorsDarkMode.accentColor,
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
                    style: TextStyle(color: AppColorsDarkMode.accentColor),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsDarkMode.accentColor,
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
                    style: TextStyle(color: AppColorsDarkMode.secondaryColor),
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
