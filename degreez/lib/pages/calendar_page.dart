import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/course_calendar_panel.dart';
import '../models/student_model.dart';
import '../mixins/calendar_theme_mixin.dart';
import '../mixins/course_event_mixin.dart';
import '../mixins/schedule_selection_mixin.dart';
import '../services/course_service.dart';

class CalendarPage extends StatefulWidget {
  final String? selectedSemester; // Receive selected semester from NavigatorPage
  final void Function(String selectedSemester)? onSemesterChanged; // Keep for compatibility
  const CalendarPage({super.key, this.selectedSemester, this.onSemesterChanged});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with CalendarDarkThemeMixin, CourseEventMixin, ScheduleSelectionMixin {
  int _viewMode = 0; // 0: Week View, 1: Day View
  final TextEditingController _searchController = TextEditingController();
  final _searchQuery = '';
  
  // Remove semester management - now handled by NavigatorPage
  // List<String> _allSemesters = [];
  // String? _selectedSemester;

  // NEW: Track courses that should be hidden from calendar
  final Set<String> _removedCourses = <String>{};
  // Flag to track if we need to trigger the initial view switch to load events
  bool _hasTriggeredInitialLoad = false;

  @override
  void initState() {
    super.initState();
    // Remove semester initialization - now handled by NavigatorPage
    // _initializeSemesters();
    _loadRemovedCourses();
  }
  // Remove _initializeSemesters method - now handled by NavigatorPage

  (int, int)? _parseSemesterCode(String semesterName) {
    final match = RegExp(
      r'^(Winter|Spring|Summer) (\d{4})(?:-(\d{4}))?$',
    ).firstMatch(semesterName);
    if (match == null) return null;

    final season = match.group(1)!;
    final firstYear = int.parse(match.group(2)!);

    int apiYear;
    int semesterCode;

    switch (season) {
      case 'Winter':
        apiYear = firstYear; // Use the first year for Winter
        semesterCode = 200;
        break;
      case 'Spring':
        apiYear = firstYear - 1;
        semesterCode = 201;
        break;
      case 'Summer':
        apiYear = firstYear - 1;
        semesterCode = 202;
        break;
      default:
        return null;
    }

    return (apiYear, semesterCode);
  }

  EventController? get _eventController {
    if (!mounted) return null;
    return CalendarControllerProvider.of(context).controller;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  } // NEW: Methods to manage removed courses from calendar display

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
    }    final eventController = _eventController;
    if (eventController == null) {
      return const SizedBox.shrink();
    }
    
    return CourseCalendarPanel(
      selectedSemester: widget.selectedSemester ?? '',
      eventController: eventController,
      onCourseRemovedFromCalendar: _markCourseAsRemovedFromCalendar,
      onCourseRestoredToCalendar: _restoreCourseToCalendar,
      isCourseRemovedFromCalendar: _isCourseRemovedFromCalendar,
      viewMode: _viewMode,
      onToggleView: () => setState(() => _viewMode = _viewMode == 0 ? 1 : 0),
    );
  }

  @override
  Widget build(BuildContext context) {    return Consumer4<
      LogInNotifier,
      StudentProvider,
      CourseProvider,
      ThemeProvider
    >(
      builder: (
        context,
        loginNotifier,
        studentProvider,
        courseProvider,
        themeProvider,
        _,
      ) {// Update calendar events when courses change
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (widget.selectedSemester == null) return;

          if (studentProvider.hasStudent && courseProvider.hasLoadedData) {
            await _updateCalendarEvents(
              courseProvider,
              themeProvider,
              forceSemester: widget.selectedSemester, // ⬅️ use selected semester
            );

            if (!_hasTriggeredInitialLoad) {
              _hasTriggeredInitialLoad = true;
              if (mounted) setState(() {});
            }
          }
        });return Column(
          children: [
            // Course Panel with integrated Toggle Button
            _buildCoursePanelWithIntegratedToggle(courseProvider),            // Calendar Views - Full Width
            Expanded(
              child: _viewMode == 0 ? _buildWeekView(themeProvider) : _buildDayView(themeProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekView(ThemeProvider themeProvider) {
    final eventController = _eventController;
    if (eventController == null) {
      return const Center(child: Text('Calendar not available'));
    }
    
    return ClipRect(
      child: WeekView(
        controller: eventController,
        backgroundColor: getCalendarBackgroundColor(context),
        weekPageHeaderBuilder: WeekHeader.hidden,
        // add the month and year to the header but smaller to fit here in weekNumberBuilder
        weekNumberBuilder:
            (date) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // shrink-wrap content
                children: [
                  Transform.rotate(
                    angle: -pi / 6, // about -30 degrees
                    child: Text(
                      DateFormat('yyyy').format(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Transform.rotate(
                    angle: -pi / 6, // same angle to match above
                    child: Text(
                      '       ${DateFormat('MMM').format(date)}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textSecondary,
                      ),
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
        eventTileBuilder:
            (date, events, boundary, startDuration, endDuration) =>
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
        minDay: DateTime.now().subtract(
          Duration(days: DateTime.now().weekday % 7),
        ),
        maxDay: DateTime.now().add(
          Duration(days: 7 - DateTime.now().weekday % 7),
        ),
        initialDay: DateTime.now(),
        heightPerMinute: 1,
        eventArranger: const SideEventArranger(),
      ),
    );
  }

  Widget _buildDayView(ThemeProvider themeProvider) {
    final eventController = _eventController;
    if (eventController == null) {
      return const Center(child: Text('Calendar not available'));
    }
    
    return DayView(
      controller: eventController,
      backgroundColor: getCalendarBackgroundColor(context),
      dayTitleBuilder: (date) => buildDayHeader(context, date),
      timeLineBuilder: (date) => buildTimeLine(context, date),
      liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(context),
      hourIndicatorSettings: getHourIndicatorSettings(context),
      eventTileBuilder:
          (date, events, boundary, startDuration, endDuration) =>
              buildEventTile(
                context,
                date,
                events,
                boundary,
                startDuration,
                endDuration,
                onTap: _onEventTap,
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
  Future<void> _updateCalendarEvents(
    CourseProvider courseProvider,
    ThemeProvider themeProvider, {
    String? forceSemester,  }) async {
    debugPrint('🔄 === STARTING CALENDAR UPDATE ===');
    debugPrint('🔄 Force semester: $forceSemester');
    
    final eventController = _eventController;
    if (eventController == null) {
      debugPrint('🔄 Event controller is null, skipping calendar update');
      return;
    }
    
    // Clear existing events
    final existingEventCount = eventController.allEvents.length;
    eventController.removeWhere((event) => true);
    debugPrint('🔄 Cleared $existingEventCount existing events');
    
    // Get current week start (Sunday)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    debugPrint('🔄 Current week start (Sunday): $currentWeekStart');

    final courseDataProvider = context.read<CourseDataProvider>();
    
    debugPrint('🔄 Found ${courseProvider.coursesBySemester.length} semesters with courses');
    
    // Collect all course detail requests to await them properly
    final List<Future<void>> courseDetailFutures = [];

    for (final semesterEntry in courseProvider.coursesBySemester.entries) {
      // process only the current semester
      final selectedSemester =
          forceSemester ?? courseDataProvider.currentSemester?.semesterName;
      if (selectedSemester != null && semesterEntry.key != selectedSemester) {
        continue;
      }      final semester = semesterEntry.key;
      final courses = semesterEntry.value;
      debugPrint('🔄 Processing semester "$semester" with ${courses.length} courses:');
      for (final course in courses) {
        debugPrint('  📚 Course: ${course.name} (${course.courseId})');
        debugPrint('    - Has selected lecture: ${course.hasSelectedLecture}');
        debugPrint('    - Has selected tutorial: ${course.hasSelectedTutorial}');
        debugPrint('    - Has selected lab: ${course.hasSelectedLab}');
        debugPrint('    - Has selected workshop: ${course.hasSelectedWorkshop}');
        debugPrint('    - Lecture time: "${course.lectureTime}"');
        debugPrint('    - Tutorial time: "${course.tutorialTime}"');
        debugPrint('    - Lab time: "${course.labTime}"');
        debugPrint('    - Workshop time: "${course.workshopTime}"');
        
        // NEW: Skip courses that are marked as removed from calendar
        if (_isCourseRemovedFromCalendar(course.courseId)) {
          debugPrint('    ❌ SKIPPING: Course marked as removed from calendar');
          continue;
        }        // Get course details to access schedule
        final parsed = _parseSemesterCode(semester);
        if (parsed == null) {
          debugPrint('    ❌ SKIPPING: Invalid semester format: $semester');
          continue;
        }
        final (year, semesterCode) = parsed;
        debugPrint('    🔍 Fetching course details for year=$year, code=$semesterCode');
        
        // Add the course detail future to our list
        courseDetailFutures.add(
          CourseService.getCourseDetails(year, semesterCode, course.courseId)
              .then((courseDetails) {
            debugPrint('    📥 Course details received for ${course.name}:');
            if (courseDetails?.schedule.isNotEmpty == true) {
              debugPrint('      ✅ Has API schedule with ${courseDetails!.schedule.length} entries');
              final eventsCreated = _createCalendarEventsFromSchedule(
                course,
                courseDetails,
                semester,
                currentWeekStart,
                themeProvider,
                eventController,
              );
              debugPrint('      📅 Created $eventsCreated events from API schedule');
            } else {
              debugPrint('      ⚠️ No API schedule, using basic times');
              final eventsCreated = _createBasicCalendarEvents(
                course,
                semester,
                currentWeekStart,
                themeProvider,
                eventController,
              );
              debugPrint('      📅 Created $eventsCreated events from basic times');
            }
          }).catchError((error) {
            debugPrint('    ❌ ERROR getting course details for ${course.courseId}: $error');
            // Fallback to basic events if API fails
            final eventsCreated = _createBasicCalendarEvents(
              course,
              semester,
              currentWeekStart,
              themeProvider,
              eventController,
            );
            debugPrint('    📅 Created $eventsCreated fallback events from basic times');
          }),
        );
      }
    }
    // Wait for all course details to be processed
    debugPrint('🔄 Waiting for ${courseDetailFutures.length} course detail requests...');
    await Future.wait(courseDetailFutures);
    
    final finalEventCount = eventController.allEvents.length;
    debugPrint('🔄 === CALENDAR UPDATE COMPLETE ===');
    debugPrint('🔄 Total events created: $finalEventCount');
    debugPrint('🔄 Event titles:');
    for (final event in eventController.allEvents) {
      debugPrint('  📅 ${event.title} (${event.startTime} - ${event.endTime})');
    }
    debugPrint('🔄 === END CALENDAR UPDATE ===');

    //    debugPrint('Total events added: $totalEventsAdded');
  }

  // Helper method to check for time conflicts with existing events
  bool _hasTimeConflict(DateTime startTime, DateTime endTime) {
    final eventController = _eventController;
    if (eventController == null) return false;
    
    final existingEvents = eventController.allEvents;

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
  List<CalendarEventData> _getConflictingEvents(
    DateTime startTime,
    DateTime endTime,
  ) {
    final conflictingEvents = <CalendarEventData>[];
    final eventController = _eventController;
    if (eventController == null) return conflictingEvents;
    
    final existingEvents = eventController.allEvents;

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
  int _createCalendarEventsFromSchedule(
    StudentCourse course,
    EnhancedCourseDetails courseDetails,
    String semester,
    DateTime weekStart,
    ThemeProvider themeProvider,
    EventController eventController,
  ) {
    debugPrint('  🏗️ Creating events from schedule for ${course.name}');
    
    // NEW: Skip courses that are marked as removed from calendar
    if (_isCourseRemovedFromCalendar(course.courseId)) {
      debugPrint('    ❌ Course is marked as removed from calendar');
      return 0;
    }

    debugPrint('    📋 Raw schedule has ${courseDetails.schedule.length} entries');
    
    int eventsAdded = 0;    // Get selected schedule entries only
    final selectedEntries = context
        .read<CourseProvider>()
        .getSelectedScheduleEntries(course.courseId, courseDetails, semester: semester);

    final selectedLectures = selectedEntries['lecture'] ?? <ScheduleEntry>[];
    final selectedTutorials = selectedEntries['tutorial'] ?? <ScheduleEntry>[];
    final selectedLabs = selectedEntries['lab'] ?? <ScheduleEntry>[];
    final selectedWorkshops = selectedEntries['workshop'] ?? <ScheduleEntry>[];

    debugPrint('    🎯 Selected entries:');
    debugPrint('      Lectures: ${selectedLectures.length}');
    debugPrint('      Tutorials: ${selectedTutorials.length}');
    debugPrint('      Labs: ${selectedLabs.length}');
    debugPrint('      Workshops: ${selectedWorkshops.length}');

    // Create events only for selected schedule entries
    final scheduleEntriesToShow = <ScheduleEntry>[];    // Add all selected lectures
    scheduleEntriesToShow.addAll(selectedLectures);
    if (selectedLectures.isNotEmpty) {
      debugPrint('      ✅ Adding ${selectedLectures.length} selected lectures');
    }

    // Add all selected tutorials
    scheduleEntriesToShow.addAll(selectedTutorials);
    if (selectedTutorials.isNotEmpty) {
      debugPrint('      ✅ Adding ${selectedTutorials.length} selected tutorials');
    }

    // Add all selected labs
    scheduleEntriesToShow.addAll(selectedLabs);
    if (selectedLabs.isNotEmpty) {
      debugPrint('      ✅ Adding ${selectedLabs.length} selected labs');
    }

    // Add all selected workshops
    scheduleEntriesToShow.addAll(selectedWorkshops);
    if (selectedWorkshops.isNotEmpty) {
      debugPrint('      ✅ Adding ${selectedWorkshops.length} selected workshops');
    }

    // If no selections made, show all (backward compatibility)
    if (scheduleEntriesToShow.isEmpty && !course.hasCompleteScheduleSelection) {
      scheduleEntriesToShow.addAll(courseDetails.schedule);
      debugPrint('      ⚠️ No selections made, showing all ${courseDetails.schedule.length} schedule entries');
    }

    debugPrint('    📝 Total entries to show: ${scheduleEntriesToShow.length}');

    // Deduplicate schedule entries by time and type to avoid multiple events for the same lecture
    final uniqueScheduleEntries = <ScheduleEntry>[];
    final seenTimeSlots = <String>{};    for (final schedule in scheduleEntriesToShow) {
      final timeSlotKey = '${schedule.day}_${schedule.time}_${schedule.type}_${schedule.group}';
      if (!seenTimeSlots.contains(timeSlotKey)) {
        uniqueScheduleEntries.add(schedule);
        seenTimeSlots.add(timeSlotKey);
        debugPrint('      ✅ Unique schedule: ${schedule.type} on ${schedule.day} at ${schedule.time} (Group ${schedule.group}) - Key: $timeSlotKey');
      } else {
        debugPrint('      ⚠️ Skipped duplicate: ${schedule.type} on ${schedule.day} at ${schedule.time} (Group ${schedule.group}) - Key: $timeSlotKey');
      }
    }

    debugPrint('    🔧 After deduplication: ${uniqueScheduleEntries.length} unique entries');    // Create calendar events from unique schedule entries
    for (final schedule in uniqueScheduleEntries) {
      debugPrint('    🏗️ Processing schedule entry:');
      debugPrint('      Day: "${schedule.day}", Time: "${schedule.time}", Type: "${schedule.type}", Group: ${schedule.group}');

      // Parse Hebrew day to weekday number
      final dayOfWeek = parseHebrewDay(schedule.day);
      debugPrint('      Parsed day "${schedule.day}" to weekday $dayOfWeek');

      // Convert DateTime weekday to correct offset from Monday
      final dayOffset = getWeekdayOffset(dayOfWeek);

      final eventDate = weekStart.add(Duration(days: dayOffset));
      debugPrint('      Event date: $eventDate (offset: $dayOffset from week start: $weekStart)');

      // Parse time range
      final timeRange = parseTimeRange(schedule.time, eventDate);
      if (timeRange == null) {
        debugPrint('      ❌ Failed to parse time range: ${schedule.time}');
        continue;
      }
      debugPrint('      Time range: ${timeRange['start']} - ${timeRange['end']}');
      
      // Get event type and create appropriate event
      final eventType = parseCourseEventType(schedule.type);
      debugPrint('      Event type: $eventType');
      
      // Check for time conflicts before adding the event
      final hasConflict = _hasTimeConflict(
        timeRange['start']!,
        timeRange['end']!,
      );
      if (hasConflict) {
        final conflictingEvents = _getConflictingEvents(
          timeRange['start']!,
          timeRange['end']!,
        );
        final conflictingTitles = conflictingEvents
            .map((e) => e.title)
            .join(', ');
        debugPrint('      ⚠️ Time conflict with: $conflictingTitles');
        debugPrint('      Allowing SideEventArranger to handle conflict display');
      }
      
      final event = CalendarEventData(
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
        color: themeProvider.getCourseColor(course.courseId),
      );
      
      debugPrint('      ✅ Created event: "${event.title}" on ${event.date} from ${event.startTime} to ${event.endTime}');
      eventController.add(event);
      eventsAdded++;
    }

    debugPrint('    🎯 Total events created for ${course.name}: $eventsAdded');
    return eventsAdded;
  }
  int _createBasicCalendarEvents(
    StudentCourse course,
    String semester,
    DateTime weekStart,
    ThemeProvider themeProvider,
    EventController eventController,
  ) {
    debugPrint('  🔧 Creating basic events for ${course.name}');
    
    // NEW: Skip courses that are marked as removed from calendar
    if (_isCourseRemovedFromCalendar(course.courseId)) {
      debugPrint('    ❌ Course is marked as removed from calendar');
      return 0;
    }

    final courseColor = themeProvider.getCourseColor(course.courseId);
    int eventsAdded = 0;

    // Create events from stored lecture time
    if (course.lectureTime.isNotEmpty) {
      debugPrint('    🎓 Processing lecture time: "${course.lectureTime}"');
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
        final hasConflict = _hasTimeConflict(
          lectureEvent.startTime!,
          lectureEvent.endTime!,
        );
        if (hasConflict) {
          debugPrint('    ⚠️ Time conflict for lecture - allowing SideEventArranger to handle');
        }
        eventController.add(lectureEvent);
        eventsAdded++;
        debugPrint('    ✅ Created lecture event: "${lectureEvent.title}"');
      } else {
        debugPrint('    ❌ Failed to create lecture event from: "${course.lectureTime}"');
      }
    }

    // Create events from stored tutorial time
    if (course.tutorialTime.isNotEmpty) {
      debugPrint('    📝 Processing tutorial time: "${course.tutorialTime}"');
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
        final hasConflict = _hasTimeConflict(
          tutorialEvent.startTime!,
          tutorialEvent.endTime!,
        );
        if (hasConflict) {
          debugPrint('    ⚠️ Time conflict for tutorial - allowing SideEventArranger to handle');
        }
        eventController.add(tutorialEvent);
        eventsAdded++;
        debugPrint('    ✅ Created tutorial event: "${tutorialEvent.title}"');
      } else {
        debugPrint('    ❌ Failed to create tutorial event from: "${course.tutorialTime}"');
      }
    }

    // Create events from stored lab time
    if (course.labTime.isNotEmpty) {
      debugPrint('    🧪 Processing lab time: "${course.labTime}"');
      final labEvent = _createEventFromTimeString(
        course,
        course.labTime,
        'Lab',
        semester,
        weekStart,
        courseColor,
      );
      if (labEvent != null) {
        final hasConflict = _hasTimeConflict(
          labEvent.startTime!,
          labEvent.endTime!,
        );
        if (hasConflict) {
          debugPrint('    ⚠️ Time conflict for lab - allowing SideEventArranger to handle');
        }
        eventController.add(labEvent);
        eventsAdded++;
        debugPrint('    ✅ Created lab event: "${labEvent.title}"');
      } else {
        debugPrint('    ❌ Failed to create lab event from: "${course.labTime}"');
      }
    }

    // Create events from stored workshop time
    if (course.workshopTime.isNotEmpty) {
      debugPrint('    🔨 Processing workshop time: "${course.workshopTime}"');
      final workshopEvent = _createEventFromTimeString(
        course,
        course.workshopTime,
        'Workshop',
        semester,
        weekStart,
        courseColor,
      );
      if (workshopEvent != null) {
        final hasConflict = _hasTimeConflict(
          workshopEvent.startTime!,
          workshopEvent.endTime!,
        );
        if (hasConflict) {
          debugPrint('    ⚠️ Time conflict for workshop - allowing SideEventArranger to handle');
        }
        eventController.add(workshopEvent);
        eventsAdded++;
        debugPrint('    ✅ Created workshop event: "${workshopEvent.title}"');
      } else {
        debugPrint('    ❌ Failed to create workshop event from: "${course.workshopTime}"');
      }
    }

    debugPrint('    🎯 Total basic events created for ${course.name}: $eventsAdded');
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
  String _buildEventDescription(
    StudentCourse course,
    dynamic schedule,
    String semester,
  ) {
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
    final themeProvider = context.read<ThemeProvider>();
    
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Course Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text('You long pressed on a calendar event!'),
                const SizedBox(height: 16),
                Container(                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode 
                          ? Colors.black.withAlpha(76)
                          : Colors.grey.withAlpha(51),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
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
                        Text(
                          'Time: ${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}',
                        ),
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
          return {'courseId': parts[0].trim(), 'semester': parts[1].trim()};
        }
      }
    }
    return null;
  }

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
    }    // Find the course in the semester with better error handling
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

    // Try to find the actual course instead of creating a dummy one
    StudentCourse? foundCourse;
    try {
      foundCourse = semesterCourses.firstWhere((c) => c.courseId == courseId);
    } catch (e) {
      // Course not found in the semester
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course "$courseId" not found in semester "$semester"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final course = foundCourse;    // Get course details for schedule selection with error handling
    final courseDataProvider = context.read<CourseDataProvider>();
    final parsed = _parseSemesterCode(semester);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid semester format: "$semester"'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final (year, semesterCode) = parsed;

    EnhancedCourseDetails? courseDetails;
    try {
      courseDetails = await courseDataProvider.getCourseDetails(
        year,
        semesterCode,
        courseId,
      );
    } catch (e) {
      debugPrint('Error fetching course details for event tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load course details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (courseDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Course details not available for "$courseId"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }// Use shared mixin to show schedule selection dialog
    if (mounted) {
      showScheduleSelectionDialog(
        context,
        course,
        courseDetails,
        semester: semester,        onSelectionUpdated: () async {
          // Match the course panel's callback behavior for consistency
          debugPrint('Schedule selection updated from event tap, refreshing...');
          
          // Small delay to ensure Firebase update consistency
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            // First update the local UI state
            setState(() {});
            
            // Then refresh the calendar events with proper error handling
            try {
              final themeProvider = context.read<ThemeProvider>();
              await refreshCalendarEvents(context, courseProvider, themeProvider);
              debugPrint('Calendar events refreshed successfully after event tap schedule selection');
            } catch (e) {
              debugPrint('Error refreshing calendar events from event tap: $e');
              // Still show success message to user even if refresh fails
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule updated, but calendar refresh failed. Please reload the page.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        },
      );
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
        debugPrint(
          'Loaded ${_removedCourses.length} removed courses from storage',
        );
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
  }  // Override the mixin's calendar refresh method to properly update calendar events
  @override
  Future<void> refreshCalendarEvents(
    BuildContext context,
    CourseProvider courseProvider,
    ThemeProvider themeProvider,
  ) async {
    debugPrint('Refreshing calendar events after schedule selection change');
    
    final eventController = _eventController;
    if (eventController == null) {
      debugPrint('Event controller is null, skipping calendar refresh');
      return;
    }
    
    // Clear existing events first to ensure clean refresh
    eventController.removeWhere((event) => true);
    
    // Force a complete calendar refresh with current semester
    await _updateCalendarEvents(
      courseProvider,
      themeProvider,
      forceSemester: widget.selectedSemester,
    );
    
    // Force UI update after the async operations complete
    if (mounted) {
      setState(() {
        // Force rebuild to show updated events
      });
    }
  }

  // Removed _loadGlobalSemesterCourses - semester management now handled by NavigatorPage
}
