import 'package:calendar_view/calendar_view.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/color_theme_provider.dart';
import '../widgets/course_calendar_panel.dart';
import '../widgets/exam_calendar_panel.dart';
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
  
  // Flag to track if we need to trigger the initial view switch to load events
  bool _hasTriggeredInitialLoad = false;



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

  // Build the course panel with integrated toggle button
  Widget _buildCoursePanelWithIntegratedToggle(CourseProvider courseProvider) {
    if (!courseProvider.hasAnyCourses) {
      return const SizedBox.shrink();
    }

    return CourseCalendarPanel(
      eventController: _eventController,
      onCourseManuallyAdded: _markCourseAsManuallyAdded,
      onCourseManuallyRemoved: _removeCourseFromManualTracking,
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
          }
        });return Column(
          children: [
            // Course Panel with integrated Toggle Button
            _buildCoursePanelWithIntegratedToggle(courseProvider),

            // NEW: Simple Exam Dates Panel
            const ExamDatesPanel(),

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
        Padding(padding: EdgeInsets.all(3), child: Transform.rotate(
            angle: -0.5, // 90 degrees in radians
            child: Column(
          children: [
            Text(
          // put it diagonal not horizontal
            DateFormat('yyyy').format(date),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
            Text(
          // put it diagonal not horizontal
            DateFormat('MMM').format(date),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,color: AppColorsDarkMode.secondaryColorDim),
            textAlign: TextAlign.center,
            

          ),
          
          ],
        ),),),
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
        hourIndicatorSettings: getHourIndicatorSettings(context),        eventTileBuilder: (date, events, boundary, startDuration, endDuration) =>
            buildEventTile(
          context,
          date,
          events,
          boundary,
          startDuration,
          endDuration,
          filtered: true,
          searchQuery: _searchQuery,
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
        endDuration,
        onLongPress: _showCourseDetailsDialog,
      ),
      startHour: 8,
      endHour: 22,
      showLiveTimeLineInAllDays: true,
      // only show events for the current week
      // Adjust min and max days to show the current day
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
  }
  int _createBasicCalendarEvents(
    StudentCourse course, 
    String semester,
    DateTime weekStart,
    ColorThemeProvider colorThemeProvider,
  ) {
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
}
