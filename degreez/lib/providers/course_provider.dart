// providers/course_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';

class CourseLoadingState {
  final bool isLoadingCourses;
  final bool isAddingCourse;
  final Set<String> loadingCourseDetails;
  final Map<String, bool> updatingGrades;

  const CourseLoadingState({
    this.isLoadingCourses = false,
    this.isAddingCourse = false,
    this.loadingCourseDetails = const {},
    this.updatingGrades = const {},
  });

  CourseLoadingState copyWith({
    bool? isLoadingCourses,
    bool? isAddingCourse,
    Set<String>? loadingCourseDetails,
    Map<String, bool>? updatingGrades,
  }) {
    return CourseLoadingState(
      isLoadingCourses: isLoadingCourses ?? this.isLoadingCourses,
      isAddingCourse: isAddingCourse ?? this.isAddingCourse,
      loadingCourseDetails: loadingCourseDetails ?? this.loadingCourseDetails,
      updatingGrades: updatingGrades ?? this.updatingGrades,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseLoadingState &&
          isLoadingCourses == other.isLoadingCourses &&
          isAddingCourse == other.isAddingCourse &&
          loadingCourseDetails.length == other.loadingCourseDetails.length &&
          loadingCourseDetails.containsAll(other.loadingCourseDetails) &&
          updatingGrades.length == other.updatingGrades.length;

  @override
  int get hashCode => Object.hash(
        isLoadingCourses,
        isAddingCourse,
        loadingCourseDetails.length,
        updatingGrades.length,
      );
}

class CourseProvider with ChangeNotifier {
  Map<String, List<StudentCourse>> _coursesBySemester = {};
  CourseLoadingState _loadingState = const CourseLoadingState();
  String? _error;

  // Getters
  Map<String, List<StudentCourse>> get coursesBySemester => Map.unmodifiable(_coursesBySemester);
  CourseLoadingState get loadingState => _loadingState;
  String? get error => _error;

  // Add this getter to distinguish between unloaded and empty data
  bool get hasLoadedData => !_loadingState.isLoadingCourses && _error == null;
  bool get hasAnyCourses => _coursesBySemester.values.any((courses) => courses.isNotEmpty);
  bool get isEmpty => hasLoadedData && _coursesBySemester.isEmpty;

  // Helper method to find a course by ID
  StudentCourse? _findCourseById(String courseId) {
    for (final semesterCourses in _coursesBySemester.values) {
      for (final course in semesterCourses) {
        if (course.courseId == courseId) {
          return course;
        }
      }
    }
    return null;
  }

  // Load courses with proper loading state
  Future<bool> loadStudentCourses(String studentId) async {
    // !! this one is called when we navigate to the courses page
    // If already loaded, no need to load again
    if (_loadingState.isLoadingCourses) {
      // Already loading, no need to start again
      return false;
    }
  // !! this causes error when navigating back to courses page
  // this if condition fixes it
    if (_coursesBySemester.isNotEmpty) {
      // Already loaded, no need to load again
      return true;
    }
    _setLoadingState(_loadingState.copyWith(isLoadingCourses: true));

    try {
      final studentRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId);

      final semestersSnapshot = await studentRef
          .collection('Courses-per-Semesters')
          .get();

      final newCoursesBySemester = <String, List<StudentCourse>>{};

      for (final semesterDoc in semestersSnapshot.docs) {
        final semesterKey = semesterDoc.id;
        final coursesSnapshot = await semesterDoc.reference
            .collection('Courses')
            .get();

        final courses = coursesSnapshot.docs
            .map((doc) => StudentCourse.fromFirestore(doc.data()))
            .toList();

        newCoursesBySemester[semesterKey] = courses;
      }

      _coursesBySemester = newCoursesBySemester;
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to load courses: $e';
      return false;
    } finally {
      _setLoadingState(_loadingState.copyWith(isLoadingCourses: false));
    }
  }

  // Add course with optimistic update
  Future<bool> addCourseToSemester(
    String studentId,
    String semesterKey,
    StudentCourse course,
  ) async {
    _setLoadingState(_loadingState.copyWith(isAddingCourse: true));

    // Optimistic update
    _coursesBySemester.putIfAbsent(semesterKey, () => []).add(course);
    notifyListeners();

    try {
      final studentRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId);

      final semesterRef = studentRef
          .collection('Courses-per-Semesters')
          .doc(semesterKey);

      // Ensure semester document exists
      final semesterDoc = await semesterRef.get();
      if (!semesterDoc.exists) {
        await semesterRef.set({
          'semesterName': semesterKey,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Add course
      await semesterRef
          .collection('Courses')
          .doc(course.courseId)
          .set(course.toFirestore());

      _error = null;
      return true;
    } catch (e) {
      // Rollback optimistic update
      _coursesBySemester[semesterKey]?.removeWhere(
        (c) => c.courseId == course.courseId,
      );
      _error = 'Failed to add course: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoadingState(_loadingState.copyWith(isAddingCourse: false));
    }
  }

  // Update grade with optimistic update and granular loading
  Future<bool> updateCourseGrade(
    String studentId,
    String semesterKey,
    String courseId,
    String grade,
  ) async {
    // Set loading for this specific course
    final newUpdatingGrades = Map<String, bool>.from(_loadingState.updatingGrades);
    newUpdatingGrades[courseId] = true;
    _setLoadingState(_loadingState.copyWith(updatingGrades: newUpdatingGrades));

    // Store old grade for rollback
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) return false;

    final courseIndex = semesterCourses.indexWhere((c) => c.courseId == courseId);
    if (courseIndex == -1) return false;

    final oldCourse = semesterCourses[courseIndex];
    
    // Optimistic update
    semesterCourses[courseIndex] = oldCourse.copyWith(finalGrade: grade);
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .update({'Final_grade': grade});

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      semesterCourses[courseIndex] = oldCourse;
      _error = 'Failed to update grade: $e';
      notifyListeners();
      return false;
    } finally {
      // Remove loading state for this course
      newUpdatingGrades.remove(courseId);
      _setLoadingState(_loadingState.copyWith(updatingGrades: newUpdatingGrades));
    }
  }

  // Update course note with optimistic update
  Future<bool> updateCourseNote(
    String studentId,
    String semesterKey,
    String courseId,
    String note,
  ) async {
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) return false;

    final courseIndex = semesterCourses.indexWhere((c) => c.courseId == courseId);
    if (courseIndex == -1) return false;

    final oldCourse = semesterCourses[courseIndex];
    
    // Optimistic update
    semesterCourses[courseIndex] = oldCourse.copyWith(note: note);
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .update({'Note': note});

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      semesterCourses[courseIndex] = oldCourse;
      _error = 'Failed to update note: $e';
      notifyListeners();
      return false;
    }
  }

  // NEW: Update course schedule selection using lectureTime and tutorialTime
  Future<bool> updateCourseScheduleSelection(
    String studentId,
    String semesterKey,
    String courseId,
    String? selectedLectureTime,
    String? selectedTutorialTime,
  ) async {
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) return false;

    final courseIndex = semesterCourses.indexWhere((c) => c.courseId == courseId);
    if (courseIndex == -1) return false;

    final oldCourse = semesterCourses[courseIndex];
    
    // Optimistic update
    semesterCourses[courseIndex] = oldCourse.copyWith(
      lectureTime: selectedLectureTime ?? '',
      tutorialTime: selectedTutorialTime ?? '',
    );
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .update({
            'Lecture_time': selectedLectureTime ?? '',
            'Tutorial_time': selectedTutorialTime ?? '',
          });

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      semesterCourses[courseIndex] = oldCourse;
      _error = 'Failed to update schedule selection: $e';
      notifyListeners();
      return false;
    }
  }

  // Helper method to get selected schedule entries for a course
  Map<String, ScheduleEntry?> getSelectedScheduleEntries(
    String courseId, 
    EnhancedCourseDetails? courseDetails,
  ) {
    if (courseDetails == null) {
      return {'lecture': null, 'tutorial': null};
    }

    // Find the course in our data using the helper method
    final course = _findCourseById(courseId);
    if (course == null) {
      return {'lecture': null, 'tutorial': null};
    }

    ScheduleEntry? selectedLecture;
    ScheduleEntry? selectedTutorial;

    // Match stored lecture time with schedule entries
    if (course.lectureTime.isNotEmpty) {
      for (final schedule in courseDetails.schedule) {
        final scheduleString = StudentCourse.formatScheduleString(schedule.day, schedule.time);
        if (course.lectureTime == scheduleString) {
          selectedLecture = schedule;
          break;
        }
      }
    }

    // Match stored tutorial time with schedule entries
    if (course.tutorialTime.isNotEmpty) {
      for (final schedule in courseDetails.schedule) {
        final scheduleString = StudentCourse.formatScheduleString(schedule.day, schedule.time);
        if (course.tutorialTime == scheduleString) {
          selectedTutorial = schedule;
          break;
        }
      }
    }

    return {
      'lecture': selectedLecture,
      'tutorial': selectedTutorial,
    };
  }

  // Add semester with validation
  Future<bool> addSemester(String studentId, String semesterName) async {
    if (_coursesBySemester.containsKey(semesterName)) {
      _error = 'Semester "$semesterName" already exists';
      notifyListeners();
      return false;
    }

    // Optimistic update
    _coursesBySemester[semesterName] = [];
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterName)
          .set({
            'semesterName': semesterName,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      _coursesBySemester.remove(semesterName);
      _error = 'Failed to add semester: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete semester with optimistic update
  Future<bool> deleteSemester(String studentId, String semesterName) async {
    if (!_coursesBySemester.containsKey(semesterName)) {
      _error = 'Semester "$semesterName" does not exist';
      notifyListeners();
      return false;
    }

    // Store for rollback
    final oldCourses = _coursesBySemester[semesterName]!;
    
    // Optimistic update
    _coursesBySemester.remove(semesterName);
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterName)
          .delete();

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      _coursesBySemester[semesterName] = oldCourses;
      _error = 'Failed to delete semester: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove course from semester with optimistic update
  Future<bool> removeCourseFromSemester(
    String studentId,
    String semesterKey,
    String courseId,
  ) async {
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) {
      _error = 'Semester "$semesterKey" does not exist';
      notifyListeners();
      return false;
    }

    final courseIndex = semesterCourses.indexWhere((c) => c.courseId == courseId);
    if (courseIndex == -1) {
      _error = 'Course not found in semester';
      notifyListeners();
      return false;
    }

    // Store for rollback
    final removedCourse = semesterCourses[courseIndex];
    
    // Optimistic update
    semesterCourses.removeAt(courseIndex);
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterKey)
          .collection('Courses')
          .doc(courseId)
          .delete();

      _error = null;
      return true;
    } catch (e) {
      // Rollback
      semesterCourses.insert(courseIndex, removedCourse);
      _error = 'Failed to remove course: $e';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _coursesBySemester.clear();
    _loadingState = const CourseLoadingState();
    _error = null;
    notifyListeners();
  }

  void _setLoadingState(CourseLoadingState newState) {
    if (_loadingState != newState) {
      _loadingState = newState;
      notifyListeners();
    }
  }
}
