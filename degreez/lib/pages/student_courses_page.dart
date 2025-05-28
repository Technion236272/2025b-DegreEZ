// pages/student_courses_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';
import '../services/course_service.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showCourseSearchDialog(context),
            tooltip: 'Search Courses',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourseDialog(context),
            tooltip: 'Add Course Manually',
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading
                      if (studentNotifier.student != null) {
                        studentNotifier.fetchStudentData(
                          studentNotifier.student!.id,
                        );
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final coursesBySemester = studentNotifier.coursesBySemester;

          if (coursesBySemester.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No courses enrolled yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap search or + to add your first course',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (studentNotifier.currentSemester != null)
                    Text(
                      'Current semester: ${studentNotifier.currentSemester!.semesterName}',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Semester info banner
              if (studentNotifier.currentSemester != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Course data from: ${studentNotifier.currentSemester!.semesterName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),

              // Courses list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: coursesBySemester.length,
                  itemBuilder: (context, index) {
                    final semester = coursesBySemester.keys.elementAt(index);
                    final courses = coursesBySemester[semester]!;
                    final totalCredits = studentNotifier
                        .getTotalCreditsForSemester(semester);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          semester,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${courses.length} courses • ${totalCredits.toStringAsFixed(1)} credits',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        children:
                            courses.map((course) {
                              final courseWithDetails = studentNotifier
                                  .getCourseWithDetails(
                                    semester,
                                    course.courseId,
                                  );
                              return CourseListItem(
                                semesterKey: semester,
                                courseWithDetails: courseWithDetails,
                                onRefresh:
                                    () => studentNotifier.refreshCourseDetails(
                                      course.courseId,
                                    ),
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCourseSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => CourseSearchDialog(searchController: searchController),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final courseIdController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Course Manually'),
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

                  final now = DateTime.now();
                  final season = _getSeason(now.month);
                  final semesterName = '$season ${now.year}';

                  final success = await context
                      .read<StudentNotifier>()
                      .addCourseToSemester(semesterName, course);

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

  String _getSeason(int month) {
    if (month <= 2 || month == 12) return 'Winter';
    if (month >= 3 && month <= 6) return 'Spring';
    return 'Summer';
  }
}

class CourseSearchDialog extends StatefulWidget {
  final TextEditingController searchController;

  const CourseSearchDialog({super.key, required this.searchController});

  @override
  State<CourseSearchDialog> createState() => _CourseSearchDialogState();
}

class _CourseSearchDialogState extends State<CourseSearchDialog> {
  List<CourseSearchResult> searchResults = [];
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search courses',
                      hintText: 'Course ID or name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _performSearch(widget.searchController.text),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSearching)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (searchResults.isEmpty &&
                widget.searchController.text.isNotEmpty)
              const Expanded(child: Center(child: Text('No courses found')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    final course = result.course;

                    return Card(
                      child: ListTile(
                        title: Text('${course.courseNumber} - ${course.name}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Faculty: ${course.faculty}'),
                            Text('Credits: ${course.points}'),
                            if (course.hasPrerequisites)
                              Text(
                                'Prerequisites: ${course.prerequisites}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _addCourse(course),
                          child: const Text('Add'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isSearching = true;
    });

    try {
      final results = await context.read<StudentNotifier>().searchCourses(
        courseId: query.contains(RegExp(r'\d')) ? query : null,
        courseName: !query.contains(RegExp(r'\d')) ? query : null,
      );

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  void _addCourse(EnhancedCourseDetails courseDetails) async {
    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
    );
    final now = DateTime.now();
    final season = _getSeason(now.month);
    final semester = '$season ${now.year}';

    final success = await context.read<StudentNotifier>().addCourseToSemester(
      semester,
      course,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course added successfully!'),
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

  String _getSeason(int month) {
    if (month <= 2 || month == 12) return 'Winter';
    if (month >= 3 && month <= 6) return 'Spring';
    return 'Summer';
  }
}

class CourseListItem extends StatelessWidget {
  final String semesterKey;
  final StudentCourseWithDetails? courseWithDetails;
  final VoidCallback? onRefresh;

  const CourseListItem({
    super.key,
    required this.semesterKey,
    required this.courseWithDetails,
    this.onRefresh,
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
    final isLoading = courseDetails == null;

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
                    if (isLoading) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Loading course details...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (onRefresh != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onRefresh,
                              child: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Text(
                        courseDetails!.faculty,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (courseDetails!.points.isNotEmpty)
                        Text(
                          '${courseDetails!.points} נקודות',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (studentCourse.finalGrade.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          if (!isLoading && courseDetails != null) ...[
            const SizedBox(height: 8),

            // Prerequisites
            if (courseDetails.hasPrerequisites)
              Text(
                'Prerequisites: ${courseDetails.prerequisites}',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),

            // Syllabus (truncated)
            if (courseDetails.syllabus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Syllabus: ${courseDetails.syllabus.length > 100 ? '${courseDetails.syllabus.substring(0, 100)}...' : courseDetails.syllabus}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],

            // Schedule info
            if (courseDetails.schedule.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Schedule: ${courseDetails.schedule.length} time slots',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              ...courseDetails.schedule
                  .take(2)
                  .map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '${schedule.type}: ${schedule.day} ${schedule.time} (${schedule.fullLocation})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              if (courseDetails.schedule.length > 2)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    '...more times',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],

            // Exams info
            if (courseDetails.hasExams) ...[
              const SizedBox(height: 4),
              Text(
                'Exams: ${courseDetails.exams.keys.join(', ')}',
                style: const TextStyle(fontSize: 11, color: Colors.purple),
              ),
            ],
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
      builder:
          (context) => AlertDialog(
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

                  final success = await context
                      .read<StudentNotifier>()
                      .updateCourseGrade(
                        semesterKey,
                        courseWithDetails!.studentCourse.courseId,
                        grade,
                      );

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
