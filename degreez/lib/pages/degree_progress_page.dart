// lib/pages/degree_progress_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';
import '../services/course_service.dart';

class DegreeProgressPage extends StatelessWidget {
  const DegreeProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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

          final semesters = studentNotifier.coursesBySemester;

          if (semesters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No courses to display',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add courses to see your degree progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Detect device orientation
          final orientation = MediaQuery.of(context).orientation;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with degree progress summary
                _buildProgressHeader(context, studentNotifier),

                // Semester list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final semesterKey = semesters.keys.elementAt(index);
                      final semester = {
                        'semester': index + 1,
                        'name': semesterKey,
                        'courses': semesters[semesterKey]!,
                      };

                      return orientation == Orientation.portrait
                          ? _buildVerticalSemesterSection(
                            context,
                            semester,
                            studentNotifier,
                          )
                          : _buildHorizontalSemesterSection(
                            context,
                            semester,
                            studentNotifier,
                          );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSemesterDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

void _showAddSemesterDialog(BuildContext context) {
  // Auto-select season based on the current month
  final month = DateTime.now().month;
  String selectedSeason;
  if (month <= 2) {
    selectedSeason = 'Winter';
  } else if (month <= 6) {
    selectedSeason = 'Spring';
  } else {
    selectedSeason = 'Summer';
  }

  int selectedYear = DateTime.now().year;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Semester'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Season dropdown
                DropdownButtonFormField<String>(
                  value: selectedSeason,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: ['Winter', 'Spring', 'Summer'].map((season) {
                    return DropdownMenuItem<String>(
                      value: season,
                      child: Text(season),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSeason = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Year dropdown: from 5 years ago to 5 years ahead
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: List.generate(11, (index) {
                    int year = DateTime.now().year - 5 + index;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final semesterName = '$selectedSeason $selectedYear';
                  Provider.of<StudentNotifier>(context, listen: false)
                      .addSemester(semesterName, context);
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Widget _buildProgressHeader(
    BuildContext context,
    StudentNotifier studentNotifier,
  ) {
    final totalCourses =
        studentNotifier.coursesBySemester.values
            .expand((courses) => courses)
            .length;

    final totalCredits = studentNotifier.coursesBySemester.keys
        .map((semester) => studentNotifier.getTotalCreditsForSemester(semester))
        .fold<double>(0.0, (sum, credits) => sum + credits);

    final completedCourses =
        studentNotifier.coursesBySemester.values
            .expand((courses) => courses)
            .where((course) => course.finalGrade.isNotEmpty)
            .length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Degree Progress',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          if (studentNotifier.student != null) ...[
            const SizedBox(height: 8),
            Text(
              '${studentNotifier.student!.major} - ${studentNotifier.student!.faculty}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Progress summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Courses',
                  totalCourses.toString(),
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Credits',
                  totalCredits.toStringAsFixed(1),
                  Icons.star,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Completed',
                  completedCourses.toString(),
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Vertical layout for portrait mode
  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentNotifier studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = studentNotifier.getTotalCreditsForSemester(
      semesterName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                semesterName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalCredits.toStringAsFixed(1)} credits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid of courses
        courses.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No courses in this semester',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
            : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final courseWithDetails = studentNotifier.getCourseWithDetails(
                  semesterName,
                  course.courseId,
                );
                return _buildCourseCard(
                  context,
                  course,
                  courseWithDetails?.courseDetails,
                );
              },
            ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  // Horizontal layout for landscape mode
  Widget _buildHorizontalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentNotifier studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = studentNotifier.getTotalCreditsForSemester(
      semesterName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                semesterName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${totalCredits.toStringAsFixed(1)} credits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal row of courses
        courses.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No courses in this semester',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
            : SizedBox(
              height: 120,
              child: Row(
                children: List.generate(courses.length, (index) {
                  final course = courses[index];
                  final courseWithDetails = studentNotifier
                      .getCourseWithDetails(semesterName, course.courseId);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildHorizontalCourseCard(
                        context,
                        course,
                        courseWithDetails?.courseDetails,
                      ),
                    ),
                  );
                }),
              ),
            ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  // Vertical course card for portrait mode
  Widget _buildCourseCard(
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    course.courseId,
                    style: const TextStyle(
                      fontSize: 11,
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
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      courseDetails.points,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              course.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasGrade) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.grade, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getGradeColor(course.finalGrade),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.finalGrade,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Horizontal course card for landscape mode
  Widget _buildHorizontalCourseCard(
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
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.red.shade700,
      Colors.indigo.shade700,
      Colors.cyan.shade700,
      Colors.deepPurple.shade700,
      Colors.brown.shade700,
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
