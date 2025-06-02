// lib/pages/degree_progress_page.dart
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../widgets/course_card.dart';
import '../models/student_model.dart';

class DegreeProgressPage extends StatefulWidget {
  const DegreeProgressPage({super.key});

  @override
  State<DegreeProgressPage> createState() => _DegreeProgressPageState();
}

class _DegreeProgressPageState extends State<DegreeProgressPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Consumer4<StudentProvider, CourseProvider, CourseDataProvider, CustomizedDiagramNotifier>(
        builder: (context, studentProvider, courseProvider, courseDataProvider, diagramNotifier, _) {
          if (studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentProvider.error != null || courseProvider.error != null) {
            final error = studentProvider.error ?? courseProvider.error!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final semesters = _getSortedCoursesBySemester(courseProvider.coursesBySemester);

          if (semesters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: AppColorsDarkMode.secondaryColorDim),
                  SizedBox(height: 16),
                  Text(
                    'No courses to display',
                    style: TextStyle(fontSize: 18, color: AppColorsDarkMode.secondaryColorDim),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add courses to see your degree progress',
                    style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
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
                // Header with degree progress summary only in portrait mode.
                if (orientation == Orientation.portrait)
                  _buildProgressHeader(context, studentProvider, courseProvider),

                Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text(
                    "Tap for details • Long press for notes • Use + to add courses",
                    style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                  ),
                ),
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
                              studentProvider,
                              courseProvider,
                              courseDataProvider,
                            )
                          : _buildHorizontalSemesterSection(
                              context,
                              semester,
                              studentProvider,
                              courseProvider,
                              courseDataProvider,
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
        backgroundColor: AppColorsDarkMode.accentColor,
        foregroundColor: AppColorsDarkMode.secondaryColor,
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
                    _addSemester(context, semesterName);
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

  Future<void> _addSemester(BuildContext context, String semesterName) async {
    final studentProvider = context.read<StudentProvider>();
    
    if (studentProvider.hasStudent) {
      // For now, we'll just add an empty semester structure
      // You can extend this to add actual semester metadata to Firestore if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semester "$semesterName" created. You can now add courses to it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildProgressHeader(
    BuildContext context,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
  ) {
    final totalCourses = courseProvider.coursesBySemester.values
        .expand((courses) => courses)
        .length;

    final totalCredits = _calculateTotalCredits(courseProvider);

    final completedCourses = courseProvider.coursesBySemester.values
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
          Consumer<CustomizedDiagramNotifier>(
            builder: (context, diagramNotifier, _) {
              return IconButton(
                onPressed: diagramNotifier.switchPalette,
                icon: Icon(
                  Icons.palette,
                  color: AppColorsDarkMode.secondaryColor,
                ),
              );
            },
          ),

          if (studentProvider.hasStudent) ...[
            const SizedBox(height: 8),
            Text(
              '${studentProvider.student!.major} - ${studentProvider.student!.faculty}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateTotalCredits(CourseProvider courseProvider) {
    // Simplified calculation - assuming average 3.5 credits per course
    // You can enhance this by fetching actual credit values from course details
    return courseProvider.coursesBySemester.values
        .fold<double>(0, (sum, courses) => sum + (courses.length * 3.5));
  }

  Map<String, List<StudentCourse>> _getSortedCoursesBySemester(
    Map<String, List<StudentCourse>> coursesBySemester,
  ) {
    final sortedKeys = coursesBySemester.keys.toList()..sort(_compareSemesters);
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, coursesBySemester[key]!)),
    );
  }

  int _compareSemesters(String a, String b) {
    // Parse semester strings and sort them chronologically
    // Handle formats like "Winter 2024", "Spring 2024-25", etc.
    final seasonOrder = {'Winter': 1, 'Spring': 2, 'Summer': 3};
    
    final aParts = a.split(' ');
    final bParts = b.split(' ');
    
    if (aParts.length < 2 || bParts.length < 2) return a.compareTo(b);
    
    final aSeason = aParts[0];
    final bSeason = bParts[0];
    final aYear = int.tryParse(aParts[1].split('-')[0]) ?? 0;
    final bYear = int.tryParse(bParts[1].split('-')[0]) ?? 0;
    
    if (aYear != bYear) return aYear.compareTo(bYear);
    
    final aSeasonOrder = seasonOrder[aSeason] ?? 0;
    final bSeasonOrder = seasonOrder[bSeason] ?? 0;
    
    return aSeasonOrder.compareTo(bSeasonOrder);
  }

  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
    CourseDataProvider courseDataProvider,
  ) {
    final semesterName = semester['name'] as String;
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterCredits = _getSemesterCredits(courses);

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semesterName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                      Text(
                        '${courses.length} courses • ${semesterCredits.toStringAsFixed(1)} credits',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColorsDarkMode.secondaryColorDim,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add Course Button
                IconButton(
                  onPressed: () => _showAddCourseDialog(context, semesterName, studentProvider, courseProvider),
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColorsDarkMode.secondaryColor,
                    size: 28,
                  ),
                  tooltip: 'Add Course',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColorsDarkMode.secondaryColor,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteSemester(context, semesterName, studentProvider, courseProvider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Semester'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Courses grid
          Container(
            decoration: BoxDecoration(
              color: AppColorsDarkMode.mainColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: AppColorsDarkMode.accentColor,
                width: 1,
              ),
            ),
            child: courses.isNotEmpty
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Consumer<CustomizedDiagramNotifier>(
                        builder: (context, diagramNotifier, _) {
                          return GestureDetector(
                            onLongPress: () => _showNoteDialog(context, course, semesterName, studentProvider, courseProvider),
                            child: CourseCard(
                              courseId: course.courseId,
                              courseName: course.name,
                              creditPoints: 3.5, // Default credit points - you can fetch actual values
                              finalGrade: course.finalGrade,
                              colorPalette: diagramNotifier.cardColorPalette ?? CourseCardColorPalette1(),
                              onTap: () => _showCourseDetailsDialog(context, course, semesterName, studentProvider, courseProvider),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 48,
                            color: AppColorsDarkMode.secondaryColorDim,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No courses yet',
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColorDim,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first course',
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColorDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
    CourseDataProvider courseDataProvider,
  ) {
    final semesterName = semester['name'] as String;
    final courses = semester['courses'] as List<StudentCourse>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddCourseDialog(context, semesterName, studentProvider, courseProvider),
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColorsDarkMode.secondaryColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal course list
          SizedBox(
            height: 120,
            child: courses.isNotEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 8.0),
                        child: Consumer<CustomizedDiagramNotifier>(
                          builder: (context, diagramNotifier, _) {
                            return GestureDetector(
                              onLongPress: () => _showNoteDialog(context, course, semesterName, studentProvider, courseProvider),
                              child: CourseCard(
                                courseId: course.courseId,
                                courseName: course.name,
                                creditPoints: 3.5, // Default credit points
                                finalGrade: course.finalGrade,
                                colorPalette: diagramNotifier.cardColorPalette ?? CourseCardColorPalette1(),
                                onTap: () => _showCourseDetailsDialog(context, course, semesterName, studentProvider, courseProvider),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No courses yet - tap + to add',
                      style: TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getSemesterCredits(List<StudentCourse> courses) {
    // Simplified - assuming 3.5 credits per course
    return courses.length * 3.5;
  }

  void _showAddCourseDialog(BuildContext context, String semesterName, StudentProvider studentProvider, CourseProvider courseProvider) {
    final courseIdController = TextEditingController();
    final courseNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Course to $semesterName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseIdController,
                decoration: const InputDecoration(
                  labelText: 'Course ID',
                  hintText: 'e.g., 234123',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g., Data Structures',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (courseIdController.text.isNotEmpty && courseNameController.text.isNotEmpty) {
                  final newCourse = StudentCourse(
                    courseId: courseIdController.text.trim(),
                    name: courseNameController.text.trim(),
                    finalGrade: '',
                    lectureTime: '',
                    tutorialTime: '',
                  );
                  
                  if (studentProvider.hasStudent) {
                    final success = await courseProvider.addCourseToSemester(
                      studentProvider.student!.id,
                      semesterName,
                      newCourse,
                    );
                    
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${newCourse.name} to $semesterName'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showCourseDetailsDialog(BuildContext context, StudentCourse course, String semesterName, StudentProvider studentProvider, CourseProvider courseProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(course.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course ID: ${course.courseId}'),
              const SizedBox(height: 8),
              Text('Semester: $semesterName'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Grade: ${course.finalGrade.isEmpty ? 'Not graded' : course.finalGrade}'),
                  if (course.finalGrade.isEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 16, color: Colors.blue),
                  ],
                ],
              ),
              if (course.note != null && course.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${course.note}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditGradeDialog(context, course, semesterName, studentProvider, courseProvider);
              },
              child: const Text('Edit Grade'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showNoteDialog(context, course, semesterName, studentProvider, courseProvider);
              },
              child: const Text('Add Note'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRemoveCourseDialog(context, course, semesterName, studentProvider, courseProvider);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditGradeDialog(BuildContext context, StudentCourse course, String semesterName, StudentProvider studentProvider, CourseProvider courseProvider) {
    final gradeController = TextEditingController(text: course.finalGrade);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Grade - ${course.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: 'Final Grade',
                  hintText: 'e.g., 95, A+, Pass',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter any grade format (number, letter, pass/fail)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (studentProvider.hasStudent) {
                  await courseProvider.updateCourseGrade(
                    studentProvider.student!.id,
                    semesterName,
                    course.courseId,
                    gradeController.text.trim(),
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated grade for ${course.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveCourseDialog(BuildContext context, StudentCourse course, String semesterName, StudentProvider studentProvider, CourseProvider courseProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Course'),
          content: Text('Are you sure you want to remove "${course.name}" from $semesterName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Note: You'll need to implement course removal in CourseProvider
                // For now, we'll show a placeholder message
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course removal not yet implemented'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showNoteDialog(
    BuildContext context,
    StudentCourse course,
    String semesterName,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
  ) {
    final noteController = TextEditingController(text: course.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Note - ${course.name}'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: 'Enter your note...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (studentProvider.hasStudent) {
                  await courseProvider.updateCourseNote(
                    studentProvider.student!.id,
                    semesterName,
                    course.courseId,
                    noteController.text,
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSemester(
    BuildContext context,
    String semesterName,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Semester'),
          content: Text('Are you sure you want to delete "$semesterName" and all its courses?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Note: You'll need to implement semester deletion in CourseProvider
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semester deletion not yet implemented'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
