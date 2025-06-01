import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../pages/student_courses_page.dart';
import '../pages/degree_progress_page.dart';
import '../widgets/profile/profile_info_row.dart';
import '../widgets/profile/stat_card.dart';
import '../widgets/course_calendar_panel.dart';
import '../models/student_model.dart';
import '../mixins/calendar_theme_mixin.dart';
import '../mixins/course_event_mixin.dart';
import '../services/course_service.dart';

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> 
    with CalendarDarkThemeMixin, CourseEventMixin {
  String _currentPage = 'Calendar';
  int _viewMode = 0; // 0: Week View, 1: Day View
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitializedData = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitializedData) {
        _hasInitializedData = true;
        _loadStudentDataIfNeeded();
      }
    });
  }

  void _loadStudentDataIfNeeded() {
    final loginNotifier = context.read<LogInNotifier>();
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    // Only proceed if user is logged in
    if (loginNotifier.user == null) return;

    // Load student data if not already loaded or loading
    if (!studentProvider.hasStudent && !studentProvider.isLoading) {
      studentProvider.fetchStudent(loginNotifier.user!.uid).then((success) {
        if (success && mounted) {
          // Only load courses if not already loaded or loading
          if (!courseProvider.hasLoadedData && !courseProvider.loadingState.isLoadingCourses) {
            courseProvider.loadStudentCourses(studentProvider.student!.id);
          }
        }
      });
    }
    // Handle case where student is loaded but courses aren't
    else if (studentProvider.hasStudent && 
             !courseProvider.hasLoadedData && 
             !courseProvider.loadingState.isLoadingCourses) {
      courseProvider.loadStudentCourses(studentProvider.student!.id);
    }
  }

  EventController get _eventController =>
      CalendarControllerProvider.of(context).controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LogInNotifier, StudentProvider, CourseProvider>(
      builder: (context, loginNotifier, studentProvider, courseProvider, _) {
        // Update calendar events when courses change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (studentProvider.hasStudent && courseProvider.hasLoadedData) {
            _updateCalendarEvents(courseProvider);
          }
        });

        Widget body;

        switch (_currentPage) {
          case 'Calendar':
            body = _buildCalendarView(courseProvider);
            break;
          case 'Profile':
            body = _buildProfileView(studentProvider, courseProvider);
            break;
          case 'My Courses':
            body = const StudentCoursesPage();
            break;
          case 'Degree Progress':
            body = const DegreeProgressPage();
            break;
          case 'GPA Calculator':
            body = _buildGpaCalculatorView();
            break;
          default:
            body = _buildCalendarView(courseProvider);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('DegreEZ - $_currentPage'),
            centerTitle: true,
            actions: [
              Consumer<CourseDataProvider>(
                builder: (context, courseDataProvider, child) {
                  if (courseDataProvider.currentSemester != null) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Center(
                        child: Text(
                          courseDataProvider.currentSemester!.semesterName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              IconButton(
                icon: const Icon(Icons.bolt_sharp),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Assistant coming soon!')),
                  );
                },
              ),
            ],
          ),
          drawer: _buildSideDrawer(context, loginNotifier, studentProvider),
          body: studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your data...'),
                    ],
                  ),
                )
              : body,
          // Simplified FAB - removed the configure button
          floatingActionButton: _currentPage == 'Calendar'
              ? FloatingActionButton(
                  onPressed: _showCourseSearchAndSelect,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSideDrawer(
    BuildContext context,
    LogInNotifier loginNotifier,
    StudentProvider studentProvider,
  ) {
    final user = loginNotifier.user;
    final student = studentProvider.student;

    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced User Header
            UserAccountsDrawerHeader(
              accountName: Text(student?.name ?? user?.displayName ?? 'User'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(user?.displayName?.substring(0, 1) ?? 'U')
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              otherAccountsPictures: student != null ? [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${student.major}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'S${student.semester}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                )
              ] : null,
            ),
            
            // Navigation Items
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: 'Calendar',
              isSelected: _currentPage == 'Calendar',
              onTap: () => _changePage('Calendar'),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              isSelected: _currentPage == 'Profile',
              onTap: () => _changePage('Profile'),
            ),
            _buildDrawerItem(
              icon: Icons.school,
              title: 'My Courses',
              isSelected: _currentPage == 'My Courses',
              onTap: () => _changePage('My Courses'),
            ),
            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'Degree Progress',
              isSelected: _currentPage == 'Degree Progress',
              onTap: () => _changePage('Degree Progress'),
            ),
            _buildDrawerItem(
              icon: Icons.calculate,
              title: 'GPA Calculator',
              isSelected: _currentPage == 'GPA Calculator',
              onTap: () => _changePage('GPA Calculator'),
            ),
            
            const Divider(),
            
            // Sign out
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              onTap: () {
                // Clear providers before signing out
                context.read<StudentProvider>().clear();
                context.read<CourseProvider>().clear();
                loginNotifier.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _changePage(String page) {
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildCalendarView(CourseProvider courseProvider) {
    return Column(
      children: [
        // Search Bar - only visible in Week View
        if (_viewMode == 0)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        
        // Course List Panel
        if (courseProvider.hasAnyCourses)
          CourseCalendarPanel(eventController: _eventController),

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
                      Expanded(
                        child: Text(
                          'F',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
      startHour: 7,
      endHour: 24,
      showLiveTimeLineInAllDays: true,
      minDay: DateTime(2020),
      maxDay: DateTime(2030),
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
      startHour: 7,
      endHour: 24,
      showLiveTimeLineInAllDays: true,
      minDay: DateTime(2020),
      maxDay: DateTime(2030),
      initialDay: DateTime.now(),
      heightPerMinute: 1,
    );
  }

  Widget _buildProfileView(StudentProvider studentProvider, CourseProvider courseProvider) {
    final student = studentProvider.student;
    
    if (student == null) {
      return const Center(
        child: Text('No student data available'),
      );
    }

    final totalCourses = courseProvider.coursesBySemester.values
        .fold<int>(0, (sum, courses) => sum + courses.length);
        
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProfileInfoRow(label: 'Name', value: student.name),
                  ProfileInfoRow(label: 'Major', value: student.major),
                  ProfileInfoRow(label: 'Faculty', value: student.faculty),
                  ProfileInfoRow(label: 'Semester', value: student.semester.toString()),
                  ProfileInfoRow(label: 'Catalog', value: student.catalog),
                  if (student.preferences.isNotEmpty)
                    ProfileInfoRow(label: 'Interests', value: student.preferences),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics
          Text(
            'Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Courses',
                  value: totalCourses.toString(),
                  icon: Icons.school,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Semesters',
                  value: courseProvider.coursesBySemester.length.toString(),
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(context, student),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaCalculatorView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'GPA Calculator',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Updated calendar event creation to only show selected schedules
  void _updateCalendarEvents(CourseProvider courseProvider) {
    debugPrint('=== Updating calendar events with schedule selection ===');
    // Clear existing events
    _eventController.removeWhere((event) => true);
    
    // Get current week start (Monday)
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    debugPrint('Current week start (Monday): $currentWeekStart');
    
    final semesterCount = courseProvider.coursesBySemester.length;
    debugPrint('Found $semesterCount semesters with courses');
    
    for (final semesterEntry in courseProvider.coursesBySemester.entries) {
      final semester = semesterEntry.key;
      final courses = semesterEntry.value;
      debugPrint('Processing semester "$semester" with ${courses.length} courses');
      
      for (final course in courses) {
        debugPrint('Processing course: ${course.name} (${course.courseId})');
        debugPrint('Has selected lecture: ${course.hasSelectedLecture}, Has selected tutorial: ${course.hasSelectedTutorial}');
        
        // Get course details to access schedule
        context.read<CourseDataProvider>().getCourseDetails(course.courseId).then((courseDetails) {
          if (courseDetails?.schedule.isNotEmpty == true) {
            debugPrint('Using API schedule for ${course.name} with selection filtering');
            _createCalendarEventsFromSchedule(course, courseDetails!, semester, currentWeekStart);
          } else {
            debugPrint('Using basic schedule for ${course.name} (lecture: "${course.lectureTime}", tutorial: "${course.tutorialTime}")');
            // Create basic events from stored lecture/tutorial times if no API schedule
            _createBasicCalendarEvents(course, semester, currentWeekStart);
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
      final isSelected = (eventType == CourseEventType.lecture && selectedLecture != null) ||
                        (eventType == CourseEventType.tutorial && selectedTutorial != null);
      
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
        title: _formatSelectedEventTitle(course.name, eventType, schedule, isSelected),
        description: _buildEventDescription(course, schedule, semester),
        startTime: timeRange['start']!,
        endTime: timeRange['end']!,
        color: _getCourseColor(course.courseId),
      );
      
      debugPrint('Created calendar event: ${event.title} on ${event.date} from ${event.startTime} to ${event.endTime}');
      _eventController.add(event);
    }
  }

  void _createBasicCalendarEvents(
    StudentCourse course, 
    String semester,
    DateTime weekStart,
  ) {
    final courseColor = _getCourseColor(course.courseId);
    
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
    
    // Convert DateTime weekday to correct offset from Monday
    final dayOffset = getWeekdayOffset(dayOfWeek);
    
    final eventDate = weekStart.add(Duration(days: dayOffset));
    final timeRange = parseTimeRange(timePart, eventDate);
    
    if (timeRange == null) return null;
    
    return CalendarEventData(
      date: eventDate,
      title: '$eventType\n${course.name}',
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

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.teal.shade900, // Dark greenish blue
      Colors.indigo.shade900, // Deep bluish purple
      Colors.cyan.shade900, // Rich green-blue — bright pop
      Colors.deepPurple.shade900, // Bold, regal purple
      Colors.blue.shade900, // Classic dark blue
      Colors.orange.shade900, // Dark, warm orange — still different from brown
      Colors.red.shade900, // Blood red — intense but clearly distinct
      Colors.lime.shade900, // Sharp and vivid green-yellow
    ];
    return colors[hash.abs() % colors.length];
  }

  // New helper method for formatting event titles with selection indication
  String _formatSelectedEventTitle(String courseName, CourseEventType type, ScheduleEntry schedule, bool isSelected) {
    final typeStr = type.name.toUpperCase();
    final groupStr = schedule.group > 0 ? ' G${schedule.group}' : '';
    final selectedIndicator = isSelected ? ' ✓' : '';
    
    return '$typeStr$groupStr$selectedIndicator\n$courseName';
  }

  // Placeholder methods
  void _showEditProfileDialog(BuildContext context, StudentModel student) {
    // Keep your existing implementation
  }

  void _showCourseSearchAndSelect() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: _CourseSearchWidget(
            onCourseSelected: (course) {
              Navigator.pop(context);
              _showAddCourseFromSearchDialog(context, course);
            },
          ),
        ),
      ),
    );
  }

  void _showAddCourseFromSearchDialog(BuildContext context, EnhancedCourseDetails courseDetails) {
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${courseDetails.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Course ID: ${courseDetails.courseNumber}'),
            Text('Credits: ${courseDetails.creditPoints}'),
            Text('Faculty: ${courseDetails.faculty}'),
            const SizedBox(height: 16),
            TextField(
              controller: semesterController,
              decoration: const InputDecoration(
                labelText: 'Semester',
                hintText: 'e.g., Winter 2024',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (semesterController.text.isNotEmpty) {
                _addCourseFromSearch(context, semesterController.text, courseDetails);
                Navigator.pop(context);
              }
            },
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourseFromSearch(
    BuildContext context,
    String semester,
    EnhancedCourseDetails courseDetails,
  ) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (!studentProvider.hasStudent) return;

    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
    );

    final success = await courseProvider.addCourseToSemester(
      studentProvider.student!.id,
      semester,
      course,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully')),
      );
    }
  }
}

class _CourseSearchWidget extends StatefulWidget {
  final Function(EnhancedCourseDetails) onCourseSelected;

  const _CourseSearchWidget({
    required this.onCourseSelected,
  });

  @override
  State<_CourseSearchWidget> createState() => _CourseSearchWidgetState();
}

class _CourseSearchWidgetState extends State<_CourseSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseDataProvider>(
      builder: (context, courseDataProvider, _) {
        return Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses by name or ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                            });
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _performSearch(courseDataProvider, value);
                  } else {
                    setState(() {
                      _searchResults.clear();
                    });
                  }
                },
              ),
            ),

            // Search results
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text('Search for courses to see results'),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(result.course.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${result.course.courseNumber}'),
                                Text('Faculty: ${result.course.faculty}'),
                                Text('Points: ${result.course.points}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                widget.onCourseSelected(result.course);
                              },
                              child: const Text('Select'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(CourseDataProvider courseDataProvider, String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      if (courseDataProvider.currentSemester == null) {
        await courseDataProvider.fetchCurrentSemester();
      }

      if (courseDataProvider.currentSemester != null) {
        final results = await CourseService.searchCourses(
          year: courseDataProvider.currentSemester!.year,
          semester: courseDataProvider.currentSemester!.semester,
          courseName: query.contains(RegExp(r'[a-zA-Z]')) ? query : null,
          courseId: query.contains(RegExp(r'[0-9]')) ? query : null,
        );

        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
}
