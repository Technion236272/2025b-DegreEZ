import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/color_theme_provider.dart';
import '../widgets/course_calendar_panel.dart';
import '../models/student_model.dart';
import '../mixins/calendar_theme_mixin.dart';
import '../mixins/course_event_mixin.dart';
import '../mixins/schedule_selection_mixin.dart';
import '../services/course_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> 
    with CalendarDarkThemeMixin, CourseEventMixin, ScheduleSelectionMixin {
  int _viewMode = 0; // 0: Week View, 1: Day View
  final TextEditingController _searchController = TextEditingController();
  final _searchQuery = '';
  
  // NEW: Track courses that should be hidden from calendar
  final Set<String> _removedCourses = <String>{};
    // Flag to track if we need to trigger the initial view switch to load events
  bool _hasTriggeredInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _loadRemovedCourses();
  }



  EventController get _eventController =>
      CalendarControllerProvider.of(context).controller;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }  // NEW: Methods to manage removed courses from calendar display
  void _markCourseAsRemovedFromCalendar(String courseId) {
    _removedCourses.add(courseId);
    _saveRemovedCourses(); // Persist the change
    debugPrint('Course $courseId marked as removed from calendar');
    // Trigger calendar refresh
    setState(() {});
  }
  
  bool _isCourseRemovedFromCalendar(String courseId) {
    return _removedCourses.contains(courseId);
  }
  // Build the course panel with integrated toggle button
  Widget _buildCoursePanelWithIntegratedToggle(CourseProvider courseProvider) {
    if (!courseProvider.hasAnyCourses) {
      return const SizedBox.shrink();
    }
      return CourseCalendarPanel(
      eventController: _eventController,
      onCourseRemovedFromCalendar: _markCourseAsRemovedFromCalendar,
      onCourseRestoredToCalendar: _restoreCourseToCalendar,
      isCourseRemovedFromCalendar: _isCourseRemovedFromCalendar,
      viewMode: _viewMode,
      onToggleView: () => setState(() => _viewMode = _viewMode == 0 ? 1 : 0),
    );
  }

@override
  Widget build(BuildContext context) {
    return Consumer4<LogInNotifier, StudentProvider, CourseProvider, ColorThemeProvider>(
      builder: (context, loginNotifier, studentProvider, courseProvider, colorThemeProvider, _) {
        // Update calendar events when courses change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (studentProvider.hasStudent && courseProvider.hasLoadedData) {
            _updateCalendarEvents(courseProvider, colorThemeProvider);
            
            // Force a rebuild to ensure events are displayed
            if (!_hasTriggeredInitialLoad) {
              _hasTriggeredInitialLoad = true;
              // Force the EventController to notify its listeners
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  // Trigger a rebuild by toggling a state that forces calendar refresh
                  setState(() {
                    // This setState will cause the calendar to rebuild and show events
                  });
                }
              });
            }
          }        });return Column(
          children: [
            // Course Panel with integrated Toggle Button
            _buildCoursePanelWithIntegratedToggle(courseProvider),

            // Calendar Views - Full Width
            Expanded(
              child: _viewMode == 0 ? _buildWeekView() : _buildDayView(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekView() {
    return ClipRect(
      child: WeekView(
        controller: _eventController,
        backgroundColor: getCalendarBackgroundColor(context),
        weekPageHeaderBuilder: WeekHeader.hidden,
        // add the month and year to the header but smaller to fit here in weekNumberBuilder
        weekNumberBuilder: (date) => 
        Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // shrink-wrap content
        children: [
          Transform.rotate(
            angle: -pi / 6, // about -30 degrees
            child: Text(
              DateFormat('yyyy').format(date),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Transform.rotate(
            angle: -pi / 6, // same angle to match above
            child: Text(
              '       ${DateFormat('MMM').format(date)}',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,color: AppColorsDarkMode.secondaryColorDim),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
        // showWeekTileBorder: false,
        // Completely transparent and minimal header
        // headerStyle: HeaderStyle(
        //   decoration: const BoxDecoration(color: Colors.transparent),
        //   headerTextStyle: const TextStyle(fontSize: 0, height: 0),
        //   headerMargin: EdgeInsets.zero,
        //   headerPadding: EdgeInsets.zero,
        // ),
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
          onTap: _onEventTap,
          onLongPress: _showCourseDetailsDialog,
        ),
        startDay: WeekDays.sunday,
        startHour: 8,
        endHour: 22,
        showLiveTimeLineInAllDays: true,
        // only show events for the current week starting from sunday to thursday
        // Adjust min and max days to show the current week
        // show only current week
        minDay: DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7)),
        maxDay: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday % 7)),
        initialDay: DateTime.now(),
        heightPerMinute: 1,
        eventArranger: const SideEventArranger(),
      ),
    );
  }

  Widget _buildDayView() {
    return DayView(
      controller: _eventController,
      backgroundColor: getCalendarBackgroundColor(context), 
      dayTitleBuilder: (date) => buildDayHeader(context, date),
      timeLineBuilder: (date) => buildTimeLine(context, date),
      liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(context),
      hourIndicatorSettings: getHourIndicatorSettings(context),      eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
          buildEventTile(
        context,
        date,
        events,
        boundary,
        startDuration,
        endDuration,          onTap: _onEventTap,
        onLongPress: _showCourseDetailsDialog,
      ),
      startHour: 8,
      endHour: 22,
      showLiveTimeLineInAllDays: true,
      // only show events for the current week
      // Adjust min and max days to show the current week

      minDay: DateTime.now(),
      // max day last day of the week (next Saturday)
      maxDay: DateTime.now(),
      initialDay: DateTime.now(),
      heightPerMinute: 1,
      eventArranger: const SideEventArranger(),
    );
  }
    // Updated calendar event creation to preserve manually added events
  void _updateCalendarEvents(CourseProvider courseProvider, ColorThemeProvider colorThemeProvider) {
    debugPrint('=== Updating calendar events with schedule selection ===');

    // Clear existing events
    _eventController.removeWhere((event) => true);
    
    // Get current week start (Sunday)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    debugPrint('Current week start (Sunday): $currentWeekStart');

    final semesterCount = courseProvider.coursesBySemester.length;
    debugPrint('Found $semesterCount semesters with courses');
    
    final courseDataProvider = context.read<CourseDataProvider>();
    int totalEventsAdded = 0;
    
    for (final semesterEntry in courseProvider.coursesBySemester.entries) {
      // process only the current semester
      if (courseDataProvider.currentSemester != null && 
          semesterEntry.key != courseDataProvider.currentSemester!.semesterName) {
        debugPrint('Skipping semester "${semesterEntry.key}" as it is not the current semester');
        continue;
      }

      final semester = semesterEntry.key;
      final courses = semesterEntry.value;
      debugPrint('Processing semester "$semester" with ${courses.length} courses');      for (final course in courses) {
        // NEW: Skip courses that are marked as removed from calendar
        if (_isCourseRemovedFromCalendar(course.courseId)) {
          debugPrint('Skipping course ${course.name} as it was removed from calendar');
          continue;
        }
        
        debugPrint('Processing course: ${course.name} (${course.courseId})');
        debugPrint('Has selected lecture: ${course.hasSelectedLecture}, Has selected tutorial: ${course.hasSelectedTutorial}');
        
        // Get course details to access schedule
        context.read<CourseDataProvider>().getCourseDetails(course.courseId).then((courseDetails) {
          if (courseDetails?.schedule.isNotEmpty == true) {
            debugPrint('Using API schedule for ${course.name} with selection filtering');
            final eventsAdded = _createCalendarEventsFromSchedule(course, courseDetails!, semester, currentWeekStart, colorThemeProvider);
            totalEventsAdded += eventsAdded;
          } else {
            debugPrint('Using basic schedule for ${course.name} (lecture: "${course.lectureTime}", tutorial: "${course.tutorialTime}", lab: "${course.labTime}", workshop: "${course.workshopTime}")');
            // Create basic events from stored lecture/tutorial/lab/workshop times if no API schedule
            final eventsAdded = _createBasicCalendarEvents(course, semester, currentWeekStart, colorThemeProvider);
            totalEventsAdded += eventsAdded;
          }
          
          // After processing all courses, force a UI refresh
          if (mounted) {
            setState(() {
              // Force rebuild to show new events
            });
          }
        });
      }
    }
    
    debugPrint('Total events added: $totalEventsAdded');
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
  }  int _createCalendarEventsFromSchedule(
    StudentCourse course, 
    EnhancedCourseDetails courseDetails, 
    String semester,
    DateTime weekStart,
    ColorThemeProvider colorThemeProvider,
  ) {
    // NEW: Skip courses that are marked as removed from calendar
    if (_isCourseRemovedFromCalendar(course.courseId)) {
      debugPrint('Skipping events for course ${course.name} as it was removed from calendar');
      return 0;
    }
    
    debugPrint('Creating calendar events for ${course.name} with schedule selection');
    int eventsAdded = 0;
      // Get selected schedule entries only
    final selectedEntries = context.read<CourseProvider>()
        .getSelectedScheduleEntries(course.courseId, courseDetails);
    
    final selectedLectures = selectedEntries['lecture'] ?? <ScheduleEntry>[];
    final selectedTutorials = selectedEntries['tutorial'] ?? <ScheduleEntry>[];
    final selectedLabs = selectedEntries['lab'] ?? <ScheduleEntry>[];
    final selectedWorkshops = selectedEntries['workshop'] ?? <ScheduleEntry>[];
    
    // Create events only for selected schedule entries
    final scheduleEntriesToShow = <ScheduleEntry>[];
    
    // Add all selected lectures
    scheduleEntriesToShow.addAll(selectedLectures);
    if (selectedLectures.isNotEmpty) {
      debugPrint('Adding ${selectedLectures.length} selected lectures');
      for (final lecture in selectedLectures) {
        debugPrint('  - Lecture: ${lecture.day} ${lecture.time}');
      }
    }
    
    // Add all selected tutorials
    scheduleEntriesToShow.addAll(selectedTutorials);
    if (selectedTutorials.isNotEmpty) {
      debugPrint('Adding ${selectedTutorials.length} selected tutorials');
      for (final tutorial in selectedTutorials) {
        debugPrint('  - Tutorial: ${tutorial.day} ${tutorial.time}');
      }
    }

    // Add all selected labs
    scheduleEntriesToShow.addAll(selectedLabs);
    if (selectedLabs.isNotEmpty) {
      debugPrint('Adding ${selectedLabs.length} selected labs');
      for (final lab in selectedLabs) {
        debugPrint('  - Lab: ${lab.day} ${lab.time}');
      }
    }

    // Add all selected workshops
    scheduleEntriesToShow.addAll(selectedWorkshops);
    if (selectedWorkshops.isNotEmpty) {
      debugPrint('Adding ${selectedWorkshops.length} selected workshops');
      for (final workshop in selectedWorkshops) {
        debugPrint('  - Workshop: ${workshop.day} ${workshop.time}');
      }
    }// If no selections made, show all (backward compatibility)
    if (scheduleEntriesToShow.isEmpty && !course.hasCompleteScheduleSelection) {
      scheduleEntriesToShow.addAll(courseDetails.schedule);
      debugPrint('No selections made, showing all ${courseDetails.schedule.length} schedule entries');
    }
    
    // Deduplicate schedule entries by time and type to avoid multiple events for the same lecture
    final uniqueScheduleEntries = <ScheduleEntry>[];
    final seenTimeSlots = <String>{};
    
    for (final schedule in scheduleEntriesToShow) {
      final timeSlotKey = '${schedule.day}_${schedule.time}_${schedule.type}';
      if (!seenTimeSlots.contains(timeSlotKey)) {
        uniqueScheduleEntries.add(schedule);
        seenTimeSlots.add(timeSlotKey);
        debugPrint('Added unique schedule: ${schedule.type} on ${schedule.day} at ${schedule.time}');
      } else {
        debugPrint('Skipped duplicate schedule: ${schedule.type} on ${schedule.day} at ${schedule.time} (Group ${schedule.group})');
      }
    }
    
    // Create calendar events from unique schedule entries
    for (final schedule in uniqueScheduleEntries) {
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
        
        // Allow SideEventArranger to handle conflicts by showing events side by side
        // Don't remove conflicting events - let the calendar view arrange them properly
        debugPrint('Allowing SideEventArranger to handle conflict display');
      }        final event = CalendarEventData(
        date: eventDate,
        title: formatEventTitle(
          course.name, 
          eventType, 
          null, // Don't show group number since we're deduplicating
          instructorName: schedule.staff.isNotEmpty ? schedule.staff : null,
        ),
        description: _buildEventDescription(course, schedule, semester),
        startTime: timeRange['start']!,
        endTime: timeRange['end']!,
        color: colorThemeProvider.getCourseColor(course.courseId),
      );      
      debugPrint('Created calendar event: ${event.title} on ${event.date} from ${event.startTime} to ${event.endTime}');
      _eventController.add(event);
      eventsAdded++;
    }
    
    return eventsAdded;
  }  int _createBasicCalendarEvents(
    StudentCourse course, 
    String semester,
    DateTime weekStart,
    ColorThemeProvider colorThemeProvider,
  ) {
    // NEW: Skip courses that are marked as removed from calendar
    if (_isCourseRemovedFromCalendar(course.courseId)) {
      debugPrint('Skipping basic events for course ${course.name} as it was removed from calendar');
      return 0;
    }
    
    final courseColor = colorThemeProvider.getCourseColor(course.courseId);
    int eventsAdded = 0;
    
    // Create events from stored lecture time
    if (course.lectureTime.isNotEmpty) {
      final lectureEvent = _createEventFromTimeString(
        course, 
        course.lectureTime, 
        'Lecture', 
        semester,
        weekStart,
        courseColor,
      );      if (lectureEvent != null) {
        // Check for conflicts before adding
        final hasConflict = _hasTimeConflict(lectureEvent.startTime!, lectureEvent.endTime!);
        if (hasConflict) {
          debugPrint('Time conflict detected for ${course.name} lecture - allowing SideEventArranger to handle display');
        }
        _eventController.add(lectureEvent);
        eventsAdded++;
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
      );      if (tutorialEvent != null) {
        // Check for conflicts before adding
        final hasConflict = _hasTimeConflict(tutorialEvent.startTime!, tutorialEvent.endTime!);
        if (hasConflict) {
          debugPrint('Time conflict detected for ${course.name} tutorial - allowing SideEventArranger to handle display');
        }
        _eventController.add(tutorialEvent);
        eventsAdded++;
      }
    }
    
    return eventsAdded;
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
      case 'workshop':
        return CourseEventType.workshop;
      default:
        return CourseEventType.lecture; // Default fallback
    }
  }

  // Helper method to build event description for course events
  String _buildEventDescription(StudentCourse course, dynamic schedule, String semester) {
    final parts = <String>[];
    
    // Add course ID and semester for course identification during removal
    parts.add('${course.courseId} - $semester');
    
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
  // Method to show course's details popup on long press on the event tile
  void _showCourseDetailsDialog(CalendarEventData event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Course Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text('You long pressed on a calendar event!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event: ${event.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (event.description != null)
                    Text('Description: ${event.description}'),
                  if (event.startTime != null && event.endTime != null)
                    // dont display seconds in time
                    Text('Time: ${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Extract course ID and semester from event description
  Map<String, String>? _extractCourseInfoFromEvent(CalendarEventData event) {
    if (event.description == null) return null;
    
    // The description contains course ID and semester in format: "courseId - semester"
    final lines = event.description!.split('\n');
    for (final line in lines) {
      if (line.contains(' - ')) {
        final parts = line.split(' - ');
        if (parts.length >= 2) {
          return {
            'courseId': parts[0].trim(),
            'semester': parts[1].trim(),
          };
        }
      }
    }
    return null;  }

  // Method to handle tap on calendar event - opens schedule selection using shared mixin
  void _onEventTap(CalendarEventData event) async {
    final courseInfo = _extractCourseInfoFromEvent(event);
    if (courseInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find course information for this event'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final courseId = courseInfo['courseId']!;
    final semester = courseInfo['semester']!;

    // Get course provider and student provider
    final courseProvider = context.read<CourseProvider>();
    final studentProvider = context.read<StudentProvider>();

    if (!studentProvider.hasStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No student logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the course in the semester
    final semesterCourses = courseProvider.coursesBySemester[semester];
    if (semesterCourses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semester "$semester" not found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final course = semesterCourses.firstWhere(
      (c) => c.courseId == courseId,
      orElse: () => StudentCourse(
        courseId: courseId,
        name: 'Unknown Course',
        finalGrade: '',
        lectureTime: '',
        tutorialTime: '',
        labTime: '',
        workshopTime: '',
      ),
    );

    // Get course details for schedule selection
    final courseDataProvider = context.read<CourseDataProvider>();
    final courseDetails = await courseDataProvider.getCourseDetails(courseId);

    // Use shared mixin to show schedule selection dialog
    if (mounted) {
      showScheduleSelectionDialog(
        context,
        course,
        courseDetails,
        semester: semester,
        onSelectionUpdated: () {
          // Refresh calendar events to show updated selection
          final colorThemeProvider = context.read<ColorThemeProvider>();
          _updateCalendarEvents(courseProvider, colorThemeProvider);
        },      );
    }
  }

  // NEW: Persistent storage methods for removed courses
  Future<void> _loadRemovedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removedCoursesString = prefs.getString('removed_courses') ?? '';
      
      if (removedCoursesString.isNotEmpty) {
        final removedCoursesList = removedCoursesString.split(',');
        _removedCourses.clear();
        _removedCourses.addAll(removedCoursesList);
        debugPrint('Loaded ${_removedCourses.length} removed courses from storage');
      }
    } catch (e) {
      debugPrint('Error loading removed courses: $e');
    }
  }

  Future<void> _saveRemovedCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removedCoursesString = _removedCourses.join(',');
      await prefs.setString('removed_courses', removedCoursesString);
      debugPrint('Saved ${_removedCourses.length} removed courses to storage');
    } catch (e) {
      debugPrint('Error saving removed courses: $e');
    }
  }

  // NEW: Method to restore course to calendar
  void _restoreCourseToCalendar(String courseId) {
    _removedCourses.remove(courseId);
    _saveRemovedCourses(); // Persist the change
    debugPrint('Course $courseId restored to calendar');
    // Trigger calendar refresh
    setState(() {});
  }
}
