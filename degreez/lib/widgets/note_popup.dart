import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/student_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool> notePopup(
  BuildContext context,
  StudentCourse course,
  String semesterName,
  String? startNote,
) async {
  final TextEditingController controller = TextEditingController();
  final notifier = context.read<StudentNotifier>();
  debugPrint(
    'Note: startNote:$startNote',
  );
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
        ],
      );
    },
  );

  notifier.updateCourseNote(semesterName, course.courseId, controller.text);

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
