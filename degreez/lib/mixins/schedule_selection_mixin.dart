// lib/mixins/schedule_selection_mixin.dart
// Shared functionality for schedule selection to eliminate code duplication

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../providers/color_theme_provider.dart';
import '../services/course_service.dart';
import '../widgets/schedule_selection_dialog.dart';

mixin ScheduleSelectionMixin {
  /// Shows the schedule selection dialog for a course
  void showScheduleSelectionDialog(
    BuildContext context,
    StudentCourse course,
    EnhancedCourseDetails? courseDetails, {
    String? semester,
    VoidCallback? onSelectionUpdated,
  }) {
    if (courseDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course details not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ScheduleSelectionDialog(
        course: course,
        courseDetails: courseDetails,
        onSelectionChanged: (lectureTime, tutorialTime, labTime, workshopTime) {
          updateCourseScheduleSelection(
            context,
            course,
            semester,
            lectureTime,
            tutorialTime,
            labTime,
            workshopTime,
            onSelectionUpdated: onSelectionUpdated,
          );
        },
      ),
    );
  }

  /// Updates course schedule selection - shared logic to avoid duplication
  Future<void> updateCourseScheduleSelection(
    BuildContext context,
    StudentCourse course,
    String? semester,
    String? lectureTime,
    String? tutorialTime,
    String? labTime,
    String? workshopTime, {
    VoidCallback? onSelectionUpdated,
  }) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (!studentProvider.hasStudent) return;

    // Determine semester if not provided
    String? targetSemester = semester;
    if (targetSemester == null) {
      // Find which semester this course belongs to
      for (final entry in courseProvider.coursesBySemester.entries) {
        if (entry.value.any((c) => c.courseId == course.courseId)) {
          targetSemester = entry.key;
          break;
        }
      }
    }

    if (targetSemester == null) return;

    final success = await courseProvider.updateCourseScheduleSelection(
      studentProvider.student!.id,
      targetSemester,
      course.courseId,
      lectureTime,
      tutorialTime,
      labTime,
      workshopTime,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule selection updated')),
      );
      
      // Call the callback to refresh UI if provided
      onSelectionUpdated?.call();
      
      // Refresh calendar events if ColorThemeProvider is available
      try {
        final colorThemeProvider = context.read<ColorThemeProvider>();
        if (context.mounted) {
          _refreshCalendarEvents(context, courseProvider, colorThemeProvider);
        }
      } catch (e) {
        // ColorThemeProvider might not be available in all contexts
        debugPrint('ColorThemeProvider not available for calendar refresh: $e');
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update schedule selection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Refresh calendar events - can be overridden by implementing classes
  void _refreshCalendarEvents(
    BuildContext context,
    CourseProvider courseProvider,
    ColorThemeProvider colorThemeProvider,
  ) {
    // Default implementation - can be overridden by classes that use this mixin
    debugPrint('Default calendar refresh - should be overridden by implementing class');
  }
}