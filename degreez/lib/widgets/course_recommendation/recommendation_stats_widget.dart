
// lib/widgets/course_recommendation/recommendation_stats_widget.dart

import 'package:flutter/material.dart';

class RecommendationStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String semester;

  const RecommendationStatsWidget({
    super.key,
    required this.stats,
    required this.semester,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Recommendation Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              semester,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Courses',
                    '${stats['totalCourses'] ?? 0}',
                    Icons.school,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Credit Points',
                    '${stats['totalCredits'] ?? 0}',
                    Icons.star,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Priority Distribution
            if (stats['highPriority'] != null) ...[
              Text(
                'Priority Distribution',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPriorityBar(
                      context,
                      'High',
                      stats['highPriority'] ?? 0,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPriorityBar(
                      context,
                      'Medium',
                      stats['mediumPriority'] ?? 0,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPriorityBar(
                      context,
                      'Low',
                      stats['lowPriority'] ?? 0,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}