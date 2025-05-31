import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/widgets/grade_sticker.dart';
import 'package:degreez/widgets/note_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';
import '../services/course_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

enum DirectionValues { horizontal, vertical }

class CourseCard extends StatefulWidget {
  final DirectionValues direction;
  final StudentCourse course;
  final EnhancedCourseDetails? courseDetails;
  final String semester;

  const CourseCard({
    super.key,
    required this.direction,
    required this.course,
    required this.semester,
    this.courseDetails,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _hasNote = false;

  @override
  Widget build(BuildContext context) {
    return (widget.direction == DirectionValues.vertical)
        ? _buildVertical(context, widget.course, widget.courseDetails)
        : _buildHorizontal(context, widget.course, widget.courseDetails);
  }

  Widget _buildVertical(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails
  ) {
    if (widget.course.note != '')
    {
      setState(() {
        _hasNote = true;
      });
    }
    
    final hasGrade = course.finalGrade.isNotEmpty;
    debugPrint(
      'Note: fetchedStartNote:${course.note}',
      );

    return GestureDetector(
      onLongPress: () async {
        final result = await notePopup(context,
        course,
        widget.semester,
        course.note);
        if (result) {
      setState(() {
        _hasNote = true;
      });
      }
      },
      
      child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // color: provider.cardColorPalette!.cardBG(course.courseId),
      color:  context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardBG(course.courseId),
      child: Column(
        children: [
          //Card Top Bar (Course number and points)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity, // ✅ full width
              decoration: BoxDecoration(
                color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.topBarBG,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 7, // 30%
                    child: Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Text(
                        course.courseId,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.topBarText,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  if (courseDetails != null && courseDetails.points.isNotEmpty)
                    Expanded(
                      flex: 3, // 30%
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.topBarMarkBG,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 2, // 30%
                                child: Icon(
                                  Icons.school,
                                  size: 8,
                                  color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.topBarMarkText,
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Text(
                                  courseDetails.points.contains(".")?courseDetails.points:"${courseDetails.points}.0",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.topBarMarkText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ), // Replace with your widget
                    ),
                ],
              ),
            ),
          ),
          //Card Middle (Course name)
          Expanded(
            flex: 6,
            child: Container(
              padding: EdgeInsets.only(right: 3,left: 1,top: 3,bottom: 2),
              width: double.infinity,
              child: AutoSizeText(
              maxLines: 3,
              minFontSize: 7,
              textDirection:TextDirection.rtl,
              course.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG,
                
              ),
            ),
            ),
          ),
          //Card Bottom (Icons Tray)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              width: double.infinity,
              child: Padding(padding: EdgeInsets.only(right: 1,left: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                hasGrade ? GradeSticker(grade: course.finalGrade) 
                : Icon(Icons.work_off_outlined, color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardBG(course.courseId),size: 18,),
                
                _hasNote ?
                Icon(Icons.edit_note_rounded,
                color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG,
                size: 18,)
                : Icon(Icons.edit_note_rounded,
                color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFGdim,
                size: 18,),

                  if(hasGrade)...[
               (double.tryParse(course.finalGrade)! > 55)
                 ? Icon(Icons.check_rounded, color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG,size: 18)
                 : Icon(Icons.clear, color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG,size: 18,),
                 ]
                 else Icon(Icons.work_off_outlined, color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardBG(course.courseId),size: 18,),
                 
                // NotePopupButton(),
                
                ]
              ),)
            ),
          ),
          SizedBox(height: 2,)
        ],
      ),
    ),);
  }

  // Horizontal course card for landscape mode
  Widget _buildHorizontal(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails,
  ) {
    final hasGrade = course.finalGrade.isNotEmpty;
    final courseColor = _getCourseColor(course.courseId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: courseColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    course.courseId,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (courseDetails != null && courseDetails.points.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      courseDetails.points,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasGrade)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getGradeColor(course.finalGrade),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.finalGrade,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.teal.shade900, // Dark greenish blue
      Colors.indigo.shade900, // Deep bluish purple
      Colors.cyan.shade900, // Rich green-blue — bright pop
      Colors.deepPurple.shade900, // Bold, regal purple
      Colors.blue.shade900, // Classic dark blue
      Colors.orange.shade900, // Dark, warm orange — still different from brown
      Colors.red.shade900, // Blood red — intense but clearly distinct
      Colors.lime.shade900, // Sharp and vivid green-yellow
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getGradeColor(String grade) {
    final numericGrade = int.tryParse(grade);
    if (numericGrade != null) {
      if (numericGrade >= 90) return Colors.green.shade600;
      if (numericGrade >= 80) return Colors.blue.shade600;
      if (numericGrade >= 70) return Colors.orange.shade600;
      if (numericGrade >= 60) return Colors.red.shade600;
      return Colors.grey.shade600;
    }

    // Handle non-numeric grades
    switch (grade.toLowerCase()) {
      case 'pass':
      case 'p':
        return Colors.green.shade600;
      case 'fail':
      case 'f':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}


  // Vertical course card for portrait mode
 