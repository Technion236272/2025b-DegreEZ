// lib/pages/degree_progress_page.dart - Updated for new providers
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../services/course_service.dart';
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
    return ChangeNotifierProvider(
      create: (ctx) => CustomizedDiagramNotifier(),
      child: Scaffold(
        backgroundColor: AppColorsDarkMode.mainColor,
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
                    Text('Loading degree progress...'),
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
                  // Header with degree progress summary only in portrait mode
                  if (orientation == Orientation.portrait)
                    _buildProgressHeader(context, studentProvider, courseProvider, courseDataProvider),

                  // Semester navigation and courses
                  Expanded(
                    child: _buildSemesterView(
                      context, 
                      semesters, 
                      orientation, 
                      courseDataProvider,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, List<StudentCourse>> _getSortedCoursesBySemester(
    Map<String, List<StudentCourse>> coursesBySemester,
  ) {
    final List<String> semesterNames = coursesBySemester.keys.toList();

    semesterNames.sort((a, b) {
      final parsedA = _parseSemester(a);
      final parsedB = _parseSemester(b);

      final yearComparison = parsedA.year.compareTo(parsedB.year);
      if (yearComparison != 0) return yearComparison;

      return _seasonOrder(parsedA.season).compareTo(_seasonOrder(parsedB.season));
    });

    return {for (final name in semesterNames) name: coursesBySemester[name]!};
  }

  int _seasonOrder(String season) {
    switch (season.toLowerCase()) {
      case 'winter':
        return 1;
      case 'spring':
        return 2;
      case 'summer':
        return 3;
      default:
        return 99;
    }
  }

  ({String season, int year}) _parseSemester(String semesterName) {
    final parts = semesterName.split(' ');
    final season = parts[0];
    final year = (parts.length > 1) ? int.tryParse(parts[1]) ?? 0 : 0;
    return (season: season, year: year);
  }

  Widget _buildProgressHeader(
    BuildContext context,
    StudentProvider studentProvider,
    CourseProvider courseProvider,
    CourseDataProvider courseDataProvider,
  ) {
    final student = studentProvider.student;
    final totalCourses = courseProvider.coursesBySemester.values
        .fold<int>(0, (sum, courses) => sum + courses.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsDarkMode.secondaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${student?.name ?? "Student"}\'s Degree Progress',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsDarkMode.secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${student?.major ?? "Unknown Major"} • ${student?.faculty ?? "Unknown Faculty"}',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsDarkMode.secondaryColorDim,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Courses',
                  totalCourses.toString(),
                  Icons.school,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Semesters',
                  courseProvider.coursesBySemester.length.toString(),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.mainColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorsDarkMode.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColorsDarkMode.accentColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsDarkMode.secondaryColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColorsDarkMode.secondaryColorDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterView(
    BuildContext context,
    Map<String, List<StudentCourse>> semesters,
    Orientation orientation,
    CourseDataProvider courseDataProvider,
  ) {
    return DefaultTabController(
      length: semesters.length,
      child: Column(
        children: [
          // Semester tabs
          Container(
            color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
            child: TabBar(
              isScrollable: true,
              indicatorColor: AppColorsDarkMode.accentColor,
              labelColor: AppColorsDarkMode.secondaryColor,
              unselectedLabelColor: AppColorsDarkMode.secondaryColorDim,
              tabs: semesters.keys.map((semester) {
                final courses = semesters[semester]!;
                return Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(semester),
                      Text(
                        '${courses.length} courses',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Semester content
          Expanded(
            child: TabBarView(
              children: semesters.entries.map((entry) {
                final semesterName = entry.key;
                final courses = entry.value;
                
                return _buildCoursesGrid(
                  context,
                  semesterName,
                  courses,
                  orientation,
                  courseDataProvider,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesGrid(
    BuildContext context,
    String semesterName,
    List<StudentCourse> courses,
    Orientation orientation,
    CourseDataProvider courseDataProvider,
  ) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: AppColorsDarkMode.secondaryColorDim,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses in $semesterName',
              style: TextStyle(
                fontSize: 18,
                color: AppColorsDarkMode.secondaryColorDim,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add courses to this semester',
              style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = orientation == Orientation.landscape ? 4 : 2;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(context, course, courseDataProvider);
        },
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    StudentCourse course,
    CourseDataProvider courseDataProvider,
  ) {
    return Consumer<CustomizedDiagramNotifier>(
      builder: (context, customizedNotifier, child) {
        return FutureBuilder<EnhancedCourseDetails?>(
          future: courseDataProvider.getCourseDetails(course.courseId),
          builder: (context, snapshot) {
            final courseDetails = snapshot.data;
            
            return CourseCard(
              courseId: course.courseId,
              courseName: course.name,
              creditPoints: courseDetails?.creditPoints ?? 0.0,
              finalGrade: course.finalGrade,
              colorPalette: customizedNotifier.cardColorPalette!,
              onTap: () => _showCourseDetailsDialog(context, course, courseDetails, snapshot),
            );
          },
        );
      },
    );
  }

  void _showCourseDetailsDialog(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails,
    AsyncSnapshot<EnhancedCourseDetails?> snapshot,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Course ID: ${course.courseId}'),
              if (course.finalGrade.isNotEmpty)
                Text('Grade: ${course.finalGrade}'),
              if (course.note?.isNotEmpty == true)
                Text('Note: ${course.note}'),
              
              if (courseDetails != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Course Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Faculty: ${courseDetails.faculty}'),
                Text('Credits: ${courseDetails.creditPoints}'),
                Text('Academic Level: ${courseDetails.academicLevel}'),
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
              ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading course details...'),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  'Course details not available',
                  style: TextStyle(color: Colors.grey),
                ),
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
}
