import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/color_theme_provider.dart';
import '../widgets/course_calendar_panel.dart';
import '../models/student_model.dart';
import '../mixins/calendar_theme_mixin.dart';
import '../mixins/course_event_mixin.dart';
import '../services/course_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> 
    with CalendarDarkThemeMixin, CourseEventMixin {
  int _viewMode = 0; // 0: Week View, 1: Day View
  final TextEditingController _searchController = TextEditingController();
  final _searchQuery = '';
  
  // Track manually added events to preserve them during automatic updates
  final Set<String> _manuallyAddedCourses = <String>{};



  EventController get _eventController =>
      CalendarControllerProvider.of(context).controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Add method to mark course as manually added
  void _markCourseAsManuallyAdded(String courseId) {
    _manuallyAddedCourses.add(courseId);
  }

  // Add method to remove course from manual tracking
  void _removeCourseFromManualTracking(String courseId) {
    _manuallyAddedCourses.remove(courseId);
  }

  @override
  Widget build(BuildContext context) {
    CourseProvider courseProvider = context.read<CourseProvider>(); 
    return Column(
      children: [
        // Course List Panel - Pass callback methods
        if (courseProvider.hasAnyCourses)
          CourseCalendarPanel(
            eventController: _eventController,
            onCourseManuallyAdded: _markCourseAsManuallyAdded,
            onCourseManuallyRemoved: _removeCourseFromManualTracking,
          ),

        // View Mode Tabs
        Container(
          color: Theme.of(context).colorScheme.surface.withAlpha(25),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _viewMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _viewMode == 0
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Week View',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _viewMode == 0
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _viewMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _viewMode == 1
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Day View',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _viewMode == 1
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Day of week header for Week View
        if (_viewMode == 0)
          Container(
            color: Theme.of(context).colorScheme.surface.withAlpha(15),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 50), // Timeline column space
                Expanded(
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'S',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'M',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'T',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'W',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'T',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Calendar Views
        Expanded(
          child: _viewMode == 0 ? _buildWeekView() : _buildDayView(),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    return WeekView(
      controller: _eventController,
      backgroundColor: getCalendarBackgroundColor(context),
      headerStyle: getHeaderStyle(context),
          weekDays: [
      WeekDays.sunday,
      WeekDays.monday,
      WeekDays.tuesday, 
      WeekDays.wednesday,
      WeekDays.thursday,
      
    ],
      weekDayBuilder: (date) => buildWeekDay(context, date),
      timeLineBuilder: (date) => buildTimeLine(context, date),
      liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(context),
      hourIndicatorSettings: getHourIndicatorSettings(context),
      eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
          buildEventTile(
        context,
        date,
        events,
        boundary,
        startDuration,
        endDuration,
        filtered: true,
        searchQuery: _searchQuery,
      ),
      startDay: WeekDays.sunday,
      startHour: 8,
      endHour: 22,
      showLiveTimeLineInAllDays: true,
      // only show events for the current week starting from sunday to thursday
      // Adjust min and max days to show the current week
      minDay: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
      maxDay: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
      initialDay: DateTime.now(),
      heightPerMinute: 1,
      eventArranger: const SideEventArranger(),
    );
  }

  Widget _buildDayView() {
    return DayView(
      controller: _eventController,
      backgroundColor: getCalendarBackgroundColor(context),
      dayTitleBuilder: (date) => buildDayHeader(context, date),
      timeLineBuilder: (date) => buildTimeLine(context, date),
      liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(context),
      hourIndicatorSettings: getHourIndicatorSettings(context),
      eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
          buildEventTile(
        context,
        date,
        events,
        boundary,
        startDuration,
        endDuration,
      ),
      startHour: 8,
      endHour: 22,
      showLiveTimeLineInAllDays: true,
      // only show events for the current week
      // Adjust min and max days to show the current day
      minDay: DateTime.now(),
      // max day last day of the week (next Saturday)
      maxDay: DateTime.now().add(Duration(days: 6 - DateTime.now().weekday)),
      initialDay: DateTime.now(),
      heightPerMinute: 1,
    );
  }

  // Updated calendar event creation to preserve manually added events
  void _updateCalendarEvents(CourseProvider courseProvider, ColorThemeProvider colorThemeProvider) {
    debugPrint('=== Updating calendar events with schedule selection ===');
    
    // Store manually added events before clearing
    final manualEvents = <CalendarEventData>[];
    final existingEvents = _eventController.allEvents;
    
    for (final event in existingEvents) {
      // Check if this event belongs to a manually added course
      // We'll identify manual events by checking if they contain course names from manually added courses
      for (final courseId in _manuallyAddedCourses) {
        // Find the course name from the course provider
        StudentCourse? course;
        for (final semesterCourses in courseProvider.coursesBySemester.values) {
          final foundCourse = semesterCourses.where((c) => c.courseId == courseId).firstOrNull;
          if (foundCourse != null) {
            course = foundCourse;
            break;
          }
        }
        
        if (course != null && event.title.contains(course.name)) {
          manualEvents.add(event);
          debugPrint('Preserving manually added event: ${event.title}');
          break;
        }
      }
    }
    
    // Clear existing events
    _eventController.removeWhere((event) => true);
    
    // Re-add manually added events
    for (final manualEvent in manualEvents) {
      _eventController.add(manualEvent);
    }
    
    // Get current week start (Sunday)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    debugPrint('Current week start (Sunday): $currentWeekStart');

    final semesterCount = courseProvider.coursesBySemester.length;
    debugPrint('Found $semesterCount semesters with courses');
    
    final courseDataProvider = context.read<CourseDataProvider>();
    
    for (final semesterEntry in courseProvider.coursesBySemester.entries) {
      // process only the current semester
      if (courseDataProvider.currentSemester != null && 
          semesterEntry.key != courseDataProvider.currentSemester!.semesterName) {
        debugPrint('Skipping semester "${semesterEntry.key}" as it is not the current semester');
        continue;
      }

      final semester = semesterEntry.key;
      final courses = semesterEntry.value;
      debugPrint('Processing semester "$semester" with ${courses.length} courses');
      
      for (final course in courses) {
        // Skip manually added courses to avoid duplicates
        if (_manuallyAddedCourses.contains(course.courseId)) {
          debugPrint('Skipping course ${course.name} as it was manually added');
          continue;
        }
        
        debugPrint('Processing course: ${course.name} (${course.courseId})');
        debugPrint('Has selected lecture: ${course.hasSelectedLecture}, Has selected tutorial: ${course.hasSelectedTutorial}');
        
        // Get course details to access schedule
        context.read<CourseDataProvider>().getCourseDetails(course.courseId).then((courseDetails) {
          if (courseDetails?.schedule.isNotEmpty == true) {
            debugPrint('Using API schedule for ${course.name} with selection filtering');
            _createCalendarEventsFromSchedule(course, courseDetails!, semester, currentWeekStart, colorThemeProvider);
          } else {
            debugPrint('Using basic schedule for ${course.name} (lecture: "${course.lectureTime}", tutorial: "${course.tutorialTime}")');
            // Create basic events from stored lecture/tutorial times if no API schedule
            _createBasicCalendarEvents(course, semester, currentWeekStart, colorThemeProvider);
          }
        });
      }
    }
  }

  // Helper method to check for time conflicts with existing events
  bool _hasTimeConflict(DateTime startTime, DateTime endTime) {
    final existingEvents = _eventController.allEvents;
    
    for (final event in existingEvents) {
      if (event.startTime != null && event.endTime != null) {
        // Check if the new event overlaps with existing event
        final eventStart = event.startTime!;
        final eventEnd = event.endTime!;
        
        // Events conflict if: new_start < existing_end AND existing_start < new_end
        if (startTime.isBefore(eventEnd) && eventStart.isBefore(endTime)) {
          return true;
        }
      }
    }
    return false;
  }

  // Helper method to find conflicting events for detailed feedback
  List<CalendarEventData> _getConflictingEvents(DateTime startTime, DateTime endTime) {
    final conflictingEvents = <CalendarEventData>[];
    final existingEvents = _eventController.allEvents;
    
    for (final event in existingEvents) {
      if (event.startTime != null && event.endTime != null) {
        final eventStart = event.startTime!;
        final eventEnd = event.endTime!;
        
        if (startTime.isBefore(eventEnd) && eventStart.isBefore(endTime)) {
          conflictingEvents.add(event);
        }
      }
    }
    return conflictingEvents;
  }

  void _createCalendarEventsFromSchedule(
    StudentCourse course, 
    EnhancedCourseDetails courseDetails, 
    String semester,
    DateTime weekStart,
    ColorThemeProvider colorThemeProvider,
  ) {
    debugPrint('Creating calendar events for ${course.name} with schedule selection');
    
    // Get selected schedule entries only
    final selectedEntries = context.read<CourseProvider>()
        .getSelectedScheduleEntries(course.courseId, courseDetails);
    
    final selectedLecture = selectedEntries['lecture'];
    final selectedTutorial = selectedEntries['tutorial'];
    
    // Create events only for selected schedule entries
    final scheduleEntriesToShow = <ScheduleEntry>[];
    
    if (selectedLecture != null) {
      scheduleEntriesToShow.add(selectedLecture);
      debugPrint('Adding selected lecture: ${selectedLecture.day} ${selectedLecture.time}');
    }
    
    if (selectedTutorial != null) {
      scheduleEntriesToShow.add(selectedTutorial);
      debugPrint('Adding selected tutorial: ${selectedTutorial.day} ${selectedTutorial.time}');
    }
    
    // If no selections made, show all (backward compatibility)
    if (scheduleEntriesToShow.isEmpty && !course.hasCompleteScheduleSelection) {
      scheduleEntriesToShow.addAll(courseDetails.schedule);
      debugPrint('No selections made, showing all ${courseDetails.schedule.length} schedule entries');
    }
    
    // Create calendar events
    for (final schedule in scheduleEntriesToShow) {
      debugPrint('Processing schedule: day="${schedule.day}", time="${schedule.time}", type="${schedule.type}"');
      
      // Parse Hebrew day to weekday number
      final dayOfWeek = parseHebrewDay(schedule.day);
      debugPrint('Parsed day "${schedule.day}" to weekday $dayOfWeek');
      
      // Convert DateTime weekday to correct offset from Monday
      final dayOffset = getWeekdayOffset(dayOfWeek);
      
      final eventDate = weekStart.add(Duration(days: dayOffset));
      debugPrint('Event date calculated: $eventDate (offset: $dayOffset from week start: $weekStart)');
      
      // Parse time range
      final timeRange = parseTimeRange(schedule.time, eventDate);
      if (timeRange == null) {
        debugPrint('Failed to parse time range: ${schedule.time}');
        continue;
      }
        // Get event type and create appropriate event
      final eventType = parseCourseEventType(schedule.type);
      
      // Check for time conflicts before adding the event
      final hasConflict = _hasTimeConflict(timeRange['start']!, timeRange['end']!);
      if (hasConflict) {
        final conflictingEvents = _getConflictingEvents(timeRange['start']!, timeRange['end']!);
        final conflictingTitles = conflictingEvents.map((e) => e.title).join(', ');
        debugPrint('Time conflict detected for ${course.name} (${schedule.type}) with: $conflictingTitles');
        
        // For automatic updates, skip conflicting events or replace them
        // You can customize this behavior based on requirements
        for (final conflictingEvent in conflictingEvents) {
          debugPrint('Removing conflicting event: ${conflictingEvent.title}');
          _eventController.remove(conflictingEvent);
        }
      }
        final event = CalendarEventData(
        date: eventDate,
        title: formatEventTitle(
          course.name, 
          eventType, 
          schedule.group > 0 ? schedule.group : null,
          instructorName: schedule.staff.isNotEmpty ? schedule.staff : null,
        ),
        description: _buildEventDescription(course, schedule, semester),
        startTime: timeRange['start']!,
        endTime: timeRange['end']!,
        color: colorThemeProvider.getCourseColor(course.courseId),
      );
      
      debugPrint('Created calendar event: ${event.title} on ${event.date} from ${event.startTime} to ${event.endTime}');
      _eventController.add(event);
    }
  }

  void _createBasicCalendarEvents(
    StudentCourse course, 
    String semester,
    DateTime weekStart,
    ColorThemeProvider colorThemeProvider,
  ) {
    final courseColor = colorThemeProvider.getCourseColor(course.courseId);
    
    // Create events from stored lecture time
    if (course.lectureTime.isNotEmpty) {
      final lectureEvent = _createEventFromTimeString(
        course, 
        course.lectureTime, 
        'Lecture', 
        semester,
        weekStart,
        courseColor,
      );
      if (lectureEvent != null) {
        // Check for conflicts before adding
        final hasConflict = _hasTimeConflict(lectureEvent.startTime!, lectureEvent.endTime!);
        if (hasConflict) {
          final conflictingEvents = _getConflictingEvents(lectureEvent.startTime!, lectureEvent.endTime!);
          for (final conflictingEvent in conflictingEvents) {
            debugPrint('Removing conflicting event: ${conflictingEvent.title}');
            _eventController.remove(conflictingEvent);
          }
        }
        _eventController.add(lectureEvent);
      }
    }
    
    // Create events from stored tutorial time
    if (course.tutorialTime.isNotEmpty) {
      final tutorialEvent = _createEventFromTimeString(
        course, 
        course.tutorialTime, 
        'Tutorial', 
        semester,
        weekStart,
        courseColor,
      );
      if (tutorialEvent != null) {
        // Check for conflicts before adding
        final hasConflict = _hasTimeConflict(tutorialEvent.startTime!, tutorialEvent.endTime!);
        if (hasConflict) {
          final conflictingEvents = _getConflictingEvents(tutorialEvent.startTime!, tutorialEvent.endTime!);
          for (final conflictingEvent in conflictingEvents) {
            debugPrint('Removing conflicting event: ${conflictingEvent.title}');
            _eventController.remove(conflictingEvent);
          }
        }
        _eventController.add(tutorialEvent);
      }
    }
  }

  CalendarEventData? _createEventFromTimeString(
    StudentCourse course,
    String timeString,
    String eventType,
    String semester,
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
      dayOfWeek = parseHebrewDay(dayPart);
    } else {
      // English day name
      dayOfWeek = _parseEnglishDay(dayPart);
    }
      if (dayOfWeek == null || timePart.isEmpty) return null;
    
    // Convert DateTime weekday to correct offset from Sunday
    final dayOffset = getWeekdayOffset(dayOfWeek);
    
    final eventDate = weekStart.add(Duration(days: dayOffset));
    final timeRange = parseTimeRange(timePart, eventDate);
    
    if (timeRange == null) return null;
    
    // Convert eventType string to CourseEventType for consistent formatting
    final courseEventType = _parseEventType(eventType);
    
    return CalendarEventData(
      date: eventDate,
      title: formatEventTitle(course.name, courseEventType, null),
      description: '${course.courseId} - $semester\n$eventType: $timeString',
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

  // Helper method to convert eventType string to CourseEventType
  CourseEventType _parseEventType(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'lecture':
        return CourseEventType.lecture;
      case 'tutorial':
        return CourseEventType.tutorial;
      case 'lab':
        return CourseEventType.lab;
      default:
        return CourseEventType.lecture; // Default fallback
    }
  }

  String _buildEventDescription(StudentCourse course, ScheduleEntry schedule, String semester) {
    final parts = <String>[];
    parts.add('${course.courseId} - $semester');
    
    if (schedule.staff.isNotEmpty) {
      parts.add('Instructor: ${schedule.staff}');
    }
    if (schedule.fullLocation.isNotEmpty) {
      parts.add('Location: ${schedule.fullLocation}');
    }
    if (schedule.type.isNotEmpty) {
      parts.add('Type: ${schedule.type}');
    }
    if (course.note?.isNotEmpty == true) {
      parts.add('Note: ${course.note}');
    }
    
    return parts.join('\n');
  }

}
