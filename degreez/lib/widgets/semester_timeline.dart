// semester_timeline.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

enum SemesterStatus { completed, current, planned, empty }

class SemesterTimelineData {
  final String name;
  final SemesterStatus status;
  final int completedCourses;
  final int totalCourses;
  final double totalCredits;
  
  SemesterTimelineData({
    required this.name,
    required this.status,
    required this.completedCourses,
    required this.totalCourses,
    required this.totalCredits,
  });
}

class SemesterTimeline extends StatelessWidget {
  final List<SemesterTimelineData> semesters;
  final int currentSemesterIndex;
  final Function(int) onSemesterTap;

  const SemesterTimeline({
    super.key,
    required this.semesters,
    required this.currentSemesterIndex,
    required this.onSemesterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (semesters.isEmpty) return SizedBox.shrink();
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: themeProvider.primaryColor,
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode 
                  ? Colors.black.withAlpha(50)
                  : Colors.grey.withAlpha(30),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: semesters.length,
            itemBuilder: (context, index) => _buildSemesterChip(
              context,
              semesters[index],
              index,
              index == currentSemesterIndex,
              themeProvider,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSemesterChip(
    BuildContext context,
    SemesterTimelineData semester,
    int index,
    bool isSelected,
    ThemeProvider themeProvider,
  ) {
    final statusColor = _getStatusColor(semester.status, themeProvider);
    final completionPercentage = semester.totalCourses > 0 
        ? semester.completedCourses / semester.totalCourses 
        : 0.0;

    return GestureDetector(
      onTap: () => onSemesterTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeProvider.secondaryColor 
              : statusColor.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? themeProvider.secondaryColor 
                : statusColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Semester name
            Text(
              _getShortSemesterName(semester.name),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected 
                    ? themeProvider.accentColor 
                    : themeProvider.secondaryColor,
              ),
            ),
            
            SizedBox(height: 2),
            
            // Progress bar
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: themeProvider.isDarkMode 
                  ? Colors.grey.shade600 
                  : Colors.grey.shade300,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: completionPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: statusColor,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 2),
            
            // Course count
            Text(
              '${semester.completedCourses}/${semester.totalCourses}',
              style: TextStyle(
                fontSize: 9,                color: isSelected 
                    ? themeProvider.accentColor 
                    : themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SemesterStatus status, ThemeProvider themeProvider) {
    switch (status) {
      case SemesterStatus.completed:
        return themeProvider.isDarkMode ? Colors.green.shade400 : Colors.green.shade600;
      case SemesterStatus.current:
        return themeProvider.isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600;
      case SemesterStatus.planned:
        return themeProvider.isDarkMode ? Colors.orange.shade400 : Colors.orange.shade600;
      case SemesterStatus.empty:
        return themeProvider.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  String _getShortSemesterName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      final season = parts[0].toLowerCase();
      final year = parts[1];

      String seasonShort;
      switch (season) {
        case 'spring':
          seasonShort = 'Sp';
          break;
        case 'summer':
          seasonShort = 'Su';
          break;
        case 'winter':
          seasonShort = 'W';
          break;
        default:
          seasonShort = season.substring(0, 1).toUpperCase();
      }

      if (year.contains('-')) {
        // Example: 2024-2025 → '24–25
        final parts = year.split('-');
        final y1 = parts[0].substring(2);
        final y2 = parts[1].substring(2);
        return "$seasonShort'$y1–$y2";
      } else {
        // Single year
        final y = year.substring(2);
        return "$seasonShort'$y";
      }
    }

    return fullName.length > 6 ? fullName.substring(0, 6) : fullName;
  }
}
