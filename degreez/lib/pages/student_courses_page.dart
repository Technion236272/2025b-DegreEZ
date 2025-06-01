// pages/student_courses_page.dart - Updated for new providers
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';

class StudentCoursesPage extends StatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  State<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends State<StudentCoursesPage> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (studentProvider.hasStudent) {
      await courseProvider.loadStudentCourses(studentProvider.student!.id);
    }
  }

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
      body: Consumer3<StudentProvider, CourseProvider, CourseDataProvider>(
        builder: (context, studentProvider, courseProvider, courseDataProvider, _) {
          // Handle loading states
          if (studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading courses...'),
                ],
              ),
            );
          }

          // Handle errors
          if (studentProvider.error != null || courseProvider.error != null) {
            final error = studentProvider.error ?? courseProvider.error!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!studentProvider.hasStudent) {
            return const Center(
              child: Text('No student data available'),
            );
          }

          final coursesBySemester = courseProvider.coursesBySemester;

          if (coursesBySemester.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 64, color: Colors.grey),
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
                  if (courseDataProvider.currentSemester != null)
                    Text(
                      'Current semester: ${courseDataProvider.currentSemester!.semesterName}',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Semester info banner
              if (courseDataProvider.currentSemester != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Course data from: ${courseDataProvider.currentSemester!.semesterName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),

              // Courses list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: coursesBySemester.length,
                    itemBuilder: (context, index) {
                      final semester = coursesBySemester.keys.elementAt(index);
                      final courses = coursesBySemester[semester]!;
                      final totalCredits = _getTotalCreditsForSemester(
                        semester, 
                        courses, 
                        courseDataProvider,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  semester,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'add_semester') {
                                    _showAddSemesterDialog(context);
                                  } else if (value == 'delete_semester') {
                                    _deleteSemester(context, semester);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'add_semester',
                                    child: Text('Add New Semester'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete_semester',
                                    child: Text('Delete Semester'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: FutureBuilder<double>(
                            future: totalCredits,
                            builder: (context, snapshot) {
                              final credits = snapshot.data ?? 0.0;
                              return Text(
                                '${courses.length} courses • ${credits.toStringAsFixed(1)} credits',
                                style: const TextStyle(color: Colors.grey),
                              );
                            },
                          ),
                          children: [
                            ...courses.map((course) => _buildCourseCard(
                              context, 
                              semester, 
                              course, 
                              courseDataProvider,
                            )),
                            // Add course button
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddCourseToSemesterDialog(context, semester),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Course'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          return FloatingActionButton(
            onPressed: courseProvider.loadingState.isAddingCourse 
                ? null 
                : () => _showAddSemesterDialog(context),
            child: courseProvider.loadingState.isAddingCourse
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, 
    String semester, 
    StudentCourse course,
    CourseDataProvider courseDataProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('ID: ${course.courseId}'),
                      if (course.finalGrade.isNotEmpty)
                        Text('Grade: ${course.finalGrade}'),
                      if (course.note?.isNotEmpty == true)
                        Text('Note: ${course.note}'),
                    ],
                  ),
                ),
                Consumer<CourseProvider>(
                  builder: (context, courseProvider, child) {
                    final isUpdating = courseProvider.loadingState.updatingGrades[course.courseId] ?? false;
                    
                    return Row(
                      children: [
                        if (isUpdating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditGradeDialog(context, semester, course),
                          ),
                        IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () => _showCourseDetailsDialog(context, course.courseId, courseDataProvider),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            
            // Course details from API
            FutureBuilder<EnhancedCourseDetails?>(
              future: courseDataProvider.getCourseDetails(course.courseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                        SizedBox(width: 8),
                        Text('Loading details...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError || snapshot.data == null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Details unavailable', style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () => courseDataProvider.invalidateCourseCache(course.courseId),
                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }
                
                final details = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credits: ${details.creditPoints} • Faculty: ${details.faculty}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (details.scheduleString.isNotEmpty)
                        Text(
                          'Schedule: ${details.scheduleString}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _getTotalCreditsForSemester(
    String semester, 
    List<StudentCourse> courses,
    CourseDataProvider courseDataProvider,
  ) async {
    double total = 0.0;
    
    for (final course in courses) {
      try {
        final details = await courseDataProvider.getCourseDetails(course.courseId);
        if (details != null) {
          total += details.creditPoints;
        }
      } catch (e) {
        // Ignore errors for individual courses
      }
    }
    
    return total;
  }

  void _showCourseSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: _CourseSearchWidget(
            onCourseSelected: (course) {
              Navigator.pop(context);
              _showAddCourseFromSearchDialog(context, course);
            },
          ),
        ),
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final courseIdController = TextEditingController();
    final courseNameController = TextEditingController();
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Course Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseIdController,
              decoration: const InputDecoration(labelText: 'Course ID'),
            ),
            TextField(
              controller: courseNameController,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
            TextField(
              controller: semesterController,
              decoration: const InputDecoration(labelText: 'Semester'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (courseIdController.text.isNotEmpty && 
                  courseNameController.text.isNotEmpty &&
                  semesterController.text.isNotEmpty) {
                _addCourseManually(
                  context,
                  semesterController.text,
                  courseIdController.text,
                  courseNameController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSemesterDialog(BuildContext context) {
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Semester'),
        content: TextField(
          controller: semesterController,
          decoration: const InputDecoration(
            labelText: 'Semester Name',
            hintText: 'e.g., Winter 2024, Spring 2025',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (semesterController.text.isNotEmpty) {
                _addSemester(context, semesterController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCourseToSemesterDialog(BuildContext context, String semester) {
    _showCourseSearchDialog(context);
  }

  void _showAddCourseFromSearchDialog(BuildContext context, EnhancedCourseDetails courseDetails) {
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${courseDetails.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course ID: ${courseDetails.courseNumber}'),
            Text('Credits: ${courseDetails.creditPoints}'),
            Text('Faculty: ${courseDetails.faculty}'),
            const SizedBox(height: 16),
            TextField(
              controller: semesterController,
              decoration: const InputDecoration(
                labelText: 'Semester',
                hintText: 'e.g., Winter 2024',
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
            onPressed: () {
              if (semesterController.text.isNotEmpty) {
                _addCourseFromSearch(context, semesterController.text, courseDetails);
                Navigator.pop(context);
              }
            },
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  void _showEditGradeDialog(BuildContext context, String semester, StudentCourse course) {
    final gradeController = TextEditingController(text: course.finalGrade);
    final noteController = TextEditingController(text: course.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${course.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade',
                hintText: 'Enter grade (e.g., 85, A, Pass)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note about this course',
              ),
              maxLines: 2,
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
              final studentProvider = context.read<StudentProvider>();
              final courseProvider = context.read<CourseProvider>();
              
              if (studentProvider.hasStudent) {
                await courseProvider.updateCourseGrade(
                  studentProvider.student!.id,
                  semester,
                  course.courseId,
                  gradeController.text,
                );
                
                if (noteController.text != course.note) {
                  await courseProvider.updateCourseNote(
                    studentProvider.student!.id,
                    semester,
                    course.courseId,
                    noteController.text,
                  );
                }
              }
              
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCourseDetailsDialog(BuildContext context, String courseId, CourseDataProvider courseDataProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: FutureBuilder<EnhancedCourseDetails?>(
            future: courseDataProvider.getCourseDetails(courseId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final details = snapshot.data;
              if (details == null) {
                return const Center(child: Text('Course details not available'));
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          details.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Course Number', details.courseNumber),
                          _buildDetailRow('Faculty', details.faculty),
                          _buildDetailRow('Credit Points', details.creditPoints.toString()),
                          _buildDetailRow('Academic Level', details.academicLevel),
                          if (details.prerequisites.isNotEmpty)
                            _buildDetailRow('Prerequisites', details.prerequisites),
                          if (details.syllabus.isNotEmpty)
                            _buildDetailRow('Syllabus', details.syllabus),
                          if (details.schedule.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Schedule:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...details.schedule.map((schedule) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${schedule.type}: ${schedule.day} ${schedule.time} (${schedule.fullLocation})',
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _addCourseManually(
    BuildContext context, 
    String semester, 
    String courseId, 
    String courseName,
  ) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (!studentProvider.hasStudent) return;

    final course = StudentCourse(
      courseId: courseId,
      name: courseName,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
    );

    final success = await courseProvider.addCourseToSemester(
      studentProvider.student!.id,
      semester,
      course,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    }
  }

  Future<void> _addCourseFromSearch(
    BuildContext context, 
    String semester, 
    EnhancedCourseDetails courseDetails,
  ) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (!studentProvider.hasStudent) return;

    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
    );

    final success = await courseProvider.addCourseToSemester(
      studentProvider.student!.id,
      semester,
      course,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    }
  }

  Future<void> _addSemester(BuildContext context, String semesterName) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (!studentProvider.hasStudent) return;

    final success = await courseProvider.addSemester(
      studentProvider.student!.id,
      semesterName,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semester "$semesterName" added successfully')),
      );
    }
  }

  Future<void> _deleteSemester(BuildContext context, String semesterName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text('Are you sure you want to delete "$semesterName"? This will remove all courses in this semester.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final studentProvider = context.read<StudentProvider>();
      final courseProvider = context.read<CourseProvider>();
      
      if (!studentProvider.hasStudent) return;

      final success = await courseProvider.deleteSemester(
        studentProvider.student!.id,
        semesterName,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semester "$semesterName" deleted')),
        );
      }
    }
  }
}

class _CourseSearchWidget extends StatefulWidget {
  final Function(EnhancedCourseDetails) onCourseSelected;

  const _CourseSearchWidget({
    required this.onCourseSelected,
  });

  @override
  State<_CourseSearchWidget> createState() => _CourseSearchWidgetState();
}

class _CourseSearchWidgetState extends State<_CourseSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDataProvider>(
      builder: (context, courseDataProvider, _) {
        return Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses by name or ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                            });
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _performSearch(courseDataProvider, value);
                  } else {
                    setState(() {
                      _searchResults.clear();
                    });
                  }
                },
              ),
            ),
            
            // Search results
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text('Search for courses to see results'),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(result.course.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${result.course.courseNumber}'),
                                Text('Faculty: ${result.course.faculty}'),
                                Text('Points: ${result.course.points}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                widget.onCourseSelected(result.course);
                              },
                              child: const Text('Select'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(CourseDataProvider courseDataProvider, String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      if (courseDataProvider.currentSemester == null) {
        await courseDataProvider.fetchCurrentSemester();
      }

      if (courseDataProvider.currentSemester != null) {
        final results = await CourseService.searchCourses(
          year: courseDataProvider.currentSemester!.year,
          semester: courseDataProvider.currentSemester!.semester,
          courseName: query.contains(RegExp(r'[a-zA-Z]')) ? query : null,
          courseId: query.contains(RegExp(r'[0-9]')) ? query : null,
        );

        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
}
