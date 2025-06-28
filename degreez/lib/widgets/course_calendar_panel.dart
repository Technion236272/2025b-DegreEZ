// lib/widgets/course_calendar_panel.dart - Updated with ColorThemeProvider
import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/theme_provider.dart';
import '../models/student_model.dart';
import '../mixins/course_event_mixin.dart';
import '../mixins/schedule_selection_mixin.dart';
import '../services/course_service.dart';

// Add exam-related classes and functionality
enum ExamPeriod { periodA, periodB, midtermA, midtermB }

class ExamInfo {
  final String courseId;
  final String courseName;
  final ExamPeriod period;
  final String examType;
  final String rawDateString;
  final DateTime? examDate;

  // Prepared display data
  final String formattedDate;
  final String displayDate;
  final Color periodColor;
  final String periodText;
  final int sortOrder; // For custom sorting

  ExamInfo({
    required this.courseId,
    required this.courseName,
    required this.period,
    required this.examType,
    required this.rawDateString,
    this.examDate,
    required this.formattedDate,
    required this.displayDate,
    required this.periodColor,
    required this.periodText,
    required this.sortOrder,
  });
}

class CourseCalendarPanel extends StatefulWidget {
  final String selectedSemester;
  final EventController eventController;
  final Function(String courseId)? onCourseRemovedFromCalendar;
  final Function(String courseId)? onCourseRestoredToCalendar;
  final bool Function(String courseId)? isCourseRemovedFromCalendar;
  final int? viewMode;
  final VoidCallback? onToggleView;
  const CourseCalendarPanel({
    super.key,
    required this.selectedSemester,
    required this.eventController,
    this.onCourseRemovedFromCalendar,
    this.onCourseRestoredToCalendar,
    this.isCourseRemovedFromCalendar,
    this.viewMode,
    this.onToggleView,
  });

  @override
  State<CourseCalendarPanel> createState() => _CourseCalendarPanelState();
}

class _CourseCalendarPanelState extends State<CourseCalendarPanel>
    with CourseEventMixin, ScheduleSelectionMixin {
  bool _isExpanded = false;

  (int, int)? _parseSemesterCode(String semesterName) {
    final match = RegExp(
      r'^(Winter|Spring|Summer) (\d{4})(?:-(\d{4}))?$',
    ).firstMatch(semesterName);
    if (match == null) return null;

    final season = match.group(1)!;
    final firstYear = int.parse(match.group(2)!);

    int apiYear;
    int semesterCode;

    switch (season) {
      case 'Winter':
        apiYear = firstYear; // Use the first year for Winter
        semesterCode = 200;
        break;
      case 'Spring':
        apiYear = firstYear - 1;
        semesterCode = 201;
        break;
      case 'Summer':
        apiYear = firstYear - 1;
        semesterCode = 202;
        break;
      default:
        return null;
    }

    return (apiYear, semesterCode);
  }

  // Exam-related methods
  Future<List<ExamInfo>> _getExamInfo(
    List<StudentCourse> courses,
    CourseDataProvider courseDataProvider,
  ) async {
    final examList = <ExamInfo>[];

    for (final course in courses) {
      final parsed = _parseSemesterCode(widget.selectedSemester);
      if (parsed == null) return [];

      final year = parsed.$1;
      final semesterCode = parsed.$2;

      final courseDetails = await courseDataProvider.getCourseDetails(
        year,
        semesterCode,
        course.courseId,
      );

      if (courseDetails?.hasExams == true) {
        final exams = courseDetails!.exams;

        // Helper function to create exam info with prepared data
        ExamInfo createExamInfo(
          String examKey,
          ExamPeriod period,
          String examType,
        ) {
          final rawDate = exams[examKey]!;
          final parsedDate = _parseExamDate(rawDate);
          
          // Determine color and text based on period
          Color periodColor;
          String periodText;
          switch (period) {
            case ExamPeriod.periodA:
              periodColor = Colors.red;
              periodText = 'Period A';
              break;
            case ExamPeriod.periodB:
              periodColor = Colors.blue;
              periodText = 'Period B';
              break;
            case ExamPeriod.midtermA:
              periodColor = Colors.orange;
              periodText = 'Midterm A';
              break;
            case ExamPeriod.midtermB:
              periodColor = Colors.purple;
              periodText = 'Midterm B';
              break;
          }          
          return ExamInfo(
            courseId: course.courseId,
            courseName: course.name,
            period: period,
            examType: examType,
            rawDateString: rawDate,
            examDate: parsedDate,
            formattedDate:
                parsedDate != null
                    ? DateFormat('dd-MM-yyyy HH:mm').format(parsedDate)
                    : 'Date TBD',
            displayDate:
                parsedDate != null
                    ? DateFormat('EEEE, dd-MM').format(parsedDate)
                    : 'Date TBD',
            periodColor: periodColor,
            periodText: periodText,
            sortOrder:
                parsedDate != null
                    ? (parsedDate.month * 100 + parsedDate.day)
                    : 999999,
          );
        }

        // Process all exam types
        if (exams.containsKey('מועד א') && exams['מועד א']!.isNotEmpty) {
          examList.add(
            createExamInfo('מועד א', ExamPeriod.periodA, 'Final Exam'),
          );
        }

        if (exams.containsKey('מועד ב') && exams['מועד ב']!.isNotEmpty) {
          examList.add(
            createExamInfo('מועד ב', ExamPeriod.periodB, 'Final Exam'),
          );
        }

        if (exams.containsKey('בוחן מועד א') &&
            exams['בוחן מועד א']!.isNotEmpty) {
          examList.add(
            createExamInfo('בוחן מועד א', ExamPeriod.periodA, 'midterm A'),
          );
        }

        if (exams.containsKey('בוחן מועד ב') &&
            exams['בוחן מועד ב']!.isNotEmpty) {
          examList.add(
            createExamInfo('בוחן מועד ב', ExamPeriod.periodB, 'midterm B'),
          );
        }
      }
    }

    examList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return examList;
  }

  DateTime? _parseExamDate(String dateString) {
    try {
      final formats = [
        'dd/MM/yyyy HH:mm',
        'dd/MM/yyyy',
        'dd-MM-yyyy HH:mm',
        'dd-MM-yyyy',
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd',
        'MM/dd/yyyy HH:mm',
        'MM/dd/yyyy',
        'dd.MM.yyyy HH:mm',
        'dd.MM.yyyy',
      ];

      final cleanedDateString = dateString.trim();

      for (final format in formats) {
        try {
          return DateFormat(format).parse(cleanedDateString);
        } catch (e) {
          // Try next format
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void _showExamDatesDialog(
    List<ExamInfo> examData,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.read<ThemeProvider>().accentColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Exam Dates (${examData.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: examData.length,
                      itemBuilder:
                          (context, index) => _buildExamListTile(
                            examData[index],
                            themeProvider,
                            examData, // Pass the full list
                            index, // Pass the current index
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildExamListTile(
    ExamInfo examInfo,
    ThemeProvider themeProvider,
    List<ExamInfo> allExams,
    int currentIndex,
  ) {
    // Calculate days until next exam
    Widget? daysDifferenceWidget;
    
    if (currentIndex < allExams.length - 1) {
      final currentExam = allExams[currentIndex];
      final nextExam = allExams[currentIndex + 1];
      
      if (currentExam.examDate != null && nextExam.examDate != null) {
        final daysDifference = nextExam.examDate!.difference(currentExam.examDate!).inDays;
        
        Color indicatorColor;
        IconData indicatorIcon;
        String indicatorText;
        
        if (daysDifference == 0) {
          indicatorColor = Colors.red;
          indicatorIcon = Icons.warning;
          indicatorText = 'Same day';
        } else if (daysDifference == 1) {
          indicatorColor = Colors.orange;
          indicatorIcon = Icons.schedule;
          indicatorText = 'Next day';
        } else if (daysDifference <= 3) {
          indicatorColor = Colors.amber;
          indicatorIcon = Icons.schedule;
          indicatorText = '$daysDifference days';
        } else if (daysDifference <= 7) {
          indicatorColor = Colors.blue;
          indicatorIcon = Icons.schedule;
          indicatorText = '$daysDifference days';
        } else {
          indicatorColor = Colors.green;
          indicatorIcon = Icons.schedule;
          indicatorText = '$daysDifference days';
        }
        
        daysDifferenceWidget = Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: indicatorColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: indicatorColor.withAlpha(76), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                indicatorIcon,
                size: 14,
                color: indicatorColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$indicatorText until ${nextExam.courseId}',
                style: TextStyle(
                  fontSize: 11,
                  color: indicatorColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    return ListTile(
      leading: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: themeProvider.getCourseColor(examInfo.courseId),
          shape: BoxShape.circle,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              examInfo.courseName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: examInfo.periodColor.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: examInfo.periodColor, width: 1),
            ),
            child: Text(
              examInfo.periodText,
              style: TextStyle(
                fontSize: 10,
                color: examInfo.periodColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 ${examInfo.formattedDate}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            'Course ID: ${examInfo.courseId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text('📝 ${examInfo.examType}', style: const TextStyle(fontSize: 12)),
          if (daysDifferenceWidget != null) ...[
            const SizedBox(height: 4),
            daysDifferenceWidget,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      StudentProvider,
      CourseProvider,
      CourseDataProvider,
      ThemeProvider
    >(
      builder: (
        context,
        studentProvider,
        courseProvider,
        courseDataProvider,
        themeProvider,
        _,
      ) {
        // final allCourses = courseProvider.coursesBySemester.values
        //     .expand((courses) => courses)
        //     .toList();
        // i want to show only the courses of the current semester
        final allCourses = courseProvider.getCoursesForSemester(
          widget.selectedSemester,
        );

        return Card(
          elevation: 3,
          margin: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Title on the left
                      Text(
                        'My Courses (${allCourses.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Exam dates icon next to title
                      FutureBuilder<List<ExamInfo>>(
                        future: _getExamInfo(allCourses, courseDataProvider),
                        builder: (context, snapshot) {
                          final examData = snapshot.data ?? [];
                          if (examData.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final periodAExams =
                              examData
                                  .where((e) => e.period == ExamPeriod.periodA)
                                  .length;
                          final periodBExams =
                              examData
                                  .where((e) => e.period == ExamPeriod.periodB)
                                  .length;

                          return Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap:
                                  () => _showExamDatesDialog(
                                    examData,
                                    themeProvider,
                                  ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.withAlpha(75),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${examData.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    if (periodAExams > 0 ||
                                        periodBExams > 0) ...[
                                      const SizedBox(width: 4),
                                      if (periodAExams > 0)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (periodBExams > 0)
                                        Container(
                                          margin: EdgeInsets.only(
                                            left: periodAExams > 0 ? 2 : 0,
                                          ),
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      // if (midtermAExams > 0)
                                      //   Container(
                                      //     margin: EdgeInsets.only(left: (periodAExams > 0 || periodBExams > 0) ? 2 : 0),
                                      //     width: 6,
                                      //     height: 6,
                                      //     decoration: const BoxDecoration(
                                      //       color: Colors.orange,
                                      //       shape: BoxShape.circle,
                                      //     ),
                                      //   ),
                                      // if (midtermBExams > 0)
                                      //   Container(
                                      //     margin: EdgeInsets.only(left: (periodAExams > 0 || periodBExams > 0 || midtermAExams > 0) ? 2 : 0),
                                      //     width: 6,
                                      //     height: 6,
                                      //     decoration: const BoxDecoration(
                                      //       color: Colors.purple,
                                      //       shape: BoxShape.circle,
                                      //     ),
                                      //   ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      // Arrow in the middle-right
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      // Toggle button on the far right
                      if (widget.viewMode != null &&
                          widget.onToggleView != null) ...[
                        const SizedBox(width: 8),
                        _buildViewToggleButton(),
                      ],
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  children: [
                    const Divider(height: 1),
                    if (allCourses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No courses added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight:
                              240, // Approximate height for 3 items (80px each)
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics:
                              allCourses.length > 1
                                  ? const AlwaysScrollableScrollPhysics()
                                  : const NeverScrollableScrollPhysics(),
                          itemCount: allCourses.length,
                          itemBuilder: (context, index) {
                            final course = allCourses[index];
                            return FutureBuilder(
                              future:
                                  (() async {
                                    final parsed = _parseSemesterCode(
                                      widget.selectedSemester,
                                    );
                                    if (parsed == null) return null;

                                    final year = parsed.$1;
                                    final semesterCode = parsed.$2;

                                    return await courseDataProvider
                                        .getCourseDetails(
                                          year,
                                          semesterCode,
                                          course.courseId,
                                        );
                                  })(),

                              builder: (context, snapshot) {
                                final courseDetails = snapshot.data;

                                return ListTile(
                                  leading: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: themeProvider.getCourseColor(
                                        course.courseId,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(course.name)),
                                      // Selection indicators
                                      if (course.hasSelectedLecture)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withAlpha(50),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'L',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (course.hasSelectedTutorial)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(50),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'T',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (course.hasSelectedLab)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withAlpha(50),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'L',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (course.hasSelectedWorkshop)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withAlpha(50),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.purple,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'W',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.purple,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${course.courseId}'),
                                      if (courseDetails != null)
                                        Text(
                                          'Credits: ${courseDetails.creditPoints}',
                                        )
                                      else if (snapshot.connectionState ==
                                          ConnectionState.waiting)
                                        const Text(
                                          'Loading...',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      else
                                        const Text(
                                          'Details unavailable',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      // Show selection status
                                      if (course.hasCompleteScheduleSelection)
                                        Text(
                                          'Schedule: ${course.selectionSummary}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Schedule: All times shown',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),

                                      // Show calendar status
                                      if (widget.isCourseRemovedFromCalendar
                                              ?.call(course.courseId) ??
                                          false)
                                        const Text(
                                          'Status: Hidden from calendar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Status: Shown in calendar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {                                        case 'select_schedule':
                                          showScheduleSelectionDialog(
                                            context,
                                            course,
                                            courseDetails,
                                            semester: widget.selectedSemester, // Add semester parameter
                                            onSelectionUpdated: () async {
                                              // Match the calendar page's callback behavior
                                              debugPrint('Schedule selection updated from course panel, refreshing...');
                                              
                                              // Small delay to ensure consistency
                                              await Future.delayed(const Duration(milliseconds: 100));
                                              
                                              if (mounted) {
                                                setState(() {});
                                                
                                                // Also refresh the calendar events if possible
                                                // This ensures both functionalities behave the same way
                                                try {
                                                  final themeProvider = context.read<ThemeProvider>();
                                                  final courseProvider = context.read<CourseProvider>();
                                                  await refreshCalendarEvents(context, courseProvider, themeProvider);
                                                } catch (e) {
                                                  debugPrint('Could not refresh calendar events from course panel: $e');
                                                }
                                              }
                                            },
                                          );
                                          break;
                                        case 'add_to_calendar':
                                          _addCourseToCalendar(
                                            course,
                                            courseDetails,
                                            themeProvider,
                                          );
                                          break;
                                        case 'remove_from_calendar':
                                          _removeCourseFromCalendar(course);
                                          break;
                                        case 'restore_to_calendar':
                                          _restoreCourseToCalendar(course);
                                          break;
                                        case 'remove_course':
                                          _showRemoveCourseDialog(course);
                                          break;
                                        case 'view_details':
                                          _showCourseDetails(
                                            context,
                                            course,
                                            courseDetails,
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      final isRemovedFromCalendar =
                                          widget.isCourseRemovedFromCalendar
                                              ?.call(course.courseId) ??
                                          false;

                                      return [
                                        const PopupMenuItem(
                                          value: 'select_schedule',
                                          child: Row(
                                            children: [
                                              Icon(Icons.schedule),
                                              SizedBox(width: 8),
                                              Text('Select Schedule'),
                                            ],
                                          ),
                                        ),

                                        if (!isRemovedFromCalendar) ...[
                                          const PopupMenuItem(
                                            value: 'remove_from_calendar',
                                            child: Row(
                                              children: [
                                                Icon(Icons.remove_circle),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Hide/remove from Calendar',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          const PopupMenuItem(
                                            value: 'restore_to_calendar',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.restore,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Restore/show on Calendar',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const PopupMenuItem(
                                          value: 'remove_course',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Remove Course',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'view_details',
                                          child: Row(
                                            children: [
                                              Icon(Icons.info),
                                              SizedBox(width: 8),
                                              Text('View Details'),
                                            ],
                                          ),
                                        ),
                                      ];
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addCourseToCalendar(
    StudentCourse course,
    courseDetails,
    ThemeProvider themeProvider,
  ) {
    if (courseDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course details not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Check if course events already exist in calendar to prevent duplicates
      final existingEvents = widget.eventController.allEvents;
      final courseEventsExist = existingEvents.any(
        (event) =>
            event.title.startsWith(course.name) ||
            event.title.startsWith('${course.name} ') ||
            event.title.contains('${course.name} -') ||
            event.title.contains('${course.name}:'),
      );

      if (courseEventsExist) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.name} is already in the calendar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get the current week's Sunday
      final now = DateTime.now();
      final sunday = now.subtract(Duration(days: now.weekday % 7));

      final courseColor = themeProvider.getCourseColor(course.courseId);
      int eventsAdded = 0;
      // Create events from detailed schedule data only for selected times
      final courseProvider = context.read<CourseProvider>();      final selectedEntries = courseProvider.getSelectedScheduleEntries(
        course.courseId,
        courseDetails,
        semester: widget.selectedSemester,
      );

      final scheduleEntriesToShow = <dynamic>[];

      // Add all selected lectures
      final selectedLectures = selectedEntries['lecture'] ?? <ScheduleEntry>[];
      scheduleEntriesToShow.addAll(selectedLectures);

      // Add all selected tutorials
      final selectedTutorials =
          selectedEntries['tutorial'] ?? <ScheduleEntry>[];
      scheduleEntriesToShow.addAll(selectedTutorials);

      // Add all selected labs
      final selectedLabs = selectedEntries['lab'] ?? <ScheduleEntry>[];
      scheduleEntriesToShow.addAll(selectedLabs);

      // Add all selected workshops
      final selectedWorkshops =
          selectedEntries['workshop'] ?? <ScheduleEntry>[];
      scheduleEntriesToShow.addAll(
        selectedWorkshops,
      ); // If no selections made, show all (backward compatibility)
      if (scheduleEntriesToShow.isEmpty &&
          !course.hasCompleteScheduleSelection) {
        scheduleEntriesToShow.addAll(courseDetails.schedule);
      }

      // Deduplicate schedule entries by time and type to avoid multiple events for the same lecture
      final uniqueScheduleEntries = <dynamic>[];
      final seenTimeSlots = <String>{};

      for (final schedule in scheduleEntriesToShow) {
        final timeSlotKey = '${schedule.day}_${schedule.time}_${schedule.type}';
        if (!seenTimeSlots.contains(timeSlotKey)) {
          uniqueScheduleEntries.add(schedule);
          seenTimeSlots.add(timeSlotKey);
        }
      }

      for (final schedule in uniqueScheduleEntries) {
        final dayOfWeek = _parseHebrewDay(schedule.day);
        if (dayOfWeek == null) continue;

        final eventDate = sunday.add(
          Duration(days: (dayOfWeek == DateTime.sunday) ? 0 : dayOfWeek),
        );
        final timeRange = _parseTimeRange(schedule.time, eventDate);
        if (timeRange == null) continue;
        final event = CalendarEventData(
          title: formatEventTitle(
            course.name,
            _parseEventType(schedule.type),
            null, // Don't show group number since we're deduplicating
            instructorName:
                schedule.staff?.isNotEmpty == true ? schedule.staff : null,
          ),
          description: _buildEventDescription(course, schedule),
          date: eventDate,
          startTime: timeRange['start']!,
          endTime: timeRange['end']!,
          color: courseColor,
        );

        widget.eventController.add(event);
        eventsAdded++;
      }
      // If no detailed schedule, try to create events from stored times
      if (eventsAdded == 0) {
        eventsAdded += _addBasicTimeEvents(course, sunday, courseColor);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${course.name} added to calendar ($eventsAdded events)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding course to calendar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeCourseFromCalendar(StudentCourse course) {
    // NEW APPROACH: Mark course as removed instead of physically removing events
    widget.onCourseRemovedFromCalendar?.call(course.courseId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} hidden from calendar'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _restoreCourseToCalendar(StudentCourse course) {
    // NEW: Call the restore callback
    widget.onCourseRestoredToCalendar?.call(course.courseId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} restored to calendar'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCourseDetails(
    BuildContext context,
    StudentCourse course,
    courseDetails,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(course.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Course ID: ${course.courseId}'),
                  if (courseDetails != null) ...[
                    const SizedBox(height: 8),
                    Text('Credits: ${courseDetails.creditPoints}'),
                    Text('Faculty: ${courseDetails.faculty}'),
                    if (courseDetails.prerequisites.isNotEmpty)
                      Text('Prerequisites: ${courseDetails.prerequisites}'),
                    if (courseDetails.syllabus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Syllabus:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(courseDetails.syllabus),
                    ],
                  ],
                  if (course.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Personal Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(course.note!),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Method to show course removal confirmation dialog
  void _showRemoveCourseDialog(StudentCourse course) {
  final selectedSemester = widget.selectedSemester;


    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to permanently remove this course from your semester?',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course: ${course.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Course ID: ${course.courseId}'),
                      Text('Semester: $selectedSemester'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will permanently remove the course from your schedule and all its associated calendar events.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeCourseFromSemester(course.courseId, selectedSemester);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove Course'),
              ),
            ],
          ),
    );
  }

  // Method to permanently remove course from semester using CourseProvider
  void _removeCourseFromSemester(String courseId, String semester) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (!studentProvider.hasStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No student logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Removing course...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      ); // Call the existing removeCourseFromSemester method
      final success = await courseProvider.removeCourseFromSemester(
        studentProvider.student!.id,
        semester,
        courseId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course $courseId removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Also remove from calendar events
        int removedCount = 0;
        widget.eventController.removeWhere((event) {
          final shouldRemove =
              event.title.contains(courseId) ||
              (event.description?.contains(courseId) == true);
          if (shouldRemove) removedCount++;
          return shouldRemove;
        });

        // Show additional feedback about calendar events removed
        if (removedCount > 0) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$removedCount calendar events also removed'),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods for parsing Hebrew days and times
  int? _parseHebrewDay(String hebrewDay) {
    final dayMap = {
      'א': DateTime.sunday,
      'ב': DateTime.monday,
      'ג': DateTime.tuesday,
      'ד': DateTime.wednesday,
      'ה': DateTime.thursday,
      'ו': DateTime.friday,
      'ש': DateTime.saturday,
    };
    return dayMap[hebrewDay];
  }

  Map<String, DateTime>? _parseTimeRange(String timeRange, DateTime baseDate) {
    try {
      final parts = timeRange.split(' - ');
      if (parts.length != 2) return null;

      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');

      if (startParts.length != 2 || endParts.length != 2) return null;

      final startTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      return {'start': startTime, 'end': endTime};
    } catch (e) {
      debugPrint('Error parsing time range: $timeRange - $e');
      return null;
    }
  }

  String _buildEventDescription(StudentCourse course, dynamic schedule) {
    final parts = <String>[];
    parts.add('Course ID: ${course.courseId}');

    if (schedule.staff?.isNotEmpty == true) {
      parts.add('Instructor: ${schedule.staff}');
    }
    if (schedule.fullLocation?.isNotEmpty == true) {
      parts.add('Location: ${schedule.fullLocation}');
    }
    if (schedule.type?.isNotEmpty == true) {
      parts.add('Type: ${schedule.type}');
    }
    if (course.note?.isNotEmpty == true) {
      parts.add('Note: ${course.note}');
    }

    return parts.join('\n');
  }

  int _addBasicTimeEvents(
    StudentCourse course,
    DateTime sunday,
    Color courseColor,
  ) {
    int eventsAdded = 0;
    // Create events from stored lecture time
    if (course.lectureTime.isNotEmpty) {
      final lectureEvent = _createEventFromTimeString(
        course,
        course.lectureTime,
        'Lecture',
        sunday,
        courseColor,
      );
      if (lectureEvent != null) {
        widget.eventController.add(lectureEvent);
        eventsAdded++;
      }
    }

    // Create events from stored tutorial time
    if (course.tutorialTime.isNotEmpty) {
      final tutorialEvent = _createEventFromTimeString(
        course,
        course.tutorialTime,
        'Tutorial',
        sunday,
        courseColor,
      );
      if (tutorialEvent != null) {
        widget.eventController.add(tutorialEvent);
        eventsAdded++;
      }
    }
    // Create events from stored lab time
    if (course.labTime.isNotEmpty) {
      final labEvent = _createEventFromTimeString(
        course,
        course.labTime,
        'Lab',
        sunday,
        courseColor,
      );
      if (labEvent != null) {
        widget.eventController.add(labEvent);
        eventsAdded++;
      }
    }
    // Create events from stored workshop time
    if (course.workshopTime.isNotEmpty) {
      final workshopEvent = _createEventFromTimeString(
        course,
        course.workshopTime,
        'Workshop',
        sunday,
        courseColor,
      );
      if (workshopEvent != null) {
        widget.eventController.add(workshopEvent);
        eventsAdded++;
      }
    }

    return eventsAdded;
  }

  CalendarEventData? _createEventFromTimeString(
    StudentCourse course,
    String timeString,
    String eventType,
    DateTime weekStart,
    Color color,
  ) {
    // Try to parse time string like "Monday 10:00-12:00" or "ב 10:00-12:00"
    final parts = timeString.split(' ');
    if (parts.length < 2) return null;

    final dayPart = parts[0];
    final timePart = parts.length > 1 ? parts[1] : '';

    // Parse day (Hebrew or English)
    int? dayOfWeek;
    if (dayPart.length == 1) {
      // Hebrew single letter
      dayOfWeek = _parseHebrewDay(dayPart);
    } else {
      // English day name
      dayOfWeek = _parseEnglishDay(dayPart);
    }

    if (dayOfWeek == null || timePart.isEmpty) return null;

    // Convert DateTime weekday to correct offset from Sunday
    final dayOffset = dayOfWeek == DateTime.sunday ? 0 : dayOfWeek;

    final eventDate = weekStart.add(Duration(days: dayOffset));
    final timeRange = _parseTimeRange(timePart, eventDate);

    if (timeRange == null) return null;

    return CalendarEventData(
      date: eventDate,
      title: '$eventType\n${course.name}',
      description: '${course.courseId}\n$eventType: $timeString',
      startTime: timeRange['start']!,
      endTime: timeRange['end']!,
      color: color,
    );
  }

  int? _parseEnglishDay(String englishDay) {
    final dayMap = {
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
    };
    return dayMap[englishDay.toLowerCase()];
  }

  CourseEventType _parseEventType(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'lecture':
        return CourseEventType.lecture;
      case 'tutorial':
        return CourseEventType.tutorial;
      case 'lab':
        return CourseEventType.lab;
      case 'workshop':
        return CourseEventType.workshop;
      default:
        return CourseEventType.lecture; // Default fallback
    }
  }

  Widget _buildViewToggleButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isLightMode = themeProvider.isLightMode;
        final backgroundColor = isLightMode 
            ? AppColorsLightMode.primaryColor 
            : AppColorsDarkMode.secondaryColor;
        final borderColor = isLightMode 
            ? AppColorsLightMode.secondaryColorDim 
            : AppColorsDarkMode.secondaryColorDim;
        final iconColor = isLightMode 
            ? AppColorsLightMode.mainColor 
            : AppColorsDarkMode.accentColor;
        
        return GestureDetector(
          onTap: widget.onToggleView,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Icon(
              widget.viewMode == 0 ? Icons.calendar_view_week : Icons.calendar_view_day,
              size: 16,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }
}
