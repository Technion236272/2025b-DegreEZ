// lib/pages/course_recommendation_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_recommendation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/course_recommendation/semester_selector_widget.dart';
import '../widgets/course_recommendation/catalog_upload_widget.dart';
import '../widgets/course_recommendation/recommendation_results_widget.dart';
import '../widgets/course_recommendation/recommendation_stats_widget.dart';

class CourseRecommendationPage extends StatefulWidget {
  const CourseRecommendationPage({super.key});

  @override
  State<CourseRecommendationPage> createState() => _CourseRecommendationPageState();
}

class _CourseRecommendationPageState extends State<CourseRecommendationPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // No need to initialize provider since it's now synchronous
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
        title: const Text('Course Recommendations'),
        backgroundColor: themeProvider.mainColor,
        foregroundColor: themeProvider.textPrimary,
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildResultsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                          Icon(Icons.auto_awesome, 
                              color: context.read<ThemeProvider>().primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'AI Course Recommendations',
                            style: Theme.of(context).textTheme.headlineSmall,
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
                        ? 'Generating Recommendations...' 
                        : 'Generate Recommendations',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.read<ThemeProvider>().primaryColor,
                    foregroundColor: context.read<ThemeProvider>().secondaryColor,
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
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          onPressed: provider.clearError,
                          icon: const Icon(Icons.close),
                          color: Colors.red[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Information Cards
              const SizedBox(height: 32),
              _buildInfoCards(),
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
              // Stats Summary
              RecommendationStatsWidget(
                stats: provider.getRecommendationStats(),
                semester: provider.selectedSemesterDisplay ?? 'Unknown',
              ),
              
              const SizedBox(height: 16),
              
              // Recommendations List
              RecommendationResultsWidget(
                recommendation: provider.currentRecommendation!,
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
                  child: Text('${recommendation.recommendations.length}'),
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
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Load this recommendation as current
                  provider.clearCurrentRecommendation();
                  // You'd implement a method to set current recommendation
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.psychology, 
                          color: context.read<ThemeProvider>().primaryColor, size: 32),
                      const SizedBox(height: 8),
                      const Text('AI-Powered', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Advanced algorithms analyze your academic progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.person, 
                          color: context.read<ThemeProvider>().primaryColor, size: 32),
                      const SizedBox(height: 8),
                      const Text('Personalized', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Recommendations tailored to your major and preferences',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, 
                          color: context.read<ThemeProvider>().primaryColor, size: 32),
                      const SizedBox(height: 8),
                      const Text('Optimized', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Balanced workload and optimal credit distribution',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.track_changes, 
                          color: context.read<ThemeProvider>().primaryColor, size: 32),
                      const SizedBox(height: 8),
                      const Text('Progressive', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Considers prerequisites and degree progression',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _generateRecommendations(CourseRecommendationProvider provider) async {
    await provider.generateRecommendations(context);
    
    if (provider.currentRecommendation != null) {
      // Switch to results tab
      _tabController.animateTo(1);
      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course recommendations generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}