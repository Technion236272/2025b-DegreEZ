// lib/mixins/course_event_mixin.dart
import 'package:flutter/material.dart';

enum CourseEventType { lecture, tutorial, lab, workshop }

enum CourseEventState { 
  available,    // Can be selected
  selected,     // Currently selected
  conflicted,   // Has time conflict
  disabled      // Cannot be selected
}

mixin CourseEventMixin {
  // Color schemes for different event types
  static const Map<CourseEventType, Color> _baseColors = {
    CourseEventType.lecture: Colors.blue,
    CourseEventType.tutorial: Colors.green,
    CourseEventType.lab: Colors.orange,
    CourseEventType.workshop: Colors.purple,
  };

  // Get color based on event type and state
  Color getEventColor(CourseEventType type, CourseEventState state) {
    final baseColor = _baseColors[type] ?? Colors.grey;
    
    switch (state) {
      case CourseEventState.available:
        return baseColor.withValues(alpha: 0.7);
      case CourseEventState.selected:
        return baseColor;
      case CourseEventState.conflicted:
        return Colors.red.withValues(alpha: 0.8);
      case CourseEventState.disabled:
        return Colors.grey.withValues(alpha: 0.5);
    }
  }

  // Get border color for events (renamed to avoid conflict with CalendarDarkThemeMixin)
  Color getEventBorderColor(CourseEventType type, CourseEventState state) {
    final baseColor = _baseColors[type] ?? Colors.grey;
    
    switch (state) {
      case CourseEventState.selected:
        return baseColor;
      case CourseEventState.conflicted:
        return Colors.red;
      default:
        return baseColor;
    }
  }

  // Get shadow elevation based on state
  double getElevation(CourseEventState state) {
    switch (state) {
      case CourseEventState.selected:
        return 8.0;
      case CourseEventState.available:
        return 4.0;
      case CourseEventState.conflicted:
        return 6.0;
      case CourseEventState.disabled:
        return 1.0;
    }
  }
  // Get text style based on state
  TextStyle getEventTextStyle(CourseEventState state) {
    return TextStyle(
      color: state == CourseEventState.disabled 
          ? Colors.grey.shade600 
          : Colors.white,
      fontWeight: state == CourseEventState.selected 
          ? FontWeight.bold 
          : FontWeight.normal,
      fontSize: 10,
    );
  }

  // Create shadow for events
  List<BoxShadow> getEventShadow(CourseEventState state) {
    final elevation = getElevation(state);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: elevation,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }

  // Get icon for event type
  IconData getEventIcon(CourseEventType type) {
    switch (type) {
      case CourseEventType.lecture:
        return Icons.school;
      case CourseEventType.tutorial:
        return Icons.groups;
      case CourseEventType.lab:
        return Icons.science;
      case CourseEventType.workshop:
        return Icons.build;
    }
  }

  // Format event title
  String formatEventTitle(String courseName, CourseEventType type, int? groupNumber, {String? instructorName}) {
    String typeStr;
    switch (type) {
      case CourseEventType.lecture:
        typeStr = 'Lecture';
        break;
      case CourseEventType.tutorial:
        typeStr = 'Tutorial';
        break;
      case CourseEventType.lab:
        typeStr = 'Lab';
        break;
      case CourseEventType.workshop:
        typeStr = 'Workshop';
        break;
    }
    
    // Build the title components
    final titleParts = <String>[typeStr];
    
    // Add group number if available
    if (groupNumber != null && groupNumber > 0) {
      titleParts[0] = '$typeStr G$groupNumber';
    }
    
    // Add course name
    // add the name of course after splitting it by space and putting every word in a new line
    courseName = courseName.split(' ').join('\n');
    titleParts.add(courseName);
    
    // Add instructor name if available
    // remove the first name from the instructor name
    if (instructorName != null && instructorName.isNotEmpty) {
      final parts = instructorName.split(' ');
      if (parts.length > 1) {
        instructorName = parts.sublist(1).join(' '); // Remove first name
      }
    }
    if (instructorName != null && instructorName.isNotEmpty) {
      titleParts.add(instructorName);
    }
    
    return titleParts.join('\n');
  }

  // Parse course event type from Hebrew text
  CourseEventType parseCourseEventType(String hebrewType) {
    final type = hebrewType.toLowerCase();
    if (type.contains('הרצאה') || type.contains('lecture')) {
      return CourseEventType.lecture;
    } else if (type.contains('תרגול') || type.contains('tutorial')) {
      return CourseEventType.tutorial;
    } else if (type.contains('מעבדה') || type.contains('lab')) {
      return CourseEventType.lab;
    }
    else if (type.contains('סדנה') || type.contains('workshop')) {
      return CourseEventType.workshop;
    }
    return CourseEventType.lecture; // Default
  }  // Convert Hebrew day to DateTime weekday
  int parseHebrewDay(String hebrewDay) {
    // Handle both full Hebrew names and single letters
    final dayMap = {
      // Full Hebrew names
      'ראשון': DateTime.sunday,
      'שני': DateTime.monday,
      'שלישי': DateTime.tuesday,
      'רביעי': DateTime.wednesday,
      'חמישי': DateTime.thursday,
      'שישי': DateTime.friday,
      'שבת': DateTime.saturday,
      // Single Hebrew letters (more common in API)
      'א': DateTime.sunday,
      'ב': DateTime.monday,
      'ג': DateTime.tuesday,
      'ד': DateTime.wednesday,
      'ה': DateTime.thursday,
      'ו': DateTime.friday,
      'ש': DateTime.saturday,
    };
    return dayMap[hebrewDay] ?? DateTime.monday;
  }
  // Convert DateTime weekday constant to day offset from Sunday
  // This is needed because DateTime.weekday uses 1=Monday, 7=Sunday
  // but we need offsets like Sunday=0, Monday=1, ..., Saturday=6
  int getWeekdayOffset(int weekday) {
    if (weekday == DateTime.sunday) {
      return 0; // Sunday is the first day of the week
    } else {
      return weekday; // Monday=1, Tuesday=2, etc.
    }
  }

  // Parse time string like "14:30 - 16:30"
  Map<String, DateTime>? parseTimeRange(String timeRange, DateTime baseDate) {
    try {
      final parts = timeRange.split(' - ');
      if (parts.length != 2) return null;

      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');

      if (startParts.length != 2 || endParts.length != 2) return null;

      final startTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final endTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      return {'start': startTime, 'end': endTime};
    } catch (e) {
      debugPrint('Error parsing time range: $timeRange - $e');
      return null;
    }
  }
}