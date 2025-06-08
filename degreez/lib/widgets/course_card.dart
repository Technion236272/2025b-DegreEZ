import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/widgets/grade_sticker.dart';
import 'package:degreez/widgets/course_actions_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';

enum DirectionValues { horizontal, vertical }

class CourseCard extends StatefulWidget {
  final DirectionValues direction;
  final StudentCourse course;
  final EnhancedCourseDetails? courseDetails;
  final String semester;
  final VoidCallback? onCourseUpdated; // Add callback for updates

  const CourseCard({
    super.key,
    required this.direction,
    required this.course,
    required this.semester,
    this.courseDetails,
    this.onCourseUpdated,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _hasNote = false;

  @override
  void initState() {
    super.initState();
    _hasNote = widget.course.note != null && widget.course.note!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return (widget.direction == DirectionValues.vertical)
        ? _buildVertical(context, widget.course, widget.courseDetails)
        : _buildHorizontal(context, widget.course, widget.courseDetails);
  }

  Widget _buildVertical(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails,
  ) {
    if (widget.course.note != '') {
      setState(() {
        _hasNote = true;
      });
    }

    final hasGrade = course.finalGrade.isNotEmpty;
    //debugPrint('Note: fetchedStartNote:${course.note}');

    return Consumer<CustomizedDiagramNotifier>(
      builder: (context, notifier, child) {
        final isFocused =
            notifier.focusedCourseId == null ||
            notifier.highlightedCourseIds.contains(widget.course.courseId);

        return Opacity(
          opacity: isFocused ? 1.0 : 0.2,
          child: AbsorbPointer(
            absorbing: !isFocused, // ✅ disable all interactions if not focused
            child: GestureDetector(              // Enhanced: Add regular tap for quick actions
              onTap: () async {
                if (!mounted) return;
                
                showCourseActionsPopup(
                  context,
                  widget.course,
                  widget.semester,
                  onCourseUpdated: () async {
                    if (!mounted) return;
                    
                    final studentProvider = Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    );
                    final courseProvider = Provider.of<CourseProvider>(
                      context,
                      listen: false,
                    );

                    await studentProvider.fetchStudentData(
                      studentProvider.student!.id,
                    ); // Optional
                    await courseProvider.loadStudentCourses(
                      studentProvider.student!.id,
                    ); // ✅ Required

                    final refreshed = courseProvider.getCourseById(
                      widget.semester,
                      widget.course.courseId,
                    );

                    if (mounted) {
                      setState(() {
                        _hasNote =
                            refreshed?.note != null &&
                            refreshed!.note!.trim().isNotEmpty;
                      });
                    }
                  },
                );
              },              onLongPress: () async {
                if (!mounted) return;
                
                final courseProvider = Provider.of<CourseProvider>(
                  context,
                  listen: false,
                );
                final studentId =
                    Provider.of<StudentProvider>(
                      context,
                      listen: false,
                    ).student!.id;

                // 🛠️ Force reload before accessing
                await courseProvider.loadStudentCourses(studentId);

          /*      final refreshed = courseProvider.getCourseById(
                  widget.semester,
                  widget.course.courseId,
                );

                debugPrint(
                  '👀 course.prerequisites = ${refreshed?.prerequisites}',
                );

                if (refreshed != null) {*/
                  if (mounted) {
                    final notifier = Provider.of<CustomizedDiagramNotifier>(
                      context,
                      listen: false,
                    );
                    notifier.focusOnCourseWithStoredPrereqs(
                      widget.course, // ✅ already has prerequisites
                      courseProvider.coursesBySemester,
                    );
                  }
               // }
              },

              child: child!,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // color: provider.cardColorPalette!.cardBG(course.courseId),
        color: context
            .watch<CustomizedDiagramNotifier>()
            .cardColorPalette!
            .cardBG(course.courseId),
        child: Column(
          children: [
            //Card Top Bar (Course number and points)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity, // ✅ full width
                decoration: BoxDecoration(
                  color:
                      context
                          .watch<CustomizedDiagramNotifier>()
                          .cardColorPalette!
                          .topBarBG,
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
                            color:
                                context
                                    .watch<CustomizedDiagramNotifier>()
                                    .cardColorPalette!
                                    .topBarText,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),                    // Always show credit points if available from stored data
                    if (course.creditPoints > 0)
                      Expanded(
                        flex: 3, // 30%
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                context
                                    .watch<CustomizedDiagramNotifier>()
                                    .cardColorPalette!
                                    .topBarMarkBG,
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
                                    color:
                                        context
                                            .watch<CustomizedDiagramNotifier>()
                                            .cardColorPalette!
                                            .topBarMarkText,
                                  ),
                                ),
                                Expanded(
                                  flex: 9,
                                  child: Text(
                                    course.creditPoints % 1 == 0 
                                        ? "${course.creditPoints.toInt()}.0"
                                        : course.creditPoints.toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          context
                                              .watch<
                                                CustomizedDiagramNotifier
                                              >()
                                              .cardColorPalette!
                                              .topBarMarkText,
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
                padding: EdgeInsets.only(right: 3, left: 1, top: 3, bottom: 2),
                width: double.infinity,
                child: AutoSizeText(
                  maxLines: 3,
                  minFontSize: 7,
                  textDirection: TextDirection.rtl,
                  course.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color:
                        context
                            .watch<CustomizedDiagramNotifier>()
                            .cardColorPalette!
                            .cardFG,
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
                child: Padding(
                  padding: EdgeInsets.only(right: 1, left: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      hasGrade
                          ? GradeSticker(grade: course.finalGrade)
                          : Icon(
                            Icons.work_off_outlined,
                            color: context
                                .watch<CustomizedDiagramNotifier>()
                                .cardColorPalette!
                                .cardBG(course.courseId),
                            size: 18,
                          ),

                      _hasNote
                          ? Icon(
                            Icons.edit_note_rounded,
                            color:
                                context
                                    .watch<CustomizedDiagramNotifier>()
                                    .cardColorPalette!
                                    .cardFG,
                            size: 18,
                          )
                          : Icon(
                            Icons.edit_note_rounded,
                            color:
                                context
                                    .watch<CustomizedDiagramNotifier>()
                                    .cardColorPalette!
                                    .cardFGdim,
                            size: 18,
                          ),

                      if (hasGrade) ...[
                        (double.tryParse(course.finalGrade)! > 55)
                            ? Icon(
                              Icons.check_rounded,
                              color:
                                  context
                                      .watch<CustomizedDiagramNotifier>()
                                      .cardColorPalette!
                                      .cardFG,
                              size: 18,
                            )
                            : Icon(
                              Icons.clear,
                              color:
                                  context
                                      .watch<CustomizedDiagramNotifier>()
                                      .cardColorPalette!
                                      .cardFG,
                              size: 18,
                            ),
                      ] else
                        Icon(
                          Icons.work_off_outlined,
                          color: context
                              .watch<CustomizedDiagramNotifier>()
                              .cardColorPalette!
                              .cardBG(course.courseId),
                          size: 18,
                        ),

                      // NotePopupButton(),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  // Horizontal course card for landscape mode - enhanced with tap gesture
  Widget _buildHorizontal(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails,
  ) {
    final hasGrade = course.finalGrade.isNotEmpty;
    final courseColor = _getCourseColor(course.courseId);

    return GestureDetector(      // Enhanced: Add tap for quick actions in horizontal mode too
      onTap: () async {
        if (!mounted) return;
        
        showCourseActionsPopup(
          context,
          widget.course,
          widget.semester,
          onCourseUpdated: () {
            if (mounted) {
              setState(() {
                _hasNote =
                    widget.course.note != null &&
                    widget.course.note!.trim().isNotEmpty;
              });
            }
          },
        );
      },
      onLongPress: () async {},
      child: Card(
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
                    ),                  ),
                  if (course.creditPoints > 0)
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
                        course.creditPoints % 1 == 0 
                            ? course.creditPoints.toInt().toString()
                            : course.creditPoints.toString(),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
