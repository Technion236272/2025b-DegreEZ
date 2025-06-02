// lib/pages/home_page.dart - Updated to use AddCoursePage
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../pages/student_courses_page.dart';
import '../pages/degree_progress_page.dart';
import '../pages/add_course_page.dart'; // Added new import
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
  final _searchQuery = '';

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
      studentProvider.fetchStudentData(loginNotifier.user!.uid).then((success) {
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
            title: Text(_currentPage),
            centerTitle: true,
            actions: [
              Consumer<CourseDataProvider>(
                builder: (context, courseDataProvider, child) {
                  if (courseDataProvider.currentSemester != null) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Center(
                        child: Text(
                          // the current semester's name
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
          // Updated FAB - now navigates to AddCoursePage
          floatingActionButton: _currentPage == 'Calendar'
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCoursePage(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                  tooltip: 'Add Course',
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
            _buildDrawerItem(
              isSelected: _currentPage == 'Log Out',
              icon: Icons.logout,
              title: 'Log Out',
              onTap: () async {
                studentProvider.clear();
                context.read<CourseProvider>().clear();
                await loginNotifier.signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
            
            // // Add Course - New menu item for easier access
            // ListTile(
            //   leading: const Icon(Icons.add_circle_outline),
            //   title: const Text('Add Course'),
            //   onTap: () {
            //     Navigator.pop(context); // Close drawer
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const AddCoursePage(),
            //       ),
            //     );
            //   },
            // ),
            
            // const Divider(),
            
            // Sign out
            // ListTile(
            //   leading: const Icon(Icons.logout, color: Colors.red),
            //   title: const Text('Sign Out'),
            //   onTap: () {
            //     // Clear providers before signing out
            //     context.read<StudentProvider>().clear();
            //     context.read<CourseProvider>().clear();
            //     loginNotifier.signOut();
            //     Navigator.pop(context);
            //   },
            // ),
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

  Widget _buildProfileView(StudentProvider studentNotifier,CourseProvider courseNotifier) {
    final student = studentNotifier.student;
    if (student == null) {
      return const Center(child: Text('No student profile found'));
    }

    final totalCredits = courseNotifier.coursesBySemester.keys
        .map((semester) => courseNotifier.getTotalCreditsForSemester(semester))
        .fold<double>(0.0, (sum, credits) => sum + credits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed:
                            () => _showEditProfileDialog(
                              context,
                              studentNotifier,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ProfileInfoRow(label: 'Name', value: student.name),
                  ProfileInfoRow(label: 'Major', value: student.major),
                  ProfileInfoRow(label: 'Faculty', value: student.faculty),
                  ProfileInfoRow(
                    label: 'Current Semester',
                    value: student.semester.toString(),
                  ),
                  ProfileInfoRow(label: 'Catalog', value: student.catalog),
                  if (student.preferences.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Preferences',
                      value: student.preferences,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Course Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatCard(
                icon: Icons.calendar_today,
                label: 'Semesters',
                value: courseNotifier.coursesBySemester.length.toString(),
              ),
              StatCard(
                icon: Icons.school,
                label: 'Courses',
                value:
                    courseNotifier.coursesBySemester.values
                        .expand((courses) => courses)
                        .length
                        .toString(),
              ),
              StatCard(
                icon: Icons.star,
                label: 'Credits',
                value: totalCredits.toStringAsFixed(1),
              ),
            ],
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
        title: formatEventTitle(course.name, eventType, schedule.group > 0 ? schedule.group : null),
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

  // Placeholder method for edit profile
    void _showEditProfileDialog(BuildContext context, StudentProvider notifier) {
    final student = notifier.student!;
    final nameController = TextEditingController(text: student.name);
    final majorController = TextEditingController(text: student.major);
    final preferencesController = TextEditingController(
      text: student.preferences,
    );
    final catalogController = TextEditingController(text: student.catalog);
    final facultyController = TextEditingController(text: student.faculty);
    final semesterController = TextEditingController(
      text: student.semester.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: majorController,
                decoration: const InputDecoration(labelText: 'Major'),
              ),
              TextField(
                controller: facultyController,
                decoration: const InputDecoration(labelText: 'Faculty'),
              ),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: catalogController,
                decoration: const InputDecoration(labelText: 'Catalog'),
              ),
              TextField(
                controller: preferencesController,
                decoration: const InputDecoration(labelText: 'Preferences'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {


                notifier.updateStudentProfile(
                  name: nameController.text,
                  major: majorController.text,
                  preferences: preferencesController.text,
                  faculty: facultyController.text,
                  catalog: catalogController.text,
                  semester: student.semester,
                );
                Navigator.of(context).pop();
              },

              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
