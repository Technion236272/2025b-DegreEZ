import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';

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
      builder: (context) => AddCourseDialog(
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
      title: Text('Add Course to ${widget.semesterName}'),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        width: 400,
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
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
                      subtitle: Text('${course.points} points • ${course.faculty}'),
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
    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
      labTime: '',
      workshopTime: '',
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
          content: Text('${courseDetails.name} added to ${widget.semesterName}'),
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