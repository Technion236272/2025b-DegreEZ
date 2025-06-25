// lib/widgets/exam_dates_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/theme_provider.dart';
import '../models/student_model.dart';

class ExamDatesPanel extends StatefulWidget {
  const ExamDatesPanel({super.key});

  @override
  State<ExamDatesPanel> createState() => _ExamDatesPanelState();
}

class _ExamDatesPanelState extends State<ExamDatesPanel> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer3<CourseProvider, CourseDataProvider, ThemeProvider>(
      builder: (context, courseProvider, courseDataProvider, themeProvider, _) {
        // Get current semester courses only
        final currentSemester = courseDataProvider.currentSemester?.semesterName;
        final currentCourses = currentSemester != null 
            ? courseProvider.coursesBySemester[currentSemester] ?? []
            : <StudentCourse>[];

        if (currentCourses.isEmpty) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<ExamInfo>>(
          future: _getExamInfo(currentCourses, courseDataProvider, currentSemester!),

          builder: (context, snapshot) {
            final examData = snapshot.data ?? [];
            
            if (examData.isEmpty) {
              return const SizedBox.shrink();
            }

            final periodAExams = examData.where((e) => e.period == ExamPeriod.periodA).toList();
            final periodBExams = examData.where((e) => e.period == ExamPeriod.periodB).toList();

            return Card(
              elevation: 5,
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
                          Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Exam Dates (${examData.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Period indicators
                          if (periodAExams.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red, width: 1),
                              ),
                              child: Text(
                                'A (${periodAExams.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (periodBExams.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Text(
                                'B (${periodBExams.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                  
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isExpanded 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(height: 0),
                    secondChild: Column(
                      children: [
                        const Divider(height: 1),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: examData.length > 4
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemCount: examData.length,
                            itemBuilder: (context, index) => _buildExamListTile(
                              examData[index], 
                              themeProvider,
                            ),
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
      },
    );
  }

Widget _buildExamListTile(ExamInfo examInfo, ThemeProvider themeProvider) {
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
        Text(
          '📝 ${examInfo.examType}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
Future<List<ExamInfo>> _getExamInfo(
  List<StudentCourse> courses,
  CourseDataProvider courseDataProvider,
  String semesterName,
) async {
  final parsed = _parseSemesterCode(semesterName);
  if (parsed == null) return [];

  final year = parsed.$1;
  final semesterCode = parsed.$2;

  final examList = <ExamInfo>[];

  for (final course in courses) {
    final courseDetails = await courseDataProvider.getCourseDetails(
      year,
      semesterCode,
      course.courseId,
    );
    if (courseDetails?.hasExams == true) {
      final exams = courseDetails!.exams;

      ExamInfo createExamInfo(String examKey, ExamPeriod period, String examType) {
        final rawDate = exams[examKey]!;
        final parsedDate = _parseExamDate(rawDate);
        return ExamInfo(
          courseId: course.courseId,
          courseName: course.name,
          period: period,
          examType: examType,
          rawDateString: rawDate,
          examDate: parsedDate,
          formattedDate: parsedDate != null
              ? DateFormat('dd-MM-yyyy HH:mm').format(parsedDate)
              : 'Date TBD',
          displayDate: parsedDate != null
              ? DateFormat('EEEE, dd-MM').format(parsedDate)
              : 'Date TBD',
          periodColor: period == ExamPeriod.periodA ? Colors.red : Colors.blue,
          periodText: period == ExamPeriod.periodA ? 'Period A' : 'Period B',
          sortOrder: parsedDate != null
              ? (parsedDate.month * 100 + parsedDate.day)
              : 999999,
        );
      }

      if (exams.containsKey('מועד א') && exams['מועד א']!.isNotEmpty) {
        examList.add(createExamInfo('מועד א', ExamPeriod.periodA, 'Final Exam'));
      }

      if (exams.containsKey('מועד ב') && exams['מועד ב']!.isNotEmpty) {
        examList.add(createExamInfo('מועד ב', ExamPeriod.periodB, 'Final Exam'));
      }

      if (exams.containsKey('בוחן מועד א') && exams['בוחן מועד א']!.isNotEmpty) {
        examList.add(createExamInfo('בוחן מועד א', ExamPeriod.periodA, 'Midterm'));
      }

      if (exams.containsKey('בוחן מועד ב') && exams['בוחן מועד ב']!.isNotEmpty) {
        examList.add(createExamInfo('בוחן מועד ב', ExamPeriod.periodB, 'Midterm'));
      }
    }
  }

  examList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return examList;
}
  
 DateTime? _parseExamDate(String dateString) {
    try {
      // Try different date formats that might be in the API
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
      
      // Debug: Print the raw date string to see what we're trying to parse
      debugPrint('Trying to parse exam date: "$cleanedDateString"');
      
      for (final format in formats) {
        try {
          final parsed = DateFormat(format).parse(cleanedDateString);
          debugPrint('Successfully parsed "$cleanedDateString" with format "$format" -> $parsed');
          return parsed;
        } catch (e) {
          // Try next format
        }
      }
      
      debugPrint('Failed to parse exam date with any format: "$cleanedDateString"');
      return null;
    } catch (e) {
      debugPrint('Error parsing exam date: $dateString - $e');
      return null;
    }  }
}

// Supporting classes
enum ExamPeriod { periodA, periodB }

// 1. Enhanced ExamInfo class with all prepared data
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
