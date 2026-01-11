// lib/pages/course_recommendation_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_recommendation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/course_recommendation/semester_selector_widget.dart';
import '../widgets/course_recommendation/catalog_upload_widget.dart';
import '../widgets/course_recommendation/recommendation_results_widget.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';
import '../models/course_recommendation_models.dart';

class CourseRecommendationPage extends StatefulWidget {
  const CourseRecommendationPage({super.key});

  @override
  State<CourseRecommendationPage> createState() =>
      _CourseRecommendationPageState();
}

class _CourseRecommendationPageState extends State<CourseRecommendationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentId = context.read<StudentProvider>().student!.id;
      context.read<CourseRecommendationProvider>().loadAvailableSemesters(
        studentId,
      );
      context.read<CourseRecommendationProvider>().loadSavedRecommendation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: themeProvider.textPrimary,
            unselectedLabelColor: themeProvider.textSecondary,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: themeProvider.secondaryColor,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.secondaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 18),
                    SizedBox(width: 8),
                    Text('Generate'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt, size: 18),
                    SizedBox(width: 8),
                    Text('Results'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 8),
                    Text('History'),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGenerateTab(), _buildResultsTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // AI Budget Warning Banner (fixed at top)
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //   decoration: BoxDecoration(
            //     color: context.read<ThemeProvider>().warningColor.withOpacity(
            //       0.1,
            //     ),
            //     border: Border(
            //       bottom: BorderSide(
            //         color: context
            //             .read<ThemeProvider>()
            //             .warningColor
            //             .withOpacity(0.3),
            //         width: 1,
            //       ),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.info_outline,
            //         color: context.read<ThemeProvider>().warningColor,
            //         size: 20,
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Text(
            //           '''the ai aint cheap, dont overuse it! \n - First, you need to add a new semester in customized diagram then come back here :) , and please wait until the AI finishes processing the file after you upload it, it may take several minutes.''',
            //           style: TextStyle(
            //             color: context.read<ThemeProvider>().textPrimary,
            //             fontSize: 13,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color:
                                      context
                                          .read<ThemeProvider>()
                                          .primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'AI Course Recommendations',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '''The courses that will be recommended are: 
1. 📚 Courses that align with your catalog requirements. 
2. 🎯 Courses that match your interests and career goals. (based on your preferences from your profile) 
3. ✅ Courses that you have their prerequisites completed for. 
4. 🗓️ Courses that are offered in the upcoming semesters.
NOTE: Dont overuse the AI, we might run out of budget  :)
''',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: context.read<ThemeProvider>().textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preferences Display
                    Consumer<StudentProvider>(
                      builder: (context, studentProvider, child) {
                        final student = studentProvider.student;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color:
                                          context
                                              .read<ThemeProvider>()
                                              .primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Current Preferences',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  student?.preferences.isNotEmpty == true
                                      ? student!.preferences
                                      : 'No preferences set. Go to Profile to add them.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Fast Mode Toggle
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  provider.fastMode
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                  color:
                                      provider.fastMode
                                          ? context
                                              .read<ThemeProvider>()
                                              .warningColor
                                          : context
                                              .read<ThemeProvider>()
                                              .textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recommendation Mode',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: Text(
                                provider.fastMode
                                    ? 'Fast Mode'
                                    : 'Optimized Mode',
                              ),
                              subtitle: Text(
                                provider.fastMode
                                    ? 'Quick recommendations (simple)  - ~1-2 minutes'
                                    : 'AI-optimized recommendations (Uses Hill Climbing Optimization Algorithm with a hybrid approach of LLM\'s evaluation): ~10-12 minutes',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              value: provider.fastMode,
                              onChanged: provider.setFastMode,
                              secondary: Icon(
                                provider.fastMode
                                    ? Icons.speed
                                    : Icons.psychology,
                                color:
                                    provider.fastMode
                                        ? context
                                            .read<ThemeProvider>()
                                            .warningColor
                                        : context
                                            .read<ThemeProvider>()
                                            .primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Semester Selection
                    SemesterSelectorWidget(
                      availableSemesters: provider.availableSemesters,
                      selectedYear: provider.selectedYear,
                      selectedSemester: provider.selectedSemester,
                      onSemesterSelected: provider.setSelectedSemester,
                    ),

                    const SizedBox(height: 24),

                    // Catalog Upload
                    CatalogUploadWidget(
                      catalogFilePath: provider.catalogFilePath,
                      onFileSelected: provider.setCatalogFilePath,
                    ),

                    const SizedBox(height: 32),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            provider.canGenerateRecommendations &&
                                    !provider.isLoading
                                ? () => _generateRecommendations(provider)
                                : null,
                        icon:
                            provider.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.auto_awesome),
                        label: Text(
                          provider.isLoading
                              ? (provider.fastMode
                                  ? 'Generating Fast Recommendations... DONT CLOSE THE SCREEN'
                                  : 'Generating Optimized Recommendations... DONT CLOSE THE SCREEN')
                              : 'Generate Recommendations',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              context.read<ThemeProvider>().primaryColor,
                          foregroundColor:
                              context.read<ThemeProvider>().secondaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Error Display
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: context
                            .read<ThemeProvider>()
                            .errorColor
                            .withAlpha(26),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: context.read<ThemeProvider>().errorColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.error!,
                                  style: TextStyle(
                                    color:
                                        context
                                            .read<ThemeProvider>()
                                            .errorColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: provider.clearError,
                                icon: const Icon(Icons.close),
                                color: context.read<ThemeProvider>().errorColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Information Cards
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultsTab() {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        if (provider.currentRecommendation == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recommendations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Generate recommendations from the first tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Recommendations List
              RecommendationResultsWidget(
                recommendation: provider.currentRecommendation!,
                onAddCourse:
                    (courseId, courseName) =>
                        _handleAddCourseToSelectedSemester(
                          context,
                          courseId,
                          courseName,
                        ),
                onFeedbackSubmitted:
                    (feedback) => _handleFeedback(context, feedback),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        if (provider.previousRecommendations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recommendation history',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: provider.previousRecommendations.length,
          itemBuilder: (context, index) {
            final recommendation = provider.previousRecommendations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.read<ThemeProvider>().primaryColor,
                ),
                title: Text(
                  provider.getSemesterDisplayName(
                    recommendation.originalRequest.year,
                    recommendation.originalRequest.semester,
                  ),
                ),
                subtitle: Text(
                  '${recommendation.generatedAt.toString().split(' ')[0]}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: context.read<ThemeProvider>().errorColor,
                      ),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Recommendation'),
                                content: const Text(
                                  'Are you sure you want to delete this item?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color:
                                            context
                                                .read<ThemeProvider>()
                                                .errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          provider.deleteRecommendationAt(index);
                        }
                      },
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
                onTap: () {
                  provider.setCurrentRecommendation(recommendation);
                  _tabController.animateTo(1);
                },
              ),
            );
          },
        );
      },
    );
  }


  void _generateRecommendations(CourseRecommendationProvider provider) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await provider.generateRecommendations(context, courseProvider);

    if (provider.currentRecommendation != null) {
      // Switch to results tab
      _tabController.animateTo(1);
      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Course recommendations generated successfully!'),
          backgroundColor: context.read<ThemeProvider>().successColor,
        ),
      );
    }
  }

  void _handleAddCourseToSelectedSemester(
    BuildContext context,
    String aiCourseId,
    String aiCourseName,
  ) async {
    final courseProvider = context.read<CourseProvider>();
    final studentProvider = context.read<StudentProvider>();
    final recommendationProvider = context.read<CourseRecommendationProvider>();

    final selectedSemester =
        recommendationProvider
            .currentRecommendation
            ?.originalRequest
            .semesterDisplayName;
    final studentId = studentProvider.student!.id;

    if (selectedSemester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No semester selected.')));
      return;
    }
    final fallbackSemester = await courseProvider.getClosestAvailableSemester(
      selectedSemester,
    );
    debugPrint(
      'Using fallback semester: $fallbackSemester for selected semester: $selectedSemester',
    );
    final parsed = courseProvider.parseSemesterCode(fallbackSemester);
    if (parsed == null) {
      debugPrint(
        '❌ Failed to parse semester string: ${recommendationProvider.selectedSemesterDisplay}',
      );
      return;
    }
    final (apiYear, semesterCode) = parsed;

    // Check if already exists
    final alreadyExists = courseProvider
        .getCoursesForSemester(selectedSemester)
        .any((c) => c.name == aiCourseName || c.courseId == aiCourseId);

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course already exists in semester $selectedSemester.'),
        ),
      );
      return;
    }

    // Match course by ID using CourseService directly
    try {
      final courseInfo = await CourseService.getCourseDetails(
        apiYear,
        semesterCode,
        aiCourseId,
      );

      if (courseInfo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course details not found for "$aiCourseName".'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final details = CourseRecommendationDetails.fromCourseService(courseInfo);

      final course = StudentCourse(
        courseId: details.courseId,
        name: details.courseName,
        finalGrade: '',
        lectureTime: '',
        tutorialTime: '',
        labTime: '',
        workshopTime: '',
        creditPoints: details.creditPoints,
      );

      final success = await courseProvider.addCourseToSemester(
        studentId,
        selectedSemester,
        course,
        fallbackSemester,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${details.courseName} added to $selectedSemester.'
                : 'Failed to add ${details.courseName}.',
          ),
          backgroundColor:
              success
                  ? context.read<ThemeProvider>().successColor
                  : context.read<ThemeProvider>().errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding course: $e'),
          backgroundColor: context.read<ThemeProvider>().errorColor,
        ),
      );
    }
  }

  /// Handle user feedback submission
  Future<void> _handleFeedback(
    BuildContext context,
    UserFeedback feedback,
  ) async {
    try {
      final provider = context.read<CourseRecommendationProvider>();
      await provider.processFeedback(feedback);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Feedback processed! Recommendations updated.',
            ),
            backgroundColor: context.read<ThemeProvider>().successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error processing feedback: $e'),
            backgroundColor: context.read<ThemeProvider>().errorColor,
          ),
        );
      }
    }
  }
}
