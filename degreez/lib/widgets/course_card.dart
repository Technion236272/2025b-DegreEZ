import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
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
    if (widget.course.note != null && widget.course.note != '') {
      setState(() {
        _hasNote = true;
      });
    }
    // Check if the course has a grade that is int or double
    // Enhanced: Use a more robust check for grade presence
    final hasGrade = course.finalGrade.isNotEmpty;

    return Consumer2<CustomizedDiagramNotifier, ThemeProvider>(
      builder: (context, notifier, themeProvider, child) {
        final isFocused =
            notifier.focusedCourseId == null ||
            notifier.highlightedCourseIds.contains(widget.course.courseId);

        // Determine card color based on grade status
        final cardColor = hasGrade
            ? themeProvider.surfaceColor
            : themeProvider.cardColor;

        final borderColor = hasGrade
            ? themeProvider.secondaryColor.withOpacity(0.3)
            : themeProvider.borderPrimary.withOpacity(0.5);

        return Opacity(
          opacity: isFocused ? 1.0 : 0.2,
          child: AbsorbPointer(
            absorbing: !isFocused, // ✅ disable all interactions if not focused
            child: GestureDetector(
              // Enhanced: Add regular tap for quick actions
              onTap: () async {
                showCourseActionsPopup(
                  context,
                  widget.course,
                  widget.semester,
                  onCourseUpdated: () async {
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

                    widget.onCourseUpdated?.call();
                  },
                );
              },
              onLongPress: () {
                final courseProvider = Provider.of<CourseProvider>(
                  context,
                  listen: false,
                );
                notifier.focusOnCourseWithStoredPrereqs(
                  widget.course,
                  courseProvider.sortedCoursesBySemester,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: hasGrade ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 26, 12, 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Course Name
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: AutoSizeText(
                                widget.course.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 3,
                                minFontSize: 9,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Grade Badge
                          if (hasGrade) ...[
                            Flexible(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: themeProvider.secondaryColor.withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: themeProvider.secondaryColor
                                        .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.course.finalGrade,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.secondaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),

                    // Course ID and Note (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          if (_hasNote) ...[
                            Icon(
                              Icons.sticky_note_2_rounded,
                              size: 14,
                              color: themeProvider.accentColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            widget.course.courseId,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: themeProvider.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Credits (Top Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.mainColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.course.creditPoints} pts',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Horizontal course card for landscape mode - enhanced with tap gesture
  Widget _buildHorizontal(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails,
  ) {
    final hasGrade = course.finalGrade.isNotEmpty;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final courseColor = themeProvider.getCourseColor(course.courseId);

    return GestureDetector(
      // Enhanced: Add tap for quick actions in horizontal mode too
      onTap: () async {
        showCourseActionsPopup(
          context,
          widget.course,
          widget.semester,
          onCourseUpdated: () {
            setState(() {
              _hasNote =
                  widget.course.note != null &&
                  widget.course.note!.trim().isNotEmpty;
            });
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
                    ),
                  ),
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
                Flexible(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      course.finalGrade,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getGradeColor(course.finalGrade),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
