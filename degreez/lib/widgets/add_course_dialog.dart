import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';

Widget buildFormattedPrereqWarning(
  List<List<String>> prereqGroups,
  List<String> missingIds,
  Map<String, String> courseNames,
) {
  final missingSet = missingIds.toSet();

  return Directionality(
    textDirection: TextDirection.rtl,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < prereqGroups.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'או',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          Wrap(
            children: [
              // const Text('('),
              for (int j = 0; j < prereqGroups[i].length; j++) ...[
                if (j > 0)
                  const Text(' ו־ ', style: TextStyle(color: Colors.white70)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: prereqGroups[i][j],
                        style: TextStyle(
                          color:
                              missingSet.contains(prereqGroups[i][j])
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' (${courseNames[prereqGroups[i][j]] ?? 'לא ידוע'})',
                        style: TextStyle(
                          color:
                              missingSet.contains(prereqGroups[i][j])
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              //  const Text(')'),
            ],
          ),
        ],
      ],
    ),
  );
}

class AddCourseDialog extends StatefulWidget {
  final String semesterName;
  final Function(String courseId)? onCourseAdded; // Callback for calendar

  const AddCourseDialog({
    super.key,
    required this.semesterName,
    this.onCourseAdded,
  });

  static Future<void> show(
    BuildContext context,
    String semesterName, {
    Function(String courseId)? onCourseAdded,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => AddCourseDialog(
            semesterName: semesterName,
            onCourseAdded: onCourseAdded,
          ),
    );
  }

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final searchController = TextEditingController();
  List<CourseSearchResult> results = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentTextStyle: TextStyle(color: AppColorsDarkMode.secondaryColor),
      title: Text('Add Course to ${widget.semesterName}'),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        width: 400,
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColorsDarkMode.secondaryColor,
                  ),
                ),
                labelText: 'Course ID or Name',
                hintText: 'e.g. 02340114 or פיסיקה 2',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (value.length > 3) _search(value);
              },
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const CircularProgressIndicator()
            else if (results.isEmpty && searchController.text.isNotEmpty)
              const Text('No courses found.'),
            if (results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final courseResult = results[index];
                    final course = courseResult.course;

                    return ListTile(
                      title: Text('${course.courseNumber} - ${course.name}'),
                      subtitle: Text(
                        '${course.points} points • ${course.faculty}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addCourse(course),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _search(String query) async {
    setState(() => isLoading = true);

    final isId = RegExp(r'^\d+$').hasMatch(query);
    final courseId = isId ? query : null;
    final courseName = isId ? null : query;

    final fetched = await context.read<CourseProvider>().searchCourses(
      courseId: courseId,
      courseName: courseName,
      pastSemestersToInclude: 4,
    );

    if (mounted) {
      setState(() {
        results = fetched;
        isLoading = false;
      });
    }
  }

  Future<void> _addCourse(EnhancedCourseDetails courseDetails) async {
    final existingCourses =
        context
            .read<CourseProvider>()
            .getCoursesForSemester(widget.semesterName)
            .map((c) => c.courseId)
            .toSet();

    if (existingCourses.contains(courseDetails.courseNumber)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              "${courseDetails.name} כבר קיים בסמסטר ${widget.semesterName}",
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      return;
    }

    final rawPrereqs = courseDetails.prerequisites;
    List<List<String>> parsedPrereqs = [];

    if (rawPrereqs is String) {
      final orGroups = rawPrereqs.split(RegExp(r'\s*או\s*'));

      for (final group in orGroups) {
        final andGroup =
            group
                .replaceAll(RegExp(r'[^\d\s]'), '')
                .trim()
                .split(RegExp(r'\s+'))
                .where((id) => RegExp(r'^\d{8}$').hasMatch(id))
                .toList();

        if (andGroup.isNotEmpty) parsedPrereqs.add(andGroup);
      }
    }

    final missing = context.read<CourseProvider>().getMissingPrerequisites(
      widget.semesterName,
      parsedPrereqs,
    );

    if (missing.isNotEmpty) {
      final allTakenCourses = context
          .read<CourseProvider>()
          .sortedCoursesBySemester
          .values
          .expand((list) => list);

      final courseIdToName = {
        for (final course in allTakenCourses) course.courseId: course.name,
      };

      for (final group in parsedPrereqs) {
        for (final courseId in group) {
          if (!courseIdToName.containsKey(courseId)) {
            final name = await CourseService.getCourseName(courseId);
            courseIdToName[courseId] = name ?? 'Unknown';
          }
        }
      }

      final proceedAnyway = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Missing Prerequisites'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'To register for this course, you must have completed one of the following prerequisite groups. '
                    'Courses in red were not found in your previous semesters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  buildFormattedPrereqWarning(
                    parsedPrereqs,
                    missing,
                    courseIdToName,
                  ),
                  const SizedBox(height: 10),
                  const Text('Do you want to add this course anyway?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Add Anyway'),
                ),
              ],
            ),
      );

      if (proceedAnyway != true) return;
    }

    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
      labTime: '',
      workshopTime: '',
      creditPoints: courseDetails.creditPoints, // Store credit points from API
    );

    final success = await context.read<CourseProvider>().addCourseToSemester(
      context.read<StudentProvider>().student!.id,
      widget.semesterName,
      course,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (success) {
      widget.onCourseAdded?.call(courseDetails.courseNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${courseDetails.name} added to ${widget.semesterName}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
