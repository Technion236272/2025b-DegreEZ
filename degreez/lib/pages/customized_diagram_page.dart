// lib/pages/degree_progress_page.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:degreez/widgets/selectors/semester_season_selector.dart';
import 'package:degreez/widgets/selectors/semester_year_selector.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/course_card.dart';
import '../widgets/add_course_dialog.dart';
import '../mixins/ai_import_mixin.dart';

class CustomizedDiagramPage extends StatefulWidget {
  const CustomizedDiagramPage({super.key});

  @override
  State<CustomizedDiagramPage> createState() => _CustomizedDiagramPageState();
}

class _CustomizedDiagramPageState extends State<CustomizedDiagramPage>
    with AiImportMixin {
  // Add the mixin here
  late ScrollController _scrollController;
  final List<GlobalKey> _semesterKeys = [];
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get responsive grid count
  int _getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 6;
    if (screenWidth > 800) return 5;
    if (screenWidth > 600) return 4;
    return 3;
  }

  // Enhanced: Callback to refresh UI when course is updated
  void _onCourseUpdated() {
    setState(() {
      // This will trigger a rebuild and refresh the course data
    });
  }

  // Override the mixin method to handle post-import actions
  @override
  void onImportCompleted() {
    super.onImportCompleted();
    // Additional actions specific to this page
    _onCourseUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CustomizedDiagramNotifier(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Scaffold(
            backgroundColor: themeProvider.mainColor,
            body: Consumer2<StudentProvider, CourseProvider>(
              builder: (context, studentNotifier, courseNotifier, _) {
                final courseNotifier = context.read<CourseProvider>();
                if (studentNotifier.isLoading && studentNotifier.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (studentNotifier.error != '' &&
                    studentNotifier.error != null) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.mainColor,
                            themeProvider.surfaceColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode
                                ? AppColorsDarkMode.shadowColor
                                : AppColorsLightMode.shadowColor,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error,
                            size: 64,
                            color: themeProvider.isDarkMode
                                ? AppColorsDarkMode.errorColor
                                : AppColorsLightMode.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${studentNotifier.error}',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? AppColorsDarkMode.errorColor
                                  : AppColorsLightMode.errorColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final semesters = courseNotifier.sortedCoursesBySemester;
                if (semesters.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.mainColor,
                            themeProvider.surfaceColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode
                                ? AppColorsDarkMode.shadowColorStrong
                                : AppColorsLightMode.shadowColor,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 64,
                            color: themeProvider.secondaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No courses to display',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.secondaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add courses to see your degree progress',
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.isLightMode
                                  ? themeProvider.primaryColor
                                  : themeProvider.secondaryColor,
                              foregroundColor: themeProvider.mainColor,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: showAiImportDialog,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: AutoSizeText(
                                'Upload Grade Sheet to automatically add courses \n - PDF import now works on web! \n - MAKE SURE TO IMPORT ENGLISH VERSION \n ALSO, IF YOU ATTACH THE FILE THEN THE AGENT WILL START AND IT WILL TAKE TIME, be patient :)',
                                style: TextStyle(
                                  color: themeProvider.primaryColor,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Ensure we have enough keys for the semesters
                while (_semesterKeys.length < semesters.length) {
                  _semesterKeys.add(GlobalKey());
                }
                int allCoursesCount = 0;
                for (List<StudentCourse> semester in semesters.values) {
                  allCoursesCount += semester.length;
                }

                // Detect device orientation
                final orientation = MediaQuery.of(context).orientation;

                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add the semester timeline
                      // SemesterTimeline(
                      //   semesters: _buildTimelineData(semesters),
                      //   currentSemesterIndex: _currentSemesterIndex,
                      //   onSemesterTap: _scrollToSemester,
                      // ),                  // Enhanced: Updated instruction text
                      ((semesters.length <= 2 && allCoursesCount == 0) ||
                              allCoursesCount <= 3)
                          ? Padding(
                              padding: EdgeInsets.only(
                                left: 25,
                                top: 10,
                                bottom: 5,
                                right: 5,
                              ),
                              child: AutoSizeText(
                                'Tip: You can press the Robot in the corner to automatically upload your courses',
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                ),
                                minFontSize: 10,
                                maxFontSize: 30,
                                maxLines: 2,
                              ),
                            )
                          : SizedBox(),

                      allCoursesCount != 0 && allCoursesCount <= 2
                          ? Padding(
                              padding: EdgeInsets.only(
                                left: 25,
                                top: 5,
                                bottom: 5,
                                right: 5,
                              ),
                              child: AutoSizeText(
                                'Tap a course for quick actions Long press to view prerequisites'
                                '\n(Long press the same course to disable prerequisites view)',
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                ),
                                minFontSize: 10,
                                maxFontSize: 30,
                                maxLines: 2,
                              ),
                            )
                          : SizedBox(),

                      // Scrollable content with banner
                      Expanded(
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // AI Budget Warning Banner as first item
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: themeProvider.warningColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: themeProvider.warningColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: themeProvider.warningColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: themeProvider.warningColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Assistant Tips',
                                            style: TextStyle(
                                              color: themeProvider.warningColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '• Operations might take a moment\n• Long press a course to see prerequisites',
                                            style: TextStyle(
                                              color: themeProvider.textPrimary.withOpacity(0.8),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Semester list
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  if (index == semesters.length) {
                                    // This is the extra bottom space
                                    return const SizedBox(height: 100);
                                  }
                                  final semesterKey = semesters.keys.elementAt(
                                    index,
                                  );
                                  final semester = {
                                    'semester': index + 1,
                                    'name': semesterKey,
                                    'courses': semesters[semesterKey]!,
                                  };

                                  return Container(
                                    key: _semesterKeys[index],
                                    child:
                                        orientation == Orientation.portrait
                                            ? _buildVerticalSemesterSection(
                                                context,
                                                semester,
                                                studentNotifier,
                                              )
                                            : _buildVerticalSemesterSection(
                                                context,
                                                semester,
                                                studentNotifier,
                                              ),
                                  );
                                }, childCount: semesters.length + 1),
                              ),
                            ),
                          ],
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
              tooltip: 'Add Semester',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  void _showAddSemesterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return AlertDialog(
              // shape: RoundedRectangleBorder(
              //   side: BorderSide(
              //     color: themeProvider.secondaryColor,
              //     width: 2,
              //   ),
              //   borderRadius: BorderRadius.circular(16),
              // ),
              backgroundColor:
                  themeProvider.mainColor, // Changed to night black
              title: Text(
                'Add New Semester',
                style: TextStyle(color: themeProvider.textPrimary),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SemesterSeasonSelector(),
                    SizedBox(height: 12),
                    SemesterYearSelector(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: themeProvider.secondaryColor.withAlpha(200),
                    ),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
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
                    final signUpProvider = context.read<SignUpProvider>();
                    final selectedSeason =
                        signUpProvider.selectedSemesterSeason;
                    final selectedYear = signUpProvider.selectedSemesterYear;
                    final semesterName =
                        '${selectedSeason ?? ''} ${selectedYear ?? ''}';
                    context.read<CourseProvider>().addSemester(
                      context.read<StudentProvider>().student!.id,
                      semesterName,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Vertical layout for portrait mode - enhanced with responsive grid and update callback
  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentProvider studentNotifier,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final courses = semester['courses'] as List<StudentCourse>;
        final semesterName = semester['name'] as String;
        final totalCredits = context
            .read<CourseProvider>()
            .getTotalCreditsForSemester(semesterName);

        final errorColor = themeProvider.isDarkMode
            ? AppColorsDarkMode.errorColor
            : AppColorsLightMode.errorColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : AppColorsLightMode.shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: themeProvider.borderPrimary.withOpacity(0.5),
                    width: 1,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeProvider.secondaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${totalCredits.toStringAsFixed(1)} credits',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.add_rounded,
                          tooltip: 'Add Course',
                          onTap: () {
                            AddCourseDialog.show(
                              context,
                              semesterName,
                              onCourseAdded: (_) => _onCourseUpdated(),
                            );
                          },
                          themeProvider: themeProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          context,
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete Semester',
                          isDestructive: true,
                          onTap: () {
                            _confirmDeleteSemester(
                              context,
                              semesterName,
                              studentNotifier.student!.id,
                            );
                          },
                          themeProvider: themeProvider,
                          customColor: errorColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Courses Grid
              courses.isEmpty
                  ? _buildEmptySemesterState(context, themeProvider)
                  : GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(context),
                        childAspectRatio: 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final courseWithDetails = context
                            .read<CourseProvider>()
                            .getCourseWithDetails(
                                semesterName, course.courseId);
                        return CourseCard(
                          direction: DirectionValues.vertical,
                          course: course,
                          courseDetails: courseWithDetails?.courseDetails,
                          semester: semesterName,
                          onCourseUpdated: _onCourseUpdated,
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    bool isDestructive = false,
    Color? customColor,
  }) {
    final color = customColor ?? themeProvider.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? color.withOpacity(0.1)
                : themeProvider.mainColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive
                  ? color.withOpacity(0.3)
                  : themeProvider.borderPrimary.withOpacity(0.5),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySemesterState(
      BuildContext context, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: themeProvider.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No courses yet',
            style: TextStyle(
              color: themeProvider.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a course to start planning',
            style: TextStyle(
              color: themeProvider.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSemester(
    BuildContext context,
    String semesterName,
    String studentId,
  ) {
    if (!mounted) return;
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // shape: RoundedRectangleBorder(
        //   side: BorderSide(
        //     color: themeProvider.textSecondary,
        //     width: 2,
        //   ),
        //   borderRadius: BorderRadius.circular(16),            ),
        backgroundColor: themeProvider.mainColor,
        title: Text(
          'Delete Semester',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "$semesterName"? This will remove all courses in it.',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.read<ThemeProvider>().secondaryColor,
              ),
            ),
          ),
          TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                var color = loading
                    ? Colors.grey
                    : context.read<ThemeProvider>().isLightMode
                        ? context.read<ThemeProvider>().accentColor
                        : context.read<ThemeProvider>().secondaryColor;
                return color;
              }),
            ),
            onPressed: loading
                ? null
                : () async {
                    if (loading == true) return;

                    setState(() {
                      loading = true;
                    });
                    await Provider.of<CourseProvider>(
                      context,
                      listen: false,
                    ).deleteSemester(studentId, semesterName);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    // Enhanced: Trigger UI refresh
                    _onCourseUpdated();
                    setState(() {
                      loading = false;
                    });
                  },
            child: Text(
              'Delete',
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
