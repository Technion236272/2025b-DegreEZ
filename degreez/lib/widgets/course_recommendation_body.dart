// lib/widgets/course_recommendation_body.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_recommendation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/course_recommendation/semester_selector_widget.dart';
import '../widgets/course_recommendation/catalog_upload_widget.dart';
import '../widgets/course_recommendation/recommendation_results_widget.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../models/course_recommendation_models.dart';

class CourseRecommendationBody extends StatefulWidget {
  const CourseRecommendationBody({super.key});

  @override
  State<CourseRecommendationBody> createState() =>
      _CourseRecommendationBodyState();
}

class _CourseRecommendationBodyState extends State<CourseRecommendationBody>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = context.read<StudentProvider>();
      if (studentProvider.hasStudent) {
        final studentId = studentProvider.student!.id;
        context.read<CourseRecommendationProvider>().loadAvailableSemesters(
          studentId,
        );
        context.read<CourseRecommendationProvider>().loadSavedRecommendation();
      }
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

    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: themeProvider.secondaryColor,
            unselectedLabelColor: themeProvider.textPrimary,
            indicatorColor: themeProvider.secondaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.search), text: 'Generate'),
              Tab(icon: Icon(Icons.list), text: 'Results'),
              Tab(icon: Icon(Icons.analytics), text: 'History'),
            ],
          ),
        ),
        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildGenerateTab(), _buildResultsTab(), _buildHistoryTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateTab() {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
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
                            color: context.read<ThemeProvider>().primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Course Recommendations',
                              style: Theme.of(context).textTheme.headlineSmall,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get personalized course recommendations based on your academic history and degree requirements.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
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
                            provider.fastMode ? Icons.flash_on : Icons.flash_off,
                            color: provider.fastMode ? Colors.orange : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recommendation Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: Text(provider.fastMode ? 'Fast Mode' : 'Optimized Mode'),
                        subtitle: Text(
                          provider.fastMode 
                            ? 'Quick recommendations  - ~1-2 minutes'
                            : 'AI-optimized recommendations (All phases) - ~10-12 minutes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: provider.fastMode,
                        onChanged: (value) {
                          provider.setFastMode(value);
                        },
                        activeColor: context.read<ThemeProvider>().primaryColor,
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
                  onPressed: provider.canGenerateRecommendations && !provider.isLoading
                      ? () => _generateRecommendations(provider)
                      : null,
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    provider.isLoading 
                        ? 'Generating...' 
                        : 'Generate Recommendations',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeProvider>().primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
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
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No recommendations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Generate recommendations to see results here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Recommendations List
              RecommendationResultsWidget(
                recommendation: provider.currentRecommendation!,
                onAddCourse: (courseId, courseName) =>
                    _handleAddCourseToSelectedSemester(
                      context,
                      courseId,
                      courseName,
                    ),
                onFeedbackSubmitted: (feedback) => _handleFeedback(
                  context,
                  feedback,
                ),
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
                  child: Text(
                    '${recommendation.recommendations.length}',
                    style: TextStyle(
                      color: context.read<ThemeProvider>().secondaryColor,
                    ),
                  ),
                ),
                title: Text(
                  provider.getSemesterDisplayName(
                    recommendation.originalRequest.year,
                    recommendation.originalRequest.semester,
                  ),
                ),
                subtitle: Text(
                  '${recommendation.totalCreditPoints} credits • ${recommendation.generatedAt.toString().split(' ')[0]}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Recommendation'),
                            content: const Text(
                              'Are you sure you want to delete this item?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
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
                  _tabController.animateTo(1); // Switch to Results tab
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateRecommendations(CourseRecommendationProvider provider) async {
    try {
      final courseProvider = context.read<CourseProvider>();
      
      await provider.generateRecommendations(context, courseProvider);
      
      if (provider.currentRecommendation != null) {
        _tabController.animateTo(1); // Switch to Results tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendations generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating recommendations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAddCourseToSelectedSemester(
    BuildContext context,
    String courseId,
    String courseName,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $courseName to semester'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleFeedback(
    BuildContext context,
    UserFeedback feedback,
  ) async {
    try {
      final provider = context.read<CourseRecommendationProvider>();
      await provider.processFeedback(feedback);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Feedback processed! Recommendations updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error processing feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
