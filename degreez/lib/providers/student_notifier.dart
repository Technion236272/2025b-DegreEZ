// providers/student_notifier.dart (Enhanced)
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/student_model.dart';

class StudentNotifier with ChangeNotifier {
  // Student data
  StudentModel? _student;
  bool _isLoading = false;
  String _error = '';

  // Student's courses with details
  Map<String, List<StudentCourse>> _coursesBySemester = {};
  Map<String, CourseDetails> _courseDetailsCache = {};

  // Getters
  StudentModel? get student => _student;
  bool get isLoading => _isLoading;
  String get error => _error;
  Map<String, List<StudentCourse>> get coursesBySemester => _coursesBySemester;

  // Fetch student data from Firestore
  Future<void> fetchStudentData(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Students')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        _student = StudentModel.fromFirestore(
            docSnapshot.data() as Map<String, dynamic>);
        
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
          
          // Fetch course details if not cached
          await _fetchCourseDetailsIfNeeded(studentCourse.courseId);
          
          courses.add(studentCourse);
        }

        _coursesBySemester[semesterKey] = courses;
      }
    } catch (e) {
      debugPrint('Error loading student courses: $e');
    }
  }

  // Fetch course details from SAP API only when needed
  Future<void> _fetchCourseDetailsIfNeeded(String courseId) async {
    if (_courseDetailsCache.containsKey(courseId)) {
      return; // Already cached
    }

    try {
      // Current semester - you might make this dynamic
      const year = '2024';
      const semester = '200'; // Winter
      
      final url = 'https://michael-maltsev.github.io/technion-sap-info-fetcher/courses_$year-$semester.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = json.decode(response.body);
        
        final courseData = coursesJson.firstWhere(
          (course) => course['general']['מספר מקצוע'] == courseId,
          orElse: () => null,
        );

        if (courseData != null) {
          _courseDetailsCache[courseId] = CourseDetails.fromSapJson(courseData);
        }
      }
    } catch (e) {
      debugPrint('Error fetching course details for $courseId: $e');
    }
  }

  // Get course with details
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

  // Add course to student's semester
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
      
      // Fetch course details
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

  // Helper method to calculate semester number
  int _calculateSemesterNumber(String semesterKey) {
    // This is a simple implementation - you might want to make it more sophisticated
    // based on your semester naming convention
    if (semesterKey.toLowerCase().contains('winter')) {
      return 1; // Or extract year and calculate properly
    } else if (semesterKey.toLowerCase().contains('spring')) {
      return 2;
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
        total += double.tryParse(details.points) ?? 0.0;
      }
    }
    
    return total;
  }

  // Clear all data (for sign out)
  void clear() {
    _student = null;
    _coursesBySemester.clear();
    _courseDetailsCache.clear();
    _error = '';
    notifyListeners();
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

class CourseDetails {
  final String courseNumber;
  final String name;
  final String syllabus;
  final String faculty;
  final String points;
  final String prerequisites;
  final List<ScheduleEntry> schedule;

  CourseDetails({
    required this.courseNumber,
    required this.name,
    required this.syllabus,
    required this.faculty,
    required this.points,
    required this.prerequisites,
    required this.schedule,
  });

  factory CourseDetails.fromSapJson(Map<String, dynamic> json) {
    final general = json['general'] as Map<String, dynamic>;
    final scheduleList = json['schedule'] as List<dynamic>;
    
    return CourseDetails(
      courseNumber: general['מספר מקצוע'] ?? '',
      name: general['שם מקצוע'] ?? '',
      syllabus: general['סילבוס'] ?? '',
      faculty: general['פקולטה'] ?? '',
      points: general['נקודות'] ?? '',
      prerequisites: general['מקצועות קדם'] ?? '',
      schedule: scheduleList.map((s) => ScheduleEntry.fromJson(s)).toList(),
    );
  }
}

class ScheduleEntry {
  final int group;
  final String type;
  final String day;
  final String time;
  final String building;
  final String staff;

  ScheduleEntry({
    required this.group,
    required this.type,
    required this.day,
    required this.time,
    required this.building,
    required this.staff,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      group: json['קבוצה'] ?? 0,
      type: json['סוג'] ?? '',
      day: json['יום'] ?? '',
      time: json['שעה'] ?? '',
      building: json['בניין'] ?? '',
      staff: json['מרצה/מתרגל'] ?? '',
    );
  }
}

class StudentCourseWithDetails {
  final StudentCourse studentCourse;
  final CourseDetails? courseDetails;

  StudentCourseWithDetails({
    required this.studentCourse,
    this.courseDetails,
  });
}