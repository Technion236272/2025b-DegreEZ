// pages/student_courses_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourseDialog(context),
            tooltip: 'Add Course',
          ),
        ],
      ),
      body: Consumer<StudentNotifier>(
        builder: (context, studentNotifier, _) {
          if (studentNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentNotifier.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${studentNotifier.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final coursesBySemester = studentNotifier.coursesBySemester;

          if (coursesBySemester.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No courses enrolled yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first course',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coursesBySemester.length,
            itemBuilder: (context, index) {
              final semester = coursesBySemester.keys.elementAt(index);
              final courses = coursesBySemester[semester]!;
              final totalCredits = studentNotifier.getTotalCreditsForSemester(semester);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    semester,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${courses.length} courses • ${totalCredits.toStringAsFixed(1)} credits',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  children: courses.map((course) {
                    final courseWithDetails = studentNotifier.getCourseWithDetails(semester, course.courseId);
                    return CourseListItem(
                      semesterKey: semester,
                      courseWithDetails: courseWithDetails,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final courseIdController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseIdController,
              decoration: const InputDecoration(
                labelText: 'Course ID',
                hintText: 'e.g., 02340124',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g., Introduction to Programming',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final courseId = courseIdController.text.trim();
              final name = nameController.text.trim();
              
              if (courseId.isEmpty || name.isEmpty) return;

              final course = StudentCourse(
                courseId: courseId,
                name: name,
                finalGrade: '',
                lectureTime: '',
                tutorialTime: '',
              );

              final success = await context.read<StudentNotifier>()
                  .addCourseToSemester('Winter 2024-25', course); // Changed from 2024/25 to 2024-25

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class CourseListItem extends StatelessWidget {
  final String semesterKey;
  final StudentCourseWithDetails? courseWithDetails;

  const CourseListItem({
    super.key,
    required this.semesterKey,
    required this.courseWithDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (courseWithDetails == null) {
      return const ListTile(
        title: Text('Course data unavailable'),
        leading: Icon(Icons.error, color: Colors.red),
      );
    }

    final studentCourse = courseWithDetails!.studentCourse;
    final courseDetails = courseWithDetails!.courseDetails;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${studentCourse.courseId} - ${studentCourse.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (courseDetails != null) ...[
                      Text(
                        courseDetails.faculty,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (courseDetails.points.isNotEmpty)
                        Text(
                          '${courseDetails.points} נקודות',
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                    ],
                  ],
                ),
              ),
              if (studentCourse.finalGrade.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(studentCourse.finalGrade),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    studentCourse.finalGrade,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.grade, size: 20),
                  onPressed: () => _showGradeDialog(context),
                  tooltip: 'Add Grade',
                ),
            ],
          ),
          
          // Course details
          if (courseDetails != null) ...[
            const SizedBox(height: 8),
            if (courseDetails.prerequisites.isNotEmpty)
              Text(
                'Prerequisites: ${courseDetails.prerequisites}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            
            // Schedule info
            if (courseDetails.schedule.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Schedule: ${courseDetails.schedule.length} time slots',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              ...courseDetails.schedule.take(2).map((schedule) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '${schedule.type}: ${schedule.day} ${schedule.time}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )),
              if (courseDetails.schedule.length > 2)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '...more times',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Loading course details...',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
          
          const Divider(height: 1),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    final numericGrade = int.tryParse(grade);
    if (numericGrade != null) {
      if (numericGrade >= 90) return Colors.green;
      if (numericGrade >= 80) return Colors.blue;
      if (numericGrade >= 70) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }

  void _showGradeDialog(BuildContext context) {
    final gradeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grade'),
        content: TextField(
          controller: gradeController,
          decoration: const InputDecoration(
            labelText: 'Final Grade',
            hintText: 'e.g., 85',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = gradeController.text.trim();
              if (grade.isEmpty) return;

              final success = await context.read<StudentNotifier>()
                  .updateCourseGrade(semesterKey, courseWithDetails!.studentCourse.courseId, grade);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grade updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}