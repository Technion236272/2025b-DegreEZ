// lib/mixins/schedule_selection_mixin.dart
// Shared functionality for schedule selection to eliminate code duplication

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';
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

    if (success && context.mounted) {      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule selection updated')),
      );
      
      // Wait a bit to ensure Firebase data is consistent
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Call the callback to refresh UI if provided
      onSelectionUpdated?.call();
      if (!context.mounted) return;
      // Refresh calendar events if ThemeProvider is available
      try {
        final themeProvider = context.read<ThemeProvider>();
        if (context.mounted) {
          await refreshCalendarEvents(context, courseProvider, themeProvider);
        }
      } catch (e) {
        // ThemeProvider might not be available in all contexts
        debugPrint('ThemeProvider not available for calendar refresh: $e');
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update schedule selection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }  /// Refresh calendar events - can be overridden by implementing classes
  Future<void> refreshCalendarEvents(
    BuildContext context,
    CourseProvider courseProvider,
    ThemeProvider themeProvider,
  ) async {
    // Default implementation - can be overridden by classes that use this mixin
    debugPrint('Default calendar refresh - should be overridden by implementing class');
  }
}