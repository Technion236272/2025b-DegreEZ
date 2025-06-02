// providers/student_notifier.dart (Enhanced with CourseService integration)
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';
import 'package:calendar_view/calendar_view.dart';

class StudentNotifier with ChangeNotifier {
  // Student data
  StudentModel? _student;
  bool _isLoading = false;
  String _error = '';

  // Student's courses with details
  Map<String, List<StudentCourse>> _coursesBySemester = {};
  Map<String, EnhancedCourseDetails> _courseDetailsCache = {};

  // Current semester info (automatically fetched)
  SemesterInfo? _currentSemester;

  // Getters
  StudentModel? get student => _student;
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, List<StudentCourse>> get coursesBySemester => _coursesBySemester;
  SemesterInfo? get currentSemester => _currentSemester;

  // Initialize and fetch the latest semester
  Future<void> initialize() async {
    await _fetchLatestSemester();
  }

  // Fetch the latest available semester from the repository
  Future<void> _fetchLatestSemester() async {
    try {
      final semesters = await CourseService.getAvailableSemesters();
      if (semesters.isNotEmpty) {
        // Get the most recent semester (they should be sorted)
        _currentSemester = semesters.first;
        debugPrint('Latest semester: ${_currentSemester!.semesterName}');
      }
    } catch (e) {
      debugPrint('Error fetching latest semester: $e');
      // Fallback to a default semester if API fails
      _currentSemester = SemesterInfo(
        year: 2024,
        semester: 200, // Winter
        startDate: '',
        endDate: '',
      );
    }
  }

  // Fetch student data from Firestore
  Future<void> fetchStudentData(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Initialize semester info if not already done
      if (_currentSemester == null) {
        await initialize();
      }

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('Students')
              .doc(userId)
              .get();

      if (docSnapshot.exists) {
        _student = StudentModel.fromFirestore(docSnapshot);

        // After fetching student, load their courses
        await _loadStudentCourses(userId);
      } else {
        _error = 'Student not found';
      }
    } catch (e) {
      _error = 'Error fetching student data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load student's enrolled courses with details
  Future<void> _loadStudentCourses(String studentId) async {
    try {
      final studentRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId);

      // Get all semester documents
      final semestersSnapshot =
          await studentRef.collection('Courses-per-Semesters').get();

      _coursesBySemester.clear();

      for (final semesterDoc in semestersSnapshot.docs) {
        final semesterKey = semesterDoc.id;

        // Get courses for this semester
        final coursesSnapshot =
            await semesterDoc.reference.collection('Courses').get();

        final courses = <StudentCourse>[];

        for (final courseDoc in coursesSnapshot.docs) {
          final courseData = courseDoc.data();
          final studentCourse = StudentCourse.fromFirestore(courseData);

          // Fetch course details using CourseService
          await _fetchCourseDetailsIfNeeded(studentCourse.courseId);

          courses.add(studentCourse);
        }

        _coursesBySemester[semesterKey] = courses;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading student courses: $e');
    }
  }

  // Fetch course details from SAP API using CourseService
  Future<void> _fetchCourseDetailsIfNeeded(String courseId) async {
    if (_courseDetailsCache.containsKey(courseId)) {
      return; // Already cached
    }

    if (_currentSemester == null) {
      await _fetchLatestSemester();
    }

    if (_currentSemester == null) {
      debugPrint('No semester info available');
      return;
    }

    try {
      debugPrint(
        'Fetching course details for $courseId from ${_currentSemester!.semesterName}',
      );

      final courseDetails = await CourseService.getCourseDetails(
        _currentSemester!.year,
        _currentSemester!.semester,
        courseId,
      );

      if (courseDetails != null) {
        _courseDetailsCache[courseId] = courseDetails;
        debugPrint('Successfully cached details for course $courseId');
        notifyListeners(); // Notify listeners to update UI
      } else {
        debugPrint(
          'Course $courseId not found in ${_currentSemester!.semesterName}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching course details for $courseId: $e');
    }
  }

  // Get course with details (updated return type)
  StudentCourseWithDetails? getCourseWithDetails(
    String semesterKey,
    String courseId,
  ) {
    final studentCourse = _coursesBySemester[semesterKey]?.firstWhere(
      (course) => course.courseId == courseId,
      orElse: () => null as StudentCourse,
    );

    if (studentCourse == null) return null;

    final courseDetails = _courseDetailsCache[courseId];

    return StudentCourseWithDetails(
      studentCourse: studentCourse,
      courseDetails: courseDetails,
    );
  }

  // Add course to student's semester (with automatic detail fetching)
  Future<bool> addCourseToSemester(
    String semesterKey,
    StudentCourse course,
  ) async {
    if (_student == null) return false;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final studentRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(_student!.id);

      final semesterRef = studentRef
          .collection('Courses-per-Semesters')
          .doc(semesterKey);

      // First, ensure the semester document exists
      final semesterDoc = await semesterRef.get();
      if (!semesterDoc.exists) {
        // Create the semester document with metadata
        await semesterRef.set({
          'semesterName': semesterKey,
          'semesterNumber': _calculateSemesterNumber(semesterKey),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Now add the course to the semester's sub collection
      final courseRef = semesterRef.collection('Courses').doc(course.courseId);

      await courseRef.set(course.toFirestore());

      // Update local state
      _coursesBySemester.putIfAbsent(semesterKey, () => []).add(course);

      // Fetch course details immediately
      await _fetchCourseDetailsIfNeeded(course.courseId);

      return true;
    } catch (e) {
      _error = 'Error adding course: $e';
      debugPrint('Full error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search for courses in the current semester
  Future<List<CourseSearchResult>> searchCourses({
    String? courseId,
    String? courseName,
    String? faculty,
    int pastSemestersToInclude = 0,
  }) async {
    if (_currentSemester == null) {
      await _fetchLatestSemester();
    }

    if (_currentSemester == null) {
      return [];
    }

    if (pastSemestersToInclude == 0) {
      return await CourseService.searchCourses(
        year: _currentSemester!.year,
        semester: _currentSemester!.semester,
        courseId: courseId,
        courseName: courseName,
        faculty: faculty,
      );
    } else {
      // ✅ Fetch all semesters from API
      final allSemesters = await CourseService.getAvailableSemesters();
      debugPrint('📅 All semesters fetched:');
      for (var s in allSemesters) {
        debugPrint('  ${s.semester} ${s.year}');
      }
      // ✅ Sort them based on custom order (Winter < Spring < Summer)
      allSemesters.sort(CourseService.compareSemesters);

      debugPrint('📅 Sorted semesters:');
      for (var s in allSemesters) {
        debugPrint('  ${s.semester} ${s.year}');
      }

      debugPrint(
        '🎯 Current semester: ${_currentSemester!.semester} ${_currentSemester!.year}',
      );

      // ✅ Find the current semester index
      final currentIndex = allSemesters.indexWhere(
        (s) =>
            s.year == _currentSemester!.year &&
            s.semester == _currentSemester!.semester,
      );

      debugPrint('🔢 Current index in sorted list: $currentIndex');

      if (currentIndex == -1) {
        debugPrint('❌ Current semester not found in available semesters.');
        return [];
      }

      final fromIndex = (currentIndex - pastSemestersToInclude).clamp(
        0,
        allSemesters.length - 1,
      );
      debugPrint('🔍 Searching from index $fromIndex to $currentIndex');
      final selectedSemesters = allSemesters.sublist(
        fromIndex,
        currentIndex + 1,
      );

      debugPrint('📚 Semesters to search in:');
      for (var s in selectedSemesters) {
        debugPrint('  ${s.semester} ${s.year}');
      }
      final Map<String, CourseSearchResult> resultMap = {};

      for (final sem in selectedSemesters) {
        final res = await CourseService.searchCourses(
          year: sem.year,
          semester: sem.semester,
          courseId: courseId,
          courseName: courseName,
          faculty: faculty,
        );

        for (final r in res) {
          // Add only if not already present (keeps first occurrence)
          resultMap.putIfAbsent(r.course.courseNumber, () => r);
        }
      }

      return resultMap.values.toList();
    }
  }

  // Helper method to calculate semester number
  int _calculateSemesterNumber(String semesterKey) {
    if (semesterKey.toLowerCase().contains('winter')) {
      return 1;
    } else if (semesterKey.toLowerCase().contains('spring')) {
      return 2;
    } else if (semesterKey.toLowerCase().contains('summer')) {
      return 3;
    }
    return 1; // Default
  }

  // Update course grade
  Future<bool> updateCourseGrade(
    String semesterKey,
    String courseId,
    String grade,
  ) async {
    if (_student == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(_student!.id)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .update({'Final_grade': grade});

      // Update local state
      final semesterCourses = _coursesBySemester[semesterKey];
      if (semesterCourses != null) {
        final courseIndex = semesterCourses.indexWhere(
          (course) => course.courseId == courseId,
        );
        if (courseIndex != -1) {
          semesterCourses[courseIndex] = semesterCourses[courseIndex].copyWith(
            finalGrade: grade,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating grade: $e';
      return false;
    }
  }


  // Update course grade
  Future<bool> updateCourseNote(
    String semesterKey,
    String courseId,
    String note,
  ) async {
    if (_student == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(_student!.id)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .update({'Note': note});

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating note: $e';
      return false;
    }
  }


  // Create and save a new student model
  Future<bool> createStudent(StudentModel student) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(student.id)
          .set(student.toFirestore());

      _student = student;

      // Initialize semester info after creating student
      if (_currentSemester == null) {
        await initialize();
      }

      return true;
    } catch (e) {
      _error = 'Error creating student: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get total credits for a semester
  double getTotalCreditsForSemester(String semesterKey) {
    final courses = _coursesBySemester[semesterKey] ?? [];
    double total = 0.0;

    for (final course in courses) {
      final details = _courseDetailsCache[course.courseId];
      if (details != null) {
        total += details.creditPoints;
      }
    }

    return total;
  }

  // Check if course details are loading
  bool isCourseDetailsLoading(String courseId) {
    return !_courseDetailsCache.containsKey(courseId) &&
        _currentSemester != null;
  }

  // Force refresh course details (useful for retry)
  Future<void> refreshCourseDetails(String courseId) async {
    _courseDetailsCache.remove(courseId);
    await _fetchCourseDetailsIfNeeded(courseId);
  }

  // In student_notifier.dart
  List<CalendarEventData> getCalendarEvents() {
    final events = <CalendarEventData>[];

    for (final semesterEntry in _coursesBySemester.entries) {
      final courses = semesterEntry.value;

      for (final course in courses) {
        final courseDetails = _courseDetailsCache[course.courseId];

        if (courseDetails != null) {
          for (final schedule in courseDetails.schedule) {
            // Parse schedule and create calendar events
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
    // Parse Hebrew day names and times to create calendar events
    final dayMap = {
      'א': DateTime.sunday,
      'ב': DateTime.monday,
      'ג': DateTime.tuesday,
      'ד': DateTime.wednesday,
      'ה': DateTime.thursday,
      'ו': DateTime.friday,
      'ש': DateTime.saturday,
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
      description: '${course.courseId} - ${schedule.fullLocation}',
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
      color: Colors.blue, // Customize color as needed //!!??
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

  // Clear all data (for sign out)
  void clear() {
    _student = null;
    _coursesBySemester.clear();
    _courseDetailsCache.clear();
    _currentSemester = null;
    _error = '';
    notifyListeners();
  }

  void setStudent(StudentModel newStudent) {
    _student = newStudent;
    notifyListeners();
  }

  void updateStudentProfile({
    required String name,
    required String major,
    required String preferences,
    required String faculty,
    required String catalog,
    required String semester,
  }) async {
    if (_student == null) return;

    final updatedStudent = _student!.copyWith(
      name: name,
      major: major,
      preferences: preferences,
      faculty: faculty,
      catalog: catalog,
      semester: semester,
    );

    _student = updatedStudent;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(_student!.id)
          .update({
            'Name': name,
            'Major': major,
            'Preferences': preferences,
            'Faculty': faculty,
            'Catalog': catalog,
            'Semester': semester,
          });
    } catch (e) {
      debugPrint('🔥 Failed to update profile: $e');
    }
  }

  Future<void> addSemester(String semesterName, BuildContext context) async {
    if (_coursesBySemester.containsKey(semesterName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semester "$semesterName" already exists'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _coursesBySemester[semesterName] = [];
    notifyListeners();

    try {
      final studentId = _student?.id;
      if (studentId == null) return;

      final semesterNumber = _coursesBySemester.length;
      final createdAt = DateTime.now();

      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterName)
          .set({
            'semesterName': semesterName,
            'semesterNumber': semesterNumber,
            'createdAt': createdAt,
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add semester: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteSemester(String semesterName, BuildContext context) async {
    final studentId = _student?.id;
    if (studentId == null) return;

    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterName)
          .delete();

      // Delete from local map
      _coursesBySemester.remove(semesterName);
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted semester "$semesterName"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Map<String, List<StudentCourse>> get sortedCoursesBySemester {
    final List<String> semesterNames = _coursesBySemester.keys.toList();

    semesterNames.sort((a, b) {
      // Sort semesters by year and season
      final parsedA = _parseSemester(
        a,
      ); //turns "Spring 2025" into {season: "Spring", year: 2025}
      final parsedB = _parseSemester(b);

      final yearComparison = parsedA.year.compareTo(parsedB.year);
      if (yearComparison != 0)
        return yearComparison; // If years are different , sort by year

      return _seasonOrder(
        parsedA.season,
      ).compareTo(_seasonOrder(parsedB.season));
    });

    return {for (final name in semesterNames) name: _coursesBySemester[name]!};
  }

  int _seasonOrder(String season) {
    switch (season.toLowerCase()) {
      case 'winter':
        return 1;
      case 'spring':
        return 2;
      case 'summer':
        return 3;
      default:
        return 99;
    }
  }

  ({String season, int year}) _parseSemester(String semesterName) {
    final parts = semesterName.split(' ');
    final season = parts[0];
    final year = (parts.length > 1) ? int.tryParse(parts[1]) ?? 0 : 0;
    return (season: season, year: year);
  }
}

// Simplified models to match your database structure
class StudentCourse {
  final String courseId;
  final String name;
  final String finalGrade;
  final String lectureTime;
  final String tutorialTime;
  final String? note;

  StudentCourse({
    required this.courseId,
    required this.name,
    required this.finalGrade,
    required this.lectureTime,
    required this.tutorialTime,
    this.note,
  });

  factory StudentCourse.fromFirestore(Map<String, dynamic> data) {
    return StudentCourse(
      courseId: data['Course_Id'] ?? '',
      name: data['Name'] ?? '',
      finalGrade: data['Final_grade'] ?? '',
      lectureTime: data['Lecture_time'] ?? '',
      tutorialTime: data['Tutorial_time'] ?? '',
      note: data['Note'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'Course_Id': courseId,
      'Name': name,
      'Final_grade': finalGrade,
      'Lecture_time': lectureTime,
      'Tutorial_time': tutorialTime,
      'Note': note ?? '',
    };
  }

  StudentCourse copyWith({String? finalGrade}) {
    return StudentCourse(
      courseId: courseId,
      name: name,
      finalGrade: finalGrade ?? this.finalGrade,
      lectureTime: lectureTime,
      tutorialTime: tutorialTime,
      note: note,
    );
  }
}

class StudentCourseWithDetails {
  final StudentCourse studentCourse;
  final EnhancedCourseDetails? courseDetails;

  StudentCourseWithDetails({required this.studentCourse, this.courseDetails});
}
