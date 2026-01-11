import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/providers/bug_report_notifier.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/feedback_notifier.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/bug_report_popup.dart';
// import 'package:degreez/widgets/delete_user_button.dart'; // Removed as logic is now inline
import 'package:degreez/widgets/feedback_popup.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/widgets/selectors/catalog_selector.dart';
import 'package:degreez/widgets/selectors/faculty_selector.dart';
import 'package:degreez/widgets/selectors/major_selector.dart';
import 'package:degreez/widgets/selectors/semester_season_selector.dart';
import 'package:degreez/widgets/selectors/semester_year_selector.dart';
import 'package:degreez/widgets/selectors/university_selector.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/calculate_gpa_function.dart';
import 'package:degreez/widgets/tutorial_popup.dart';
import 'package:degreez/pages/deleting_account_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, int> _getCompletionStats(
    Map<String, List<StudentCourse>> coursesBySemester,
  ) {
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
          } else if (course.finalGrade == 'Pass') {
            passedCourses++;
          } else if (course.finalGrade == 'Fail') {
            failedCourses++;
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

  void _showEditProfileDialog(BuildContext context, StudentProvider notifier) {
    final student = notifier.student!;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student.name);
    final preferencesController = TextEditingController(
      text: student.preferences,
    );

    context.read<SignUpProvider>().setSelectedCatalog(student.catalog);
    context.read<SignUpProvider>().setSelectedFaculty(student.faculty);
    context.read<SignUpProvider>().setSelectedMajor(student.major);
    context.read<SignUpProvider>().setSelectedSemester(student.semester);
    context.read<SignUpProvider>().setSelectedUniversity(student.university);

    final RegExp nameValidator = RegExp(r'^(?!\s*$).+');
    final RegExp preferencesValidator = RegExp(r'^(.?)+$');

    showDialog(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textFormFieldWithStyle(
                    label: 'Name',
                    controller: nameController,
                    example: 'e.g. Steve Harvey',
                    validatorRegex: nameValidator,
                    errorMessage: "Really? an empty name ...",
                    context: context,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: UniversitySelector(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: CatalogSelector(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: FacultySelector(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: MajorSelector(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 10, child: SemesterSeasonSelector()),
                        Expanded(flex: 1, child: const SizedBox(height: 2)),
                        Expanded(
                          flex: 10,
                          child: SemesterYearSelector(
                            year: DateTime.now().year - 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  textFormFieldWithStyle(
                    label: 'Preferences',
                    controller: preferencesController,
                    example:
                        "e.g. I like mathematics and coding related topics and I hate history lessons since I thinks they're boring",
                    validatorRegex: preferencesValidator,
                    lineNum: 3,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: context.read<ThemeProvider>().secondaryColor,
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return context.read<ThemeProvider>().isLightMode
                        ? context.read<ThemeProvider>().accentColor
                        : context.read<ThemeProvider>().secondaryColor;
                  }
                  return context.read<ThemeProvider>().isLightMode
                      ? context.read<ThemeProvider>().accentColor
                      : context.read<ThemeProvider>().secondaryColor;
                }),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                var name = nameController.text;
                var preference = preferencesController.text;
                notifier.updateStudentProfile(
                  name: name,
                  major: context.read<SignUpProvider>().selectedMajor ?? '',
                  preferences: preference,
                  faculty: context.read<SignUpProvider>().selectedFaculty ?? '',
                  catalog: context.read<SignUpProvider>().selectedCatalog ?? '',
                  semester:
                      context.read<SignUpProvider>().selectedSemester ?? '',
                  university: context.read<SignUpProvider>().selectedUniversity ??
                      'Technion',
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: themeProvider.isDarkMode
                        ? AppColorsDarkMode.successColor
                        : AppColorsLightMode.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Are you sure?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Provider.of<ThemeProvider>(dialogContext).errorColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'This action cannot be undone.\n\n'
              'If you proceed, your account will be permanently deleted along with all associated data.',
              style: TextStyle(
                fontSize: 14,
                color: Provider.of<ThemeProvider>(dialogContext).textPrimary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Provider.of<ThemeProvider>(dialogContext).secondaryColor,
                ),
              ),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                 Navigator.of(dialogContext).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => DeletingAccountPage(),
                ));
                
                final rootNavigator = Navigator.of(dialogContext, rootNavigator: true);

                await dialogContext.read<CourseProvider>().deleteStudentAndCourses(dialogContext.read<StudentProvider>().student!.id);
                if (!dialogContext.mounted) return;
                await dialogContext.read<LogInNotifier>().deleteUser();
                if (!dialogContext.mounted) return;
                await dialogContext.read<LogInNotifier>().signOut();
                rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // New method to trigger tutorial replay
  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TutorialPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final loginNotifier = Provider.of<LogInNotifier>(context);

    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final student = studentProvider.student;
    final user = loginNotifier.user;

    if (student == null) {
      return const Center(child: Text('No student data found'));
    }

    final stats = _getCompletionStats(courseProvider.coursesBySemester);
    final gpa = calculateAverage(getCompletedCourses(
            courseProvider.sortedCoursesBySemester, courseProvider))
        .gpa;

    return Scaffold(
      backgroundColor: themeProvider.mainColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [
                                themeProvider.primaryColor,
                                themeProvider.accentColor,
                              ]
                            : [
                                themeProvider.primaryColor,
                                themeProvider.secondaryColor,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage: user?.photoURL != null
                                      ? NetworkImage(user!.photoURL!)
                                      : null,
                                  child: user?.photoURL == null
                                      ? Text(
                                          student.name.isNotEmpty
                                              ? student.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      student.major,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'GPA: ${gpa.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showEditProfileDialog(
                                  context,
                                  studentProvider,
                                ),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        context,
                        'Completed Courses',
                        stats['completed'].toString(),
                        Icons.check_circle_outline,
                        themeProvider.successColor,
                      ),
                      _buildStatCard(
                        context,
                        'Current Semester',
                        student.semester,
                        Icons.calendar_today,
                        themeProvider.accentColor,
                      ),
                      _buildStatCard(
                        context,
                        'Faculty',
                        student.faculty,
                        Icons.school,
                        themeProvider.primaryColor,
                      ),
                      _buildStatCard(
                        context,
                        'Catalog Year',
                        student.catalog,
                        Icons.menu_book,
                        themeProvider.warningColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildPreferencesCard(context, student),

                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSettingsSection(context, themeProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, StudentModel student) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: themeProvider.primaryColor),
              const SizedBox(width: 12),
              Text(
                'My Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            student.preferences.isEmpty
                ? 'No preferences set. Tap edit to add some!'
                : student.preferences,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.textPrimary,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: themeProvider.primaryColor,
              ),
            ),
            title: const Text('Appearance'),
            subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              activeColor: themeProvider.primaryColor,
              onChanged: (_) => themeProvider.toggleLightDark(),
            ),
          ),
          Divider(height: 1, color: themeProvider.textSecondary.withOpacity(0.1)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline_rounded, color: themeProvider.primaryColor),
            ),
            title: const Text('Show Tutorial'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTutorial(context),
          ),
          Divider(height: 1, color: themeProvider.textSecondary.withOpacity(0.1)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bug_report, color: themeProvider.accentColor),
            ),
            title: const Text('Report a Bug'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (context) => ChangeNotifierProvider(
                create: (_) => BugReportNotifier(),
                child: const BugReportPopup(),
              ),
            ),
          ),
          Divider(height: 1, color: themeProvider.textSecondary.withOpacity(0.1)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.feedback, color: themeProvider.successColor),
            ),
            title: const Text('Send Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (context) => ChangeNotifierProvider(
                create: (_) => FeedbackNotifier(),
                child: const FeedbackPopup(),
              ),
            ),
          ),
          Divider(height: 1, color: themeProvider.textSecondary.withOpacity(0.1)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever, color: themeProvider.errorColor),
            ),
            title: Text(
              'Delete Account',
              style: TextStyle(color: themeProvider.errorColor),
            ),
            onTap: () => _showDeleteConfirmationDialog(context),
          ),
          Divider(height: 1, color: themeProvider.textSecondary.withOpacity(0.1)),
          
        ],
      ),
    );
  }
}
