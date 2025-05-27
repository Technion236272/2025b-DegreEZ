// lib/pages/calendar_home_page.dart
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_notifier.dart';
import '../pages/student_courses_page.dart';
import '../pages/degree_progress_page.dart';
import '../mixins/calendar_theme_mixin.dart';
import '../services/course_service.dart';
import '../widgets/profile/profile_info_row.dart';
import '../widgets/profile/stat_card.dart';

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage>
    with CalendarDarkThemeMixin {
  String _currentPage = 'Calendar';
  int _viewMode = 0; // 0: Week View, 1: Day View
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load student data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentDataIfNeeded();
    });
  }

  void _loadStudentDataIfNeeded() {
    final loginNotifier = Provider.of<LogInNotifier>(context, listen: false);
    final studentNotifier = Provider.of<StudentNotifier>(
      context,
      listen: false,
    );

    if (loginNotifier.user != null &&
        studentNotifier.student == null &&
        !studentNotifier.isLoading) {
      studentNotifier.fetchStudentData(loginNotifier.user!.uid);
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
    final loginNotifier = Provider.of<LogInNotifier>(context);
    final studentNotifier = Provider.of<StudentNotifier>(context);

    // Update calendar events when courses change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final events = _getEventsFromCourses(studentNotifier);
      _eventController.removeWhere((event) => true); // Clear existing
      _eventController.addAll(events); // Add new events
    });

    Widget body;

    switch (_currentPage) {
      case 'Calendar':
        body = _buildCalendarView();
        break;
      case 'Profile':
        body = _buildProfileView(studentNotifier);
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
        body = _buildCalendarView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('DegreEZ - $_currentPage'),
        centerTitle: true,
        actions: [
          if (studentNotifier.currentSemester != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  studentNotifier.currentSemester!.semesterName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
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

      drawer: _buildSideDrawer(
        context,
        loginNotifier,
        studentNotifier,
        _currentPage,
      ),
      body:
          studentNotifier.isLoading
              ? const Center(child: CircularProgressIndicator())
              : body,
      floatingActionButton:
          _currentPage == 'Calendar'
              ? FloatingActionButton(
                onPressed: () => _showAddCourseToCalendar(),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  // Move all the following methods inside the _CalendarHomePageState class

  Widget _buildSideDrawer(
    BuildContext context,
    LogInNotifier loginNotifier,
    StudentNotifier studentNotifier,
    String currentPage,
  ) {
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        loginNotifier.user?.photoURL != null
                            ? NetworkImage(loginNotifier.user!.photoURL!)
                            : null,
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    child:
                        loginNotifier.user?.photoURL == null
                            ? Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    studentNotifier.student?.name ??
                        loginNotifier.user?.displayName ??
                        'Welcome!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (studentNotifier.student != null)
                    Text(
                      '${studentNotifier.student!.major} - ${studentNotifier.student!.faculty}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            _buildDrawerItem('Calendar', Icons.calendar_today, currentPage),
            _buildDrawerItem('My Courses', Icons.school, currentPage),
            _buildDrawerItem('Degree Progress', Icons.timeline, currentPage),
            _buildDrawerItem('Profile', Icons.person, currentPage),
            _buildDrawerItem('GPA Calculator', Icons.calculate, currentPage),
            const Divider(),
            _buildDrawerItem(
              'Log Out',
              Icons.logout,
              currentPage,
              onTap: () async {
                studentNotifier.clear();
                await loginNotifier.signOut();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    String title,
    IconData icon,
    String currentPage, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            currentPage == title
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              currentPage == title
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurface,
          fontWeight:
              currentPage == title ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: currentPage == title,
      onTap:
          onTap ??
          () {
            setState(() {
              _currentPage = title;
            });
            Navigator.pop(context);
          },
    );
  }

  Widget _buildCalendarView() {
    return Consumer<StudentNotifier>(
      builder: (context, studentNotifier, _) {
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
                    suffixIcon:
                        _searchQuery.isNotEmpty
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
                              color:
                                  _viewMode == 0
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
                            color:
                                _viewMode == 0
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
                              color:
                                  _viewMode == 1
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
                            color:
                                _viewMode == 1
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
              child:
                  _viewMode == 0
                      ? WeekView(
                        backgroundColor: getCalendarBackgroundColor(context),
                        headerStyle: getHeaderStyle(context),
                        weekDayBuilder: (date) => buildWeekDay(context, date),
                        timeLineBuilder: (date) => buildTimeLine(context, date),
                        liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(
                          context,
                        ),
                        hourIndicatorSettings: getHourIndicatorSettings(
                          context,
                        ),
                        eventTileBuilder:
                            (
                              date,
                              events,
                              boundary,
                              startDuration,
                              endDuration,
                            ) => buildEventTile(
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
                      )
                      : DayView(
                        backgroundColor: getCalendarBackgroundColor(context),
                        dayTitleBuilder:
                            (date) => buildDayHeader(context, date),
                        timeLineBuilder: (date) => buildTimeLine(context, date),
                        liveTimeIndicatorSettings: getLiveTimeIndicatorSettings(
                          context,
                        ),
                        hourIndicatorSettings: getHourIndicatorSettings(
                          context,
                        ),
                        eventTileBuilder:
                            (
                              date,
                              events,
                              boundary,
                              startDuration,
                              endDuration,
                            ) => buildEventTile(
                              context,
                              date,
                              events,
                              boundary,
                              startDuration,
                              endDuration,
                            ),
                        startHour: 7,
                        endHour: 24,
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileView(StudentNotifier studentNotifier) {
    final student = studentNotifier.student;
    if (student == null) {
      return const Center(child: Text('No student profile found'));
    }

    final totalCredits = studentNotifier.coursesBySemester.keys
        .map((semester) => studentNotifier.getTotalCreditsForSemester(semester))
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
                value: studentNotifier.coursesBySemester.length.toString(),
              ),
              StatCard(
                icon: Icons.school,
                label: 'Courses',
                value:
                    studentNotifier.coursesBySemester.values
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

  void _showEditProfileDialog(BuildContext context, StudentNotifier notifier) {
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
                final parsedSemester =
                    int.tryParse(semesterController.text) ?? student.semester;

                notifier.updateStudentProfile(
                  name: nameController.text,
                  major: majorController.text,
                  preferences: preferencesController.text,
                  faculty: facultyController.text,
                  catalog: catalogController.text,
                  semester: parsedSemester,
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

  /*  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
*/
  Widget _buildGpaCalculatorView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('GPA Calculator', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showAddCourseToCalendar() {
    Navigator.pushNamed(context, '/courses');
  }

  List<CalendarEventData> _getEventsFromCourses(
    StudentNotifier studentNotifier,
  ) {
    final events = <CalendarEventData>[];

    for (final semesterEntry in studentNotifier.coursesBySemester.entries) {
      final courses = semesterEntry.value;

      for (final course in courses) {
        final courseWithDetails = studentNotifier.getCourseWithDetails(
          semesterEntry.key,
          course.courseId,
        );

        if (courseWithDetails?.courseDetails != null) {
          final courseDetails = courseWithDetails!.courseDetails!;

          for (final schedule in courseDetails.schedule) {
            final event = _createCalendarEventFromSchedule(
              course,
              courseDetails,
              schedule,
            );
            if (event != null) events.add(event);
          }
        }
      }
    }

    return events;
  }

  CalendarEventData? _createCalendarEventFromSchedule(
    StudentCourse course,
    EnhancedCourseDetails details,
    ScheduleEntry schedule,
  ) {
    // Map Hebrew day names to weekday numbers
    final dayMap = {
      'א': 7, // Sunday
      'ב': 1, // Monday
      'ג': 2, // Tuesday
      'ד': 3, // Wednesday
      'ה': 4, // Thursday
      'ו': 5, // Friday
      'ש': 6, // Saturday
    };

    final dayNum = dayMap[schedule.day];
    if (dayNum == null) return null;

    // Parse time (format: "14:30 - 16:30")
    final timeParts = schedule.time.split(' - ');
    if (timeParts.length != 2) return null;

    final startTime = _parseTime(timeParts[0]);
    final endTime = _parseTime(timeParts[1]);
    if (startTime == null || endTime == null) return null;

    // Create event for next occurrence of this day
    final now = DateTime.now();
    final daysUntilTarget = (dayNum - now.weekday) % 7;
    final targetDate = now.add(Duration(days: daysUntilTarget));

    return CalendarEventData(
      date: targetDate,
      title: details.name,
      description:
          '${course.courseId} - ${schedule.fullLocation}\n${schedule.type} with ${schedule.staff}',
      startTime: DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        startTime.hour,
        startTime.minute,
      ),
      endTime: DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        endTime.hour,
        endTime.minute,
      ),
      color: _getCourseColor(course.courseId),
    );
  }

  DateTime? _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.red.shade700,
      Colors.indigo.shade700,
      Colors.cyan.shade700,
    ];
    return colors[hash.abs() % colors.length];
  }
}

// Course Calendar Panel Widget
class CourseCalendarPanel extends StatefulWidget {
  final EventController eventController;

  const CourseCalendarPanel({Key? key, required this.eventController})
    : super(key: key);

  @override
  State<CourseCalendarPanel> createState() => _CourseCalendarPanelState();
}

class _CourseCalendarPanelState extends State<CourseCalendarPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentNotifier>(
      builder: (context, studentNotifier, _) {
        final allCourses =
            studentNotifier.coursesBySemester.values
                .expand((courses) => courses)
                .toList();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Courses (${allCourses.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState:
                    _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  children: [
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allCourses.length,
                      itemBuilder: (context, index) {
                        final course = allCourses[index];
                        final semesterKey = studentNotifier
                            .coursesBySemester
                            .keys
                            .firstWhere(
                              (key) => studentNotifier.coursesBySemester[key]!
                                  .contains(course),
                            );
                        final courseDetails =
                            studentNotifier
                                .getCourseWithDetails(
                                  semesterKey,
                                  course.courseId,
                                )
                                ?.courseDetails;

                        return ListTile(
                          leading: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getCourseColor(course.courseId),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            course.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            course.courseId,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          trailing:
                              courseDetails != null &&
                                      courseDetails.points.isNotEmpty
                                  ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${courseDetails.points} credits',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  )
                                  : null,
                          dense: true,
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

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.red.shade700,
    ];
    return colors[hash.abs() % colors.length];
  }
}
