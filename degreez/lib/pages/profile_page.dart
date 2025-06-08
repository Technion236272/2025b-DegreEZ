import 'package:degreez/color/color_palette2.dart';
import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/widgets/bug_report_popup.dart';
import 'package:degreez/widgets/profile/profile_info_row.dart';
import 'package:degreez/widgets/profile/stat_card.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  // Calculate GPA from completed courses
  double _calculateGPA(Map<String, List<StudentCourse>> coursesBySemester) {
    double totalPoints = 0;
    int totalCourses = 0;
    
    for (var courses in coursesBySemester.values) {
      for (var course in courses) {
        if (course.finalGrade.isNotEmpty) {
          final grade = double.tryParse(course.finalGrade);
          if (grade != null && grade >= 0 && grade <= 100) {
            totalPoints += grade;
            totalCourses++;
          }
        }
      }
    }
    
    return totalCourses > 0 ? totalPoints / totalCourses : 0.0;
  }

  // Get completion statistics
  Map<String, int> _getCompletionStats(Map<String, List<StudentCourse>> coursesBySemester) {
    int totalCourses = 0;
    int completedCourses = 0;
    int passedCourses = 0;
    int failedCourses = 0;
    
    for (var courses in coursesBySemester.values) {
      for (var course in courses) {
        totalCourses++;
        if (course.finalGrade.isNotEmpty) {
          completedCourses++;
          final grade = double.tryParse(course.finalGrade);
          if (grade != null) {
            if (grade >= 55) {
              passedCourses++;
            } else {
              failedCourses++;
            }
          }
        }
      }
    }
    
    return {
      'total': totalCourses,
      'completed': completedCourses,
      'passed': passedCourses,
      'failed': failedCourses,
    };
  }

  // Enhanced edit profile dialog
  void _showEditProfileDialog(BuildContext context, StudentProvider notifier) {
    final student = notifier.student!;
    final nameController = TextEditingController(text: student.name);
    final majorController = TextEditingController(text: student.major);
    final preferencesController = TextEditingController(text: student.preferences);
    // final catalogController = TextEditingController(text: student.catalog);
    final facultyController = TextEditingController(text: student.faculty);
    final semesterController = TextEditingController(text: student.semester.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary, width: 2),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField(nameController, 'Name', Icons.person),
                SizedBox(height: 12),
                _buildEditField(majorController, 'Major', Icons.school),
                SizedBox(height: 12),
                _buildEditField(facultyController, 'Faculty', Icons.business),
                SizedBox(height: 12),
                _buildEditField(semesterController, 'Semester', Icons.calendar_today, 
                  keyboardType: TextInputType.number),
                // SizedBox(height: 12),
                // _buildEditField(catalogController, 'Catalog', Icons.book),
                SizedBox(height: 12),
                _buildEditField(preferencesController, 'Preferences', Icons.settings,
                  maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryDim),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                notifier.updateStudentProfile(
                  name: nameController.text,
                  major: majorController.text,
                  preferences: preferencesController.text,
                  faculty: facultyController.text,
                  catalog: '',
                  semester: student.semester,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.primaryDim),
        prefixIcon: Icon(icon, color: AppColors.primaryDim),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryDim),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
 create: (ctx) => BugReportNotifier(),
 builder: (context, child) { 
    return Consumer2<StudentProvider, CourseProvider>(
      builder: (context, studentNotifier, courseNotifier, _) {
        final student = studentNotifier.student;
        if (student == null) {
          return const Center(
            child: Text(
              'No student profile found',
              style: TextStyle(color: AppColors.primaryDim),
            ),
          );
        }

        final totalCredits = courseNotifier.coursesBySemester.keys
            .map((semester) => courseNotifier.getTotalCreditsForSemester(semester))
            .fold<double>(0.0, (sum, credits) => sum + credits);

        final gpa = _calculateGPA(courseNotifier.coursesBySemester);
        final stats = _getCompletionStats(courseNotifier.coursesBySemester);
        final completionPercentage = stats['total']! > 0 ? stats['completed']! / stats['total']! : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Profile Header
              _buildProfileHeader(context, student, studentNotifier),
              
              const SizedBox(height: 20),
              
              // Academic Progress Section
              _buildAcademicProgress(context, gpa, completionPercentage, stats),
              
              const SizedBox(height: 20),
              
              // Enhanced Statistics Section
              _buildEnhancedStatistics(context, courseNotifier, totalCredits, stats),
              
              const SizedBox(height: 20),
              
              // Academic Details Section
              _buildAcademicDetails(context, student),
              
              const SizedBox(height: 20),
              
              // Actions Section
              _buildActionsSection(context),
            ],
          ),
        );
      });
  });
  }

  Widget _buildProfileHeader(BuildContext context, student, StudentProvider notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accentDim,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDim,
                ],
              ),
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Major: ${student.major}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryDim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Faculty: ${student.faculty}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryDim,
                  ),
                ),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            onPressed: () => _showEditProfileDialog(context, notifier),
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProgress(BuildContext context, double gpa, double completionPercentage, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // GPA Display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current GPA',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryDim,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getGPAColor(gpa),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Completion Percentage
              /*
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: completionPercentage,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(completionPercentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
             */
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Course Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusChip('Completed', stats['completed']!, AppColors.success),
              _buildStatusChip('Passed', stats['passed']!, Colors.green),
              _buildStatusChip('Failed', stats['failed']!, AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatistics(BuildContext context, CourseProvider courseNotifier, double totalCredits, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedStatCard(
                Icons.calendar_today,
                'Semesters',
                courseNotifier.coursesBySemester.length.toString(),
                AppColors.primaryDim,
              ),
              _buildEnhancedStatCard(
                Icons.school,
                'Total Courses',
                stats['total'].toString(),
                AppColors.primary,
              ),
              _buildEnhancedStatCard(
                Icons.star,
                'Credits',
                totalCredits.toStringAsFixed(1),
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryDim,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicDetails(BuildContext context, student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          // _buildDetailRow('Student ID', student.id),
          _buildDetailRow('Current Semester', student.semester.toString()),
          // _buildDetailRow('Catalog Year', student.catalog),
          if (student.preferences.isNotEmpty)
            _buildDetailRow('Academic Preferences', student.preferences),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDim,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Feedback',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          BugReportButton(),
        ],
      ),
    );
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 90) return Colors.green;
    if (gpa >= 80) return Colors.blue;
    if (gpa >= 70) return Colors.orange;
    if (gpa >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
