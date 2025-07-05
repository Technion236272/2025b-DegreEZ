// lib/widgets/course_recommendation/recommendation_results_widget.dart

import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_recommendation_models.dart';
import '../../providers/course_recommendation_provider.dart';
import 'feedback_widget.dart';

class RecommendationResultsWidget extends StatelessWidget {
  final CourseRecommendationResponse recommendation;
  final void Function(String courseId, String courseName)? onAddCourse;
  final void Function(UserFeedback feedback)? onFeedbackSubmitted;

  const RecommendationResultsWidget({
    super.key,
    required this.recommendation,
    this.onAddCourse,
    this.onFeedbackSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize,
                      color: context.read<ThemeProvider>().primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommendation Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recommendation.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context
                        .read<ThemeProvider>()
                        .secondaryColor
                        .withAlpha(75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation.reasoning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.read<ThemeProvider>().primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Courses by Sets
        Text(
          'Recommended Course Sets',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Group courses by category (sets)
        ..._buildCourseSetGroups(context),

        // Add feedback widget if callback is provided
        if (onFeedbackSubmitted != null) ...[
          const SizedBox(height: 24),
          Consumer<CourseRecommendationProvider>(
            builder: (context, provider, child) {
              final courseSets = provider.getCurrentCourseSets();
              if (courseSets.isNotEmpty) {
                return FeedbackWidget(
                  currentRecommendations: courseSets,
                  onFeedbackSubmitted: onFeedbackSubmitted!,
                );
              }
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '💬 Feedback widget will be available once recommendations are generated.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Build course sets grouped by category with highlighting
  List<Widget> _buildCourseSetGroups(BuildContext context) {
    // Group courses by category (sets)
    final groupedCourses = <String, List<CourseRecommendation>>{};
    
    for (final course in recommendation.recommendations) {
      final category = course.category;
      if (!groupedCourses.containsKey(category)) {
        groupedCourses[category] = [];
      }
      groupedCourses[category]!.add(course);
    }
    
    // Sort to ensure Primary Set appears first
    final sortedEntries = groupedCourses.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Primary Set') return -1;
        if (b.key == 'Primary Set') return 1;
        return a.key.compareTo(b.key);
      });
    
    return sortedEntries.map((entry) {
      final setName = entry.key;
      final courses = entry.value;
      final isPrimary = setName == 'Primary Set';
      final totalCredits = courses.fold(0.0, (sum, course) => sum + course.creditPoints);
      
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isPrimary ? 4 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary 
              ? Border.all(
                  color: context.read<ThemeProvider>().primaryColor, 
                  width: 2
                )
              : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set header
                Row(
                  children: [
                    if (isPrimary) ...[
                      Icon(
                        Icons.star,
                        color: context.read<ThemeProvider>().primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        isPrimary ? 'Primary Recommendation' : setName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPrimary 
                            ? context.read<ThemeProvider>().primaryColor 
                            : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimary 
                          ? context.read<ThemeProvider>().primaryColor
                          : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${totalCredits.toStringAsFixed(1)} credits',
                        style: TextStyle(
                          color: isPrimary ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Courses in this set
                ...courses.map((course) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPrimary 
                        ? context.read<ThemeProvider>().primaryColor.withAlpha(26)
                        : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.courseName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${course.courseId} • ${course.creditPoints} credits',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add to semester',
                          onPressed: () {
                            if (onAddCourse != null) {
                              onAddCourse!(course.courseId, course.courseName);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

}
