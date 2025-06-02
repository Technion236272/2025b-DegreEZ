// lib/pages/degree_progress_page.dart - With Color Theme Toggle
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/color_theme_provider.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Degree Progress', style: TextStyle(color: Colors.white)),
        actions: [
          // Color Theme Toggle Button
          Consumer<ColorThemeProvider>(
            builder: (context, colorThemeProvider, _) {
              return PopupMenuButton<String>(
                icon: Icon(
                  colorThemeProvider.currentThemeIcon,
                  color: Colors.white,
                ),
                onSelected: (value) {
                  if (value == 'toggle') {
                    colorThemeProvider.toggleColorMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to ${colorThemeProvider.currentThemeName}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          colorThemeProvider.isColorful ? Icons.style : Icons.palette,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Switch to ${colorThemeProvider.isColorful ? 'Classic' : 'Colorful'} Theme',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Current: ${colorThemeProvider.currentThemeName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer4<StudentProvider, CourseProvider, CourseDataProvider, ColorThemeProvider>(
        builder: (context, studentProvider, courseProvider, courseDataProvider, colorThemeProvider, _) {
          // Handle loading states
          if (studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading degree progress...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          // Handle no student data
          if (!studentProvider.hasStudent) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No student data available', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(studentProvider.student!),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  _buildStatsCards(courseProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Instruction Text
                  const Center(
                    child: Text(
                      'Press and hold down on a course to add notes to it',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Semesters
                  _buildSemesters(courseProvider, courseDataProvider, colorThemeProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(StudentModel student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${student.major} - ${_getShortFacultyName(student.faculty)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getShortFacultyName(String faculty) {
    // Convert full faculty names to short versions
    if (faculty.toLowerCase().contains('computer')) return 'CS';
    if (faculty.toLowerCase().contains('engineering')) return 'ENG';
    if (faculty.toLowerCase().contains('science')) return 'SCI';
    if (faculty.toLowerCase().contains('medicine')) return 'MED';
    if (faculty.toLowerCase().contains('management')) return 'MNG';
    return faculty.length > 3 ? faculty.substring(0, 3).toUpperCase() : faculty.toUpperCase();
  }

  Widget _buildStatsCards(CourseProvider courseProvider) {
    final totalCourses = courseProvider.coursesBySemester.values
        .fold<int>(0, (sum, courses) => sum + courses.length);
    
    final totalCredits = _calculateTotalCredits(courseProvider);
    final completedCourses = _calculateCompletedCourses(courseProvider);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Courses',
            totalCourses.toString(),
            Icons.school,
            Colors.blue.shade800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Credits',
            totalCredits.toString(),
            Icons.star,
            Colors.green.shade800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            completedCourses.toString(),
            Icons.check_circle,
            Colors.orange.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateTotalCredits(CourseProvider courseProvider) {
    // This is a simplified calculation - you might want to fetch actual credit values
    // from the course details API for more accuracy
    return courseProvider.coursesBySemester.values
        .fold<double>(0, (sum, courses) => sum + (courses.length * 3.5)); // Assuming average 3.5 credits per course
  }

  int _calculateCompletedCourses(CourseProvider courseProvider) {
    return courseProvider.coursesBySemester.values
        .fold<int>(0, (sum, courses) => 
            sum + courses.where((course) => course.finalGrade.isNotEmpty).length);
  }

  Widget _buildSemesters(CourseProvider courseProvider, CourseDataProvider courseDataProvider, ColorThemeProvider colorThemeProvider) {
    final semesters = _getSortedSemesters(courseProvider.coursesBySemester);
    
    if (semesters.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses added yet',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add courses to see your degree progress',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: semesters.entries.map((entry) {
        final semesterName = entry.key;
        final courses = entry.value;
        final semesterCredits = _calculateSemesterCredits(courses);
        
        return _buildSemesterSection(
          semesterName,
          courses,
          semesterCredits,
          courseDataProvider,
          colorThemeProvider,
        );
      }).toList(),
    );
  }

  Map<String, List<StudentCourse>> _getSortedSemesters(Map<String, List<StudentCourse>> coursesBySemester) {
    final sortedKeys = coursesBySemester.keys.toList()..sort((a, b) {
      // Sort semesters chronologically
      final aYear = _extractYear(a);
      final bYear = _extractYear(b);
      
      if (aYear != bYear) {
        return aYear.compareTo(bYear);
      }
      
      return _getSemesterOrder(a).compareTo(_getSemesterOrder(b));
    });
    
    return {for (String key in sortedKeys) key: coursesBySemester[key]!};
  }

  int _extractYear(String semesterName) {
    final parts = semesterName.split(' ');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  int _getSemesterOrder(String semesterName) {
    final lowerName = semesterName.toLowerCase();
    if (lowerName.contains('winter')) return 1;
    if (lowerName.contains('spring')) return 2;
    if (lowerName.contains('summer')) return 3;
    return 4;
  }

  double _calculateSemesterCredits(List<StudentCourse> courses) {
    // Simplified calculation - you might want to fetch actual credit values
    return courses.length * 3.5; // Assuming average 3.5 credits per course
  }

  Widget _buildSemesterSection(
    String semesterName,
    List<StudentCourse> courses,
    double credits,
    CourseDataProvider courseDataProvider,
    ColorThemeProvider colorThemeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade600),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${credits.toStringAsFixed(1)} credits',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addCourseToSemester(semesterName),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deleteSemester(semesterName),
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Course Cards
          if (courses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No courses in this semester',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: courses.map((course) => _buildCourseCard(course, colorThemeProvider)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(StudentCourse course, ColorThemeProvider colorThemeProvider) {
    final courseColor = colorThemeProvider.getCourseColor(course.courseId);
    
    return GestureDetector(
      onLongPress: () => _showCourseNoteDialog(course),
      child: Container(
        width: 140,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: courseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: courseColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course ID
            Text(
              course.courseId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Course Name
            Expanded(
              child: Text(
                course.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Grade indicator
            if (course.finalGrade.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getGradeColor(course.finalGrade),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.finalGrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.isEmpty) return Colors.grey;
    
    final numericGrade = int.tryParse(grade);
    if (numericGrade != null) {
      if (numericGrade >= 90) return Colors.green.shade600;
      if (numericGrade >= 80) return Colors.blue.shade600;
      if (numericGrade >= 70) return Colors.orange.shade600;
      return Colors.red.shade600;
    }
    
    // Handle letter grades
    switch (grade.toUpperCase()) {
      case 'A': case 'A+': return Colors.green.shade600;
      case 'B': case 'B+': return Colors.blue.shade600;
      case 'C': case 'C+': return Colors.orange.shade600;
      default: return Colors.red.shade600;
    }
  }

  void _addCourseToSemester(String semesterName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add course to $semesterName - Coming soon!'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  void _deleteSemester(String semesterName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete Semester', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$semesterName" and all its courses?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteSemester(semesterName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDeleteSemester(String semesterName) {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (studentProvider.hasStudent) {
      courseProvider.deleteSemester(studentProvider.student!.id, semesterName);
    }
  }

  void _showCourseNoteDialog(StudentCourse course) {
    final noteController = TextEditingController(text: course.note ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Add Note - ${course.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveNote(course, noteController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveNote(StudentCourse course, String note) {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();
    
    if (!studentProvider.hasStudent) return;

    // Find which semester this course belongs to
    String? targetSemester;
    for (final entry in courseProvider.coursesBySemester.entries) {
      if (entry.value.any((c) => c.courseId == course.courseId)) {
        targetSemester = entry.key;
        break;
      }
    }

    if (targetSemester != null) {
      courseProvider.updateCourseNote(
        studentProvider.student!.id,
        targetSemester,
        course.courseId,
        note,
      );
    }
  }
}
