// lib/widgets/course_calendar_panel.dart - Updated with ColorThemeProvider
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/color_theme_provider.dart';
import '../models/student_model.dart';
import 'schedule_selection_dialog.dart';

class CourseCalendarPanel extends StatefulWidget {
  final EventController eventController;
  
  const CourseCalendarPanel({
    Key? key, 
    required this.eventController,
  }) : super(key: key);

  @override
  State<CourseCalendarPanel> createState() => _CourseCalendarPanelState();
}

class _CourseCalendarPanelState extends State<CourseCalendarPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer4<StudentProvider, CourseProvider, CourseDataProvider, ColorThemeProvider>(
      builder: (context, studentProvider, courseProvider, courseDataProvider, colorThemeProvider, _) {
        final allCourses = courseProvider.coursesBySemester.values
            .expand((courses) => courses)
            .toList();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Courses (${allCourses.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  children: [
                    const Divider(height: 1),
                    if (allCourses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No courses added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allCourses.length,
                        itemBuilder: (context, index) {
                          final course = allCourses[index];
                          
                          return FutureBuilder(
                            future: courseDataProvider.getCourseDetails(course.courseId),
                            builder: (context, snapshot) {
                              final courseDetails = snapshot.data;
                              
                              return ListTile(
                                leading: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorThemeProvider.getCourseColor(course.courseId),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(course.name)),
                                    // Selection indicators
                                    if (course.hasSelectedLecture)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(50),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue, width: 1),
                                        ),
                                        child: const Text(
                                          'L',
                                          style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (course.hasSelectedTutorial)
                                      Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(50),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green, width: 1),
                                        ),
                                        child: const Text(
                                          'T',
                                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${course.courseId}'),
                                    if (courseDetails != null)
                                      Text('Credits: ${courseDetails.creditPoints}')
                                    else if (snapshot.connectionState == ConnectionState.waiting)
                                      const Text('Loading...', style: TextStyle(fontSize: 12))
                                    else
                                      const Text('Details unavailable', style: TextStyle(fontSize: 12)),
                                    
                                    // Show selection status
                                    if (course.hasCompleteScheduleSelection)
                                      Text(
                                        'Schedule: ${course.selectionSummary}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Schedule: All times shown',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'select_schedule':
                                        _showScheduleSelection(course, courseDetails);
                                        break;
                                      case 'add_to_calendar':
                                        _addCourseToCalendar(course, courseDetails, colorThemeProvider);
                                        break;
                                      case 'remove_from_calendar':
                                        _removeCourseFromCalendar(course);
                                        break;
                                      case 'view_details':
                                        _showCourseDetails(context, course, courseDetails);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'select_schedule',
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule),
                                          SizedBox(width: 8),
                                          Text('Select Schedule'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'add_to_calendar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add_to_photos),
                                          SizedBox(width: 8),
                                          Text('Add to Calendar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove_from_calendar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.remove_circle),
                                          SizedBox(width: 8),
                                          Text('Remove from Calendar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'view_details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.info),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScheduleSelection(StudentCourse course, courseDetails) {
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
        onSelectionChanged: (lectureTime, tutorialTime) {
          _updateCourseScheduleSelection(course, lectureTime, tutorialTime);
        },
      ),
    );
  }

  void _updateCourseScheduleSelection(
    StudentCourse course,
    String? lectureTime,
    String? tutorialTime,
  ) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (!studentProvider.hasStudent) return;

    // Find which semester this course belongs to
    String? targetSemester;
    for (final entry in courseProvider.coursesBySemester.entries) {
      if (entry.value.any((c) => c.courseId == course.courseId)) {
        targetSemester = entry.key;
        break;
      }
    }

    if (targetSemester == null) return;

    final success = await courseProvider.updateCourseScheduleSelection(
      studentProvider.student!.id,
      targetSemester,
      course.courseId,
      lectureTime,
      tutorialTime,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule selection updated')),
      );
      
      // Refresh calendar events
      setState(() {});
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update schedule selection'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCourseToCalendar(StudentCourse course, courseDetails, ColorThemeProvider colorThemeProvider) {
    if (courseDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course details not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get the current week's Monday
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      
      final courseColor = colorThemeProvider.getCourseColor(course.courseId);
      int eventsAdded = 0;
      
      // Create events from detailed schedule data only for selected times
      final courseProvider = context.read<CourseProvider>();
      final selectedEntries = courseProvider.getSelectedScheduleEntries(course.courseId, courseDetails);
      
      final scheduleEntriesToShow = <dynamic>[];
      if (selectedEntries['lecture'] != null) {
        scheduleEntriesToShow.add(selectedEntries['lecture']);
      }
      if (selectedEntries['tutorial'] != null) {
        scheduleEntriesToShow.add(selectedEntries['tutorial']);
      }
      
      // If no selections made, show all (backward compatibility)
      if (scheduleEntriesToShow.isEmpty && !course.hasCompleteScheduleSelection) {
        scheduleEntriesToShow.addAll(courseDetails.schedule);
      }
      
      for (final schedule in scheduleEntriesToShow) {
        final dayOfWeek = _parseHebrewDay(schedule.day);
        if (dayOfWeek == null) continue;
        
        final eventDate = monday.add(Duration(days: dayOfWeek - 1));
        final timeRange = _parseTimeRange(schedule.time, eventDate);
        if (timeRange == null) continue;
        
        final event = CalendarEventData(
          title: '${course.name} (${schedule.type})',
          description: _buildEventDescription(course, schedule),
          date: eventDate,
          startTime: timeRange['start']!,
          endTime: timeRange['end']!,
          color: courseColor,
        );
        
        widget.eventController.add(event);
        eventsAdded++;
      }
      
      // If no detailed schedule, try to create events from stored times
      if (eventsAdded == 0) {
        eventsAdded += _addBasicTimeEvents(course, monday, courseColor);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${course.name} added to calendar ($eventsAdded events)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding course to calendar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeCourseFromCalendar(StudentCourse course) {
    int removedCount = 0;
    widget.eventController.removeWhere((event) {
      final shouldRemove = event.title.contains(course.name);
      if (shouldRemove) removedCount++;
      return shouldRemove;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} removed from calendar ($removedCount events)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCourseDetails(BuildContext context, StudentCourse course, courseDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Course ID: ${course.courseId}'),
              if (courseDetails != null) ...[
                const SizedBox(height: 8),
                Text('Credits: ${courseDetails.creditPoints}'),
                Text('Faculty: ${courseDetails.faculty}'),
                if (courseDetails.prerequisites.isNotEmpty)
                  Text('Prerequisites: ${courseDetails.prerequisites}'),
                if (courseDetails.syllabus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Syllabus:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(courseDetails.syllabus),
                ],
              ],
              if (course.note?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                const Text('Personal Note:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(course.note!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper methods for parsing Hebrew days and times
  int? _parseHebrewDay(String hebrewDay) {
    final dayMap = {
      'א': DateTime.sunday,
      'ב': DateTime.monday,
      'ג': DateTime.tuesday,
      'ד': DateTime.wednesday,
      'ה': DateTime.thursday,
      'ו': DateTime.friday,
      'ש': DateTime.saturday,
    };
    return dayMap[hebrewDay];
  }

  Map<String, DateTime>? _parseTimeRange(String timeRange, DateTime baseDate) {
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

  String _buildEventDescription(StudentCourse course, dynamic schedule) {
    final parts = <String>[];
    parts.add('Course ID: ${course.courseId}');
    
    if (schedule.staff?.isNotEmpty == true) {
      parts.add('Instructor: ${schedule.staff}');
    }
    if (schedule.fullLocation?.isNotEmpty == true) {
      parts.add('Location: ${schedule.fullLocation}');
    }
    if (schedule.type?.isNotEmpty == true) {
      parts.add('Type: ${schedule.type}');
    }
    if (course.note?.isNotEmpty == true) {
      parts.add('Note: ${course.note}');
    }
    
    return parts.join('\n');
  }

  int _addBasicTimeEvents(StudentCourse course, DateTime monday, Color courseColor) {
    int eventsAdded = 0;
    
    // Create events from stored lecture time
    if (course.lectureTime.isNotEmpty) {
      final lectureEvent = _createEventFromTimeString(
        course, 
        course.lectureTime, 
        'Lecture', 
        monday,
        courseColor,
      );
      if (lectureEvent != null) {
        widget.eventController.add(lectureEvent);
        eventsAdded++;
      }
    }
    
    // Create events from stored tutorial time
    if (course.tutorialTime.isNotEmpty) {
      final tutorialEvent = _createEventFromTimeString(
        course, 
        course.tutorialTime, 
        'Tutorial', 
        monday,
        courseColor,
      );
      if (tutorialEvent != null) {
        widget.eventController.add(tutorialEvent);
        eventsAdded++;
      }
    }
    
    return eventsAdded;
  }

  CalendarEventData? _createEventFromTimeString(
    StudentCourse course,
    String timeString,
    String eventType,
    DateTime weekStart,
    Color color,
  ) {
    // Try to parse time string like "Monday 10:00-12:00" or "ב 10:00-12:00"
    final parts = timeString.split(' ');
    if (parts.length < 2) return null;
    
    final dayPart = parts[0];
    final timePart = parts.length > 1 ? parts[1] : '';
    
    // Parse day (Hebrew or English)
    int? dayOfWeek;
    if (dayPart.length == 1) {
      // Hebrew single letter
      dayOfWeek = _parseHebrewDay(dayPart);
    } else {
      // English day name
      dayOfWeek = _parseEnglishDay(dayPart);
    }
    
    if (dayOfWeek == null || timePart.isEmpty) return null;
    
    // Convert DateTime weekday to correct offset from Monday
    final dayOffset = dayOfWeek == DateTime.sunday ? 6 : dayOfWeek - 1;
    
    final eventDate = weekStart.add(Duration(days: dayOffset));
    final timeRange = _parseTimeRange(timePart, eventDate);
    
    if (timeRange == null) return null;
    
    return CalendarEventData(
      date: eventDate,
      title: '$eventType\n${course.name}',
      description: '${course.courseId}\n$eventType: $timeString',
      startTime: timeRange['start']!,
      endTime: timeRange['end']!,
      color: color,
    );
  }

  int? _parseEnglishDay(String englishDay) {
    final dayMap = {
      'sunday': DateTime.sunday,
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
    };
    return dayMap[englishDay.toLowerCase()];
  }
}
