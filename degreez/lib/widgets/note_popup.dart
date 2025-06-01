import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool> notePopup(
  BuildContext context,
  StudentCourse course,
  String semesterName,
  String? startNote,
) async {
  final TextEditingController controller = TextEditingController();
  final studentProvider = context.read<StudentProvider>();
  final courseProvider = context.read<CourseProvider>();
  
  debugPrint('Note: startNote:$startNote');
  
  await showDialog(
    context: context,
    builder: (_) {
      controller.text = startNote ?? '';
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
          // Add action buttons
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColorsDarkMode.accentColorDim),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (studentProvider.hasStudent) {
                      await courseProvider.updateCourseNote(
                        studentProvider.student!.id,
                        semesterName,
                        course.courseId,
                        controller.text,
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsDarkMode.accentColor,
                  ),
                  child: Text(
                    'Save',
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

  debugPrint(
    'Note: semesterKey:$semesterName, courseId:${course.courseId}, note:${controller.text}',
  );

  return controller.text.isNotEmpty;
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
    final intialOffset = offsetY + distanceToBaseline;
    for (double y = intialOffset; y < size.height; y = y + lineHeight) {
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
