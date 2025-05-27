// providers/student_notifier.dart (Enhanced with CourseService integration)
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';
import 'package:calendar_view/calendar_view.dart';
import '../widgets/course_calendar_panel.dart';
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

      final docSnapshot = await FirebaseFirestore.instance
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
      final semestersSnapshot = await studentRef
          .collection('Courses-per-Semesters')
          .get();

      _coursesBySemester.clear();

      for (final semesterDoc in semestersSnapshot.docs) {
        final semesterKey = semesterDoc.id;
        
        // Get courses for this semester
        final coursesSnapshot = await semesterDoc.reference
            .collection('Courses')
            .get();

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
      debugPrint('Fetching course details for $courseId from ${_currentSemester!.semesterName}');
      
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
        debugPrint('Course $courseId not found in ${_currentSemester!.semesterName}');
      }
    } catch (e) {
      debugPrint('Error fetching course details for $courseId: $e');
    }
  }

  // Get course with details (updated return type)
  StudentCourseWithDetails? getCourseWithDetails(String semesterKey, String courseId) {
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
  Future<bool> addCourseToSemester(String semesterKey, StudentCourse course) async {
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
      
      // Now add the course to the semester's subcollection
      final courseRef = semesterRef
          .collection('Courses')
          .doc(course.courseId);

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
  }) async {
    if (_currentSemester == null) {
      await _fetchLatestSemester();
    }

    if (_currentSemester == null) {
      return [];
    }

    return await CourseService.searchCourses(
      year: _currentSemester!.year,
      semester: _currentSemester!.semester,
      courseId: courseId,
      courseName: courseName,
      faculty: faculty,
    );
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
  Future<bool> updateCourseGrade(String semesterKey, String courseId, String grade) async {
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
          (course) => course.courseId == courseId
        );
        if (courseIndex != -1) {
          semesterCourses[courseIndex] = semesterCourses[courseIndex].copyWith(finalGrade: grade);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating grade: $e';
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
    return !_courseDetailsCache.containsKey(courseId) && _currentSemester != null;
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
          final event = _createCalendarEventFromSchedule(course, courseDetails, schedule);
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
  ScheduleEntry schedule
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
  required int semester,
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
    print('🔥 Failed to update profile: $e');
  }
}



}

// Simplified models to match your database structure
class StudentCourse {
  final String courseId;
  final String name;
  final String finalGrade;
  final String lectureTime;
  final String tutorialTime;

  StudentCourse({
    required this.courseId,
    required this.name,
    required this.finalGrade,
    required this.lectureTime,
    required this.tutorialTime,
  });

  factory StudentCourse.fromFirestore(Map<String, dynamic> data) {
    return StudentCourse(
      courseId: data['Course_Id'] ?? '',
      name: data['Name'] ?? '',
      finalGrade: data['Final_grade'] ?? '',
      lectureTime: data['Lecture_time'] ?? '',
      tutorialTime: data['Tutorial_time'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'Course_Id': courseId,
      'Name': name,
      'Final_grade': finalGrade,
      'Lecture_time': lectureTime,
      'Tutorial_time': tutorialTime,
    };
  }

  StudentCourse copyWith({String? finalGrade}) {
    return StudentCourse(
      courseId: courseId,
      name: name,
      finalGrade: finalGrade ?? this.finalGrade,
      lectureTime: lectureTime,
      tutorialTime: tutorialTime,
    );
  }
}

class StudentCourseWithDetails {
  final StudentCourse studentCourse;
  final EnhancedCourseDetails? courseDetails;

  StudentCourseWithDetails({
    required this.studentCourse,
    this.courseDetails,
  });
}