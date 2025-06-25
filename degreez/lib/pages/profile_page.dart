import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/feedback_notifier.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/services/theme_sync_service.dart';
import 'package:degreez/widgets/bug_report_popup.dart';
import 'package:degreez/widgets/delete_user_button.dart';
import 'package:degreez/widgets/feedback_popup.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
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
  // Controllers for the form fields
  // These controllers will be used to get the text input from the user
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: student.name);
  final majorController = TextEditingController(text: student.major);
  final preferencesController = TextEditingController(text: student.preferences);
  final facultyController = TextEditingController(text: student.faculty);
  final semesterController = TextEditingController(text: student.semester.toString());

  // Catalog Selection Not Implemented Yet
  // final _catalogController = TextEditingController();

  final RegExp nameValidator = RegExp(r'^(?!\s*$).+');
  final RegExp majorValidator = RegExp(r'^(?!\s*$)[A-Za-z\s]+$');
  final RegExp facultyValidator = RegExp(r'^(?!\s*$)[A-Za-z\s]+$');
  final RegExp preferencesValidator = RegExp(r'^(.?)+$');
  final RegExp semesterValidator = RegExp(
    r'^(Winter|Spring|Summer) (\d{4}-\d{2}|\d{4})$',
    caseSensitive: false,
  );

  // Catalog Selection Not Implemented Yet
  // final RegExp _catalogValidator = RegExp(r'');

  // Dispose the controllers when the widget is removed from the widget tree
  // This is important to free up resources and avoid memory leaks
  @override
  void dispose() {
    nameController.dispose();
    majorController.dispose();
    facultyController.dispose();
    preferencesController.dispose();
    semesterController.dispose();
  }    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.surfaceColor,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
          ),
          content: Form(
                      key: formKey,
                      child:SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [                textFormFieldWithStyle(
                            label: 'Name',
                            controller: nameController,
                            example: 'e.g. Steve Harvey',
                            validatorRegex: nameValidator,
                            errorMessage: "Really? an empty name ...",
                            context: context,
                          ),                textFormFieldWithStyle(
                            label: 'Major',
                            controller: majorController,
                            example: 'e.g. Data Analysis',
                            validatorRegex: majorValidator,
                            errorMessage:
                                "Invalid Input! remember to write the major in English",
                            context: context,
                          ),                          textFormFieldWithStyle(
                            label: 'Faculty',
                            controller: facultyController,
                            example: 'e.g. Computer Science',
                            validatorRegex: facultyValidator,
                            errorMessage:
                                "Invalid Input! remember to write the faculty in English",
                            context: context,
                          ),                          textFormFieldWithStyle(
                            label: 'Semester',
                            controller: semesterController,
                            example: 'e.g. Winter 2024-25 or Summer 2021',
                            validatorRegex: semesterValidator,
                            errorMessage:
                                "should match this template 'Winter 2024-25'",
                            context: context,
                          ),                          textFormFieldWithStyle(
                            label: 'Preferences',
                            controller: preferencesController,
                            example:
                                "e.g. I like mathematics and coding related topics and I hate history lessons since I thinks they're boring",
                            validatorRegex: preferencesValidator,
                            lineNum: 3,
                            context: context,
                          ),
              ],
            ),),
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Provider.of<ThemeProvider>(context).textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true)
                                {return;}
                notifier.updateStudentProfile(
                  name: nameController.text,
                  major: majorController.text,
                  preferences: preferencesController.text,
                  faculty: facultyController.text,
                  catalog: '',
                  semester: student.semester,
                );
                dispose();
                Navigator.of(context).pop();                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode 
                        ? AppColorsDarkMode.successColor 
                        : AppColorsLightMode.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                
              },
              child: Text('Save Changes',style: TextStyle(
                    color: Provider.of<ThemeProvider>(context).secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => BugReportNotifier()),
    ChangeNotifierProvider(create: (_) => FeedbackNotifier()),
    // You can add more here if needed
  ],
 builder: (context, child) { 
    return Consumer3<StudentProvider, CourseProvider,LogInNotifier>(
      builder: (context, studentNotifier, courseNotifier,logInNotifier, _) {
        final student = studentNotifier.student;
        if (student == null) {          return Center(
            child: Text(
              'No student profile found',
              style: TextStyle(color: Provider.of<ThemeProvider>(context).textSecondary),
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
              _buildProfileHeader(context, student, studentNotifier,logInNotifier.user),
              
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
              
              const SizedBox(height: 40),
              
              DeleteUserButton(),
            ],
          ),
        );
      });
  });
  }
  Widget _buildProfileHeader(BuildContext context, student, StudentProvider notifier,user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.mainColor,
            themeProvider.accentColor,
          ],
          begin: Alignment.topLeft,          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black : AppColorsLightMode.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          user?.photoURL != null 
          ?Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: themeProvider.borderPrimary, // Border color
      width: 1.0,         // Border width
    ),
  ),
  child: CircleAvatar(
            radius: 39,
                backgroundImage: NetworkImage(user!.photoURL!)
              ),)          :Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  themeProvider.secondaryColor,
                  themeProvider.borderPrimary,
                ],
              ),
              border: Border.all(
                color: themeProvider.secondaryColor,
                width: 3,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: themeProvider.accentColor,
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
                    color: themeProvider.secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Major: ${student.major}',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.textSecondary,
                  ),
                ),                const SizedBox(height: 4),
                Text(
                  'Faculty: ${student.faculty}',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
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
              color: themeProvider.accentColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: themeProvider.secondaryColor,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.mainColor,
            themeProvider.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black : AppColorsLightMode.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // GPA Display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    Text(
                      'Current GPA',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textSecondary,
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
                  children: [                    Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),                    LinearProgressIndicator(
                      value: completionPercentage,
                      backgroundColor: themeProvider.surfaceColor,
                      valueColor: AlwaysStoppedAnimation(themeProvider.isDarkMode 
                          ? AppColorsDarkMode.successColor 
                          : AppColorsLightMode.successColor),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),                      Text(
                        '${(completionPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.secondaryColor,
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
              _buildStatusChip('Completed', stats['completed']!, const Color.fromARGB(255, 109, 228, 115)),
              _buildStatusChip('Passed', stats['passed']!, const Color.fromARGB(255, 68, 255, 55)),
              _buildStatusChip('Failed', stats['failed']!, const Color.fromARGB(255, 255, 49, 49)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStatusChip(String label, int value, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderPrimary),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.mainColor,
            themeProvider.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black : AppColorsLightMode.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.secondaryColor,
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
                themeProvider.secondaryColor,
              ),
              _buildEnhancedStatCard(
                Icons.school,
                'Total Courses',
                stats['total'].toString(),
                themeProvider.secondaryColor,
              ),
              _buildEnhancedStatCard(
                Icons.star,
                'Credits',
                totalCredits.toStringAsFixed(1),
                themeProvider.secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildEnhancedStatCard(IconData icon, String label, String value, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.borderPrimary),
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
              color: themeProvider.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildAcademicDetails(BuildContext context, student) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeProvider.mainColor,
            themeProvider.accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black : AppColorsLightMode.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.secondaryColor,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
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
                color: themeProvider.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: themeProvider.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionsSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(            gradient: LinearGradient(
              colors: [
                themeProvider.mainColor,
                themeProvider.accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode ? Colors.black : AppColorsLightMode.shadowColor,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance & Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Theme Mode Toggle
              _buildThemeToggleCard(themeProvider),
              const SizedBox(height: 16),
              // Color Theme Toggle
              _buildColorThemeCard(themeProvider),
              const SizedBox(height: 24),
              Text(
                'Support & Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              BugReportButton(),
              const SizedBox(height: 16),
              FeedbackButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeToggleCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                themeProvider.currentThemeIcon,
                color: themeProvider.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current: ${themeProvider.currentThemeName}',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildThemeButton(
                themeProvider,
                AppThemeMode.light,
                Icons.light_mode,
                'Light',
              ),
              _buildThemeButton(
                themeProvider,
                AppThemeMode.dark,
                Icons.dark_mode,
                'Dark',
              ),
              _buildThemeButton(
                themeProvider,
                AppThemeMode.system,
                Icons.brightness_auto,
                'System',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorThemeCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                themeProvider.currentColorThemeIcon,
                color: themeProvider.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Color Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current: ${themeProvider.currentColorThemeName}',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorThemeButton(
                themeProvider,
                ColorThemeMode.colorful,
                Icons.palette,
                'Colorful',
              ),
              _buildColorThemeButton(
                themeProvider,
                ColorThemeMode.classic,
                Icons.style,
                'Classic',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    ThemeProvider themeProvider,
    AppThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeProvider.currentThemeMode == mode;
    return GestureDetector(
      onTap: () async {
        await themeProvider.setThemeMode(mode);
        // Update student preference if logged in
        final studentProvider = context.read<StudentProvider>();
        if (studentProvider.hasStudent) {
          await _updateStudentThemePreference(mode.name);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? themeProvider.primaryColor
                : themeProvider.borderPrimary,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : themeProvider.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : themeProvider.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorThemeButton(
    ThemeProvider themeProvider,
    ColorThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeProvider.currentColorMode == mode;
    return GestureDetector(
      onTap: () async {
        await themeProvider.setColorMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeProvider.primaryColor
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? themeProvider.primaryColor
                : themeProvider.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : themeProvider.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : themeProvider.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }  Future<void> _updateStudentThemePreference(String themeMode) async {
    try {
      await ThemeSyncService.updateStudentThemePreference(
        context,
        AppThemeMode.values.firstWhere((mode) => mode.name == themeMode),
      );
    } catch (e) {
      debugPrint('Error updating student theme preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save theme preference: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  Color _getGPAColor(double gpa) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (gpa >= 90) return const Color.fromARGB(255, 49, 200, 57);
    if (gpa >= 80) return themeProvider.isDarkMode 
        ? AppColorsDarkMode.successColor 
        : AppColorsLightMode.successColor;
    if (gpa >= 70) return themeProvider.primaryColor;
    if (gpa >= 60) return themeProvider.isDarkMode 
        ? AppColorsDarkMode.warningColor 
        : AppColorsLightMode.warningColor;
    return themeProvider.isDarkMode 
        ? AppColorsDarkMode.errorColor 
        : AppColorsLightMode.errorColor;
  }
}
