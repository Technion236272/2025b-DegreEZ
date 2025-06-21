// providers/course_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';
import '../services/GlobalConfigService.dart';

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
  final Map<String, EnhancedCourseDetails> _courseDetailsCache = {};
  SemesterInfo? _currentSemester;

  SemesterInfo? get currentSemester => _currentSemester;

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

  // Getters
  List<StudentCourse> getCoursesForSemester(String semesterKey) {
    return _coursesBySemester[semesterKey] ?? [];
  }

  Map<String, List<StudentCourse>> get coursesBySemester =>
      Map.unmodifiable(_coursesBySemester);
  CourseLoadingState get loadingState => _loadingState;
  String? get error => _error;

  // Add this getter to distinguish between unloaded and empty data
  bool get hasLoadedData => !_loadingState.isLoadingCourses && _error == null;
  bool get hasAnyCourses =>
      _coursesBySemester.values.any((courses) => courses.isNotEmpty);
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

      final semestersSnapshot =
          await studentRef.collection('Courses-per-Semesters').get();

      final newCoursesBySemester = <String, List<StudentCourse>>{};

      for (final semesterDoc in semestersSnapshot.docs) {
        final semesterKey = semesterDoc.id;
        debugPrint('📘 Found semester: $semesterKey');
        final coursesSnapshot =
            await semesterDoc.reference.collection('Courses').get();

        final courses =
            coursesSnapshot.docs
                .map((doc) => StudentCourse.fromFirestore(doc.data()))
                .toList();

        newCoursesBySemester[semesterKey] = courses;
      }
      _coursesBySemester = newCoursesBySemester;
      _error = null;

      // Check if we need to migrate any courses that don't have credit points
      final needsMigration = _coursesBySemester.values.any(
        (courses) => courses.any((course) => course.creditPoints <= 0),
      );

      if (needsMigration) {
        debugPrint(
          '🔄 Detected courses without credit points, starting migration...',
        );
        // Run migration in background without blocking the UI
        migrateCreditPointsForExistingCourses(studentId);
      }

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

      // 🔍 Fetch prerequisites (as string or list from API)
      final parsed = _parseSemesterCode(semesterKey);
      if (parsed == null) {
        debugPrint('❌ Invalid semester format: $semesterKey');
        return false;
      }
      final (year, semesterCode) = parsed;
      final rawPrereqs =
          (await CourseService.getCourseDetails(
            year,
            semesterCode,
            course.courseId,
          ))?.prerequisites;
      debugPrint('📦 Raw prerequisites from API: $rawPrereqs');

      List<List<String>> parsedPrereqs = [];

      if (rawPrereqs is String) {
        final orGroups = rawPrereqs.split(RegExp(r'\s*או\s*'));
        debugPrint('📦 orGroups : $orGroups');

        for (final group in orGroups) {
          final andGroup =
              group
                  .replaceAll(
                    RegExp(r'[^\d\s]'),
                    '', // keep only digits + space
                  )
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((id) => RegExp(r'^\d{8}$').hasMatch(id))
                  .toList();

          if (andGroup.isNotEmpty) parsedPrereqs.add(andGroup);
        }
      } else {
        debugPrint(
          '⚠️ Unexpected prerequisite format: ${rawPrereqs.runtimeType}',
        );
      }

      // 🔁 Convert parsedPrereqs to the expected format for Firestore
      final List<Map<String, List<String>>> mappedPrereqs =
          parsedPrereqs.map((andGroup) => {'and': andGroup}).toList();

      // ✅ Create enriched course
      final enrichedCourse = course.copyWith(prerequisites: mappedPrereqs);

      // ✅ Optimistic update
      _coursesBySemester.putIfAbsent(semesterKey, () => []).add(enrichedCourse);
      notifyListeners();

      // ✅ Save to Firestore
      debugPrint('📤 Writing course: ${enrichedCourse.courseId}');
      debugPrint(
        '✅ Writing data to Firestore: ${enrichedCourse.toFirestore()}',
      );

      await semesterRef
          .collection('Courses')
          .doc(course.courseId)
          .set(enrichedCourse.toFirestore());

      // ✅ Refresh UI
      await loadStudentCourses(studentId);
      _error = null;
      return true;
    } catch (e, stack) {
      debugPrint('❌ Error writing course to Firestore: $e');
      debugPrint('📍 Stack trace: $stack');
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
    final newUpdatingGrades = Map<String, bool>.from(
      _loadingState.updatingGrades,
    );
    newUpdatingGrades[courseId] = true;
    _setLoadingState(_loadingState.copyWith(updatingGrades: newUpdatingGrades));

    // Store old grade for rollback
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) return false;

    final courseIndex = semesterCourses.indexWhere(
      (c) => c.courseId == courseId,
    );
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
      _setLoadingState(
        _loadingState.copyWith(updatingGrades: newUpdatingGrades),
      );
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

    final courseIndex = semesterCourses.indexWhere(
      (c) => c.courseId == courseId,
    );
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
    String? selectedLabTime,
    String? selectedWorkshopTime,
  ) async {
    final semesterCourses = _coursesBySemester[semesterKey];
    if (semesterCourses == null) return false;

    final courseIndex = semesterCourses.indexWhere(
      (c) => c.courseId == courseId,
    );
    if (courseIndex == -1) return false;

    final oldCourse = semesterCourses[courseIndex];

    // Optimistic update
    semesterCourses[courseIndex] = oldCourse.copyWith(
      lectureTime: selectedLectureTime ?? '',
      tutorialTime: selectedTutorialTime ?? '',
      labTime: selectedLabTime ?? '',
      workshopTime: selectedWorkshopTime ?? '',
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
            'Lab_time': selectedLabTime ?? '',
            'Workshop_time': selectedWorkshopTime ?? '',
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
  Map<String, List<ScheduleEntry>> getSelectedScheduleEntries(
    String courseId,
    EnhancedCourseDetails? courseDetails,
  ) {
    if (courseDetails == null) {
      return {'lecture': [], 'tutorial': [], 'lab': [], 'workshop': []};
    }

    // Find the course in our data using the helper method
    final course = _findCourseById(courseId);
    if (course == null) {
      return {'lecture': [], 'tutorial': [], 'lab': [], 'workshop': []};
    }

    final selectedLectures = <ScheduleEntry>[];
    final selectedTutorials = <ScheduleEntry>[];
    final selectedLabs = <ScheduleEntry>[];
    final selectedWorkshops = <ScheduleEntry>[];

    // Match stored lecture time with schedule entries
    if (course.lectureTime.isNotEmpty) {
      if (course.lectureTime.startsWith('GROUP_')) {
        // New group format: find all entries with the same type and group
        final parts = course.lectureTime.split('_');
        if (parts.length >= 3) {
          final type = parts[1];
          final group = int.tryParse(parts[2]);
          if (group != null) {
            selectedLectures.addAll(
              courseDetails.schedule
                  .where(
                    (schedule) =>
                        schedule.type == type && schedule.group == group,
                  )
                  .toList(),
            );
          }
        }
      } else {
        // Backward compatibility: old time format
        for (final schedule in courseDetails.schedule) {
          final scheduleString = StudentCourse.formatScheduleString(
            schedule.day,
            schedule.time,
          );
          if (course.lectureTime == scheduleString) {
            selectedLectures.add(schedule);
            break;
          }
        }
      }
    }

    // Match stored tutorial time with schedule entries
    if (course.tutorialTime.isNotEmpty) {
      if (course.tutorialTime.startsWith('GROUP_')) {
        // New group format: find all entries with the same type and group
        final parts = course.tutorialTime.split('_');
        if (parts.length >= 3) {
          final type = parts[1];
          final group = int.tryParse(parts[2]);
          if (group != null) {
            selectedTutorials.addAll(
              courseDetails.schedule
                  .where(
                    (schedule) =>
                        schedule.type == type && schedule.group == group,
                  )
                  .toList(),
            );
          }
        }
      } else {
        // Backward compatibility: old time format
        for (final schedule in courseDetails.schedule) {
          final scheduleString = StudentCourse.formatScheduleString(
            schedule.day,
            schedule.time,
          );
          if (course.tutorialTime == scheduleString) {
            selectedTutorials.add(schedule);
            break;
          }
        }
      }
    }

    // Match stored lab time with schedule entries
    if (course.labTime.isNotEmpty) {
      if (course.labTime.startsWith('GROUP_')) {
        // New group format: find all entries with the same type and group
        final parts = course.labTime.split('_');
        if (parts.length >= 3) {
          final type = parts[1];
          final group = int.tryParse(parts[2]);
          if (group != null) {
            selectedLabs.addAll(
              courseDetails.schedule
                  .where(
                    (schedule) =>
                        schedule.type == type && schedule.group == group,
                  )
                  .toList(),
            );
          }
        }
      } else {
        // Backward compatibility: old time format
        for (final schedule in courseDetails.schedule) {
          final scheduleString = StudentCourse.formatScheduleString(
            schedule.day,
            schedule.time,
          );
          if (course.labTime == scheduleString) {
            selectedLabs.add(schedule);
            break;
          }
        }
      }
    }

    // Match stored workshop time with schedule entries
    if (course.workshopTime.isNotEmpty) {
      if (course.workshopTime.startsWith('GROUP_')) {
        // New group format: find all entries with the same type and group
        final parts = course.workshopTime.split('_');
        if (parts.length >= 3) {
          final type = parts[1];
          final group = int.tryParse(parts[2]);
          if (group != null) {
            selectedWorkshops.addAll(
              courseDetails.schedule
                  .where(
                    (schedule) =>
                        schedule.type == type && schedule.group == group,
                  )
                  .toList(),
            );
          }
        }
      } else {
        // Backward compatibility: old time format
        for (final schedule in courseDetails.schedule) {
          final scheduleString = StudentCourse.formatScheduleString(
            schedule.day,
            schedule.time,
          );
          if (course.workshopTime == scheduleString) {
            selectedWorkshops.add(schedule);
            break;
          }
        }
      }
    }

    return {
      'lecture': selectedLectures,
      'tutorial': selectedTutorials,
      'lab': selectedLabs,
      'workshop': selectedWorkshops,
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

  // Helper function to convert semester ID to semester name
  String _getSemesterNameFromId(int semesterId, int year) {
    switch (semesterId) {
      case 200:
        return 'Winter $year-${year + 1}';
      case 201:
        return 'Spring ${year + 1}';
      case 202:
        return 'Summer $year';
      default:
        return 'Semester $semesterId $year';
    }
  }

  // Add semester by ID with validation
  Future<bool> addSemesterById(String studentId, int semesterId, int year) async {
    final semesterName = _getSemesterNameFromId(semesterId, year);
    
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
            'semesterId': semesterId,
            'year': year,
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

  Future<bool> deleteStudentAndCourses(String studentId) async {
    try {
      final studentRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId);

      // Step 1: Delete all documents in the 'Courses-per-Semesters' sub collection
      final semesterDocs =
          await studentRef.collection('Courses-per-Semesters').get();
      for (final doc in semesterDocs.docs) {
        await deleteSemester(studentId, doc.get("semesterName"));
      }

      // Step 2: Delete the student document
      await studentRef.delete();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to delete student: $e';
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

    final oldCourses = _coursesBySemester[semesterName]!;

    // Optimistic update
    _coursesBySemester.remove(semesterName);
    notifyListeners();

    try {
      final semesterRef = FirebaseFirestore.instance
          .collection('Students')
          .doc(studentId)
          .collection('Courses-per-Semesters')
          .doc(semesterName);

      // Step 1: Delete all documents in the 'Courses' sub collection
      final courseDocs = await semesterRef.collection('Courses').get();
      for (final doc in courseDocs.docs) {
        await doc.reference.delete();
      }

      // Step 2: Delete the semester document
      await semesterRef.delete();

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

    final courseIndex = semesterCourses.indexWhere(
      (c) => c.courseId == courseId,
    );
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

  Map<String, List<StudentCourse>> get sortedCoursesBySemester {
    final List<String> semesterNames = _coursesBySemester.keys.toList();

    semesterNames.sort((a, b) {
      // Sort semesters by year and season
      final parsedA = parseSemester(
        a,
      ); //turns "Spring 2025" into {season: "Spring", year: 2025}
      final parsedB = parseSemester(b);

      final yearComparison = parsedA.year.compareTo(parsedB.year);
      if (yearComparison != 0) {
        return yearComparison;
      } // If years are different , sort by year

      return _seasonOrder(
        parsedA.season,
      ).compareTo(_seasonOrder(parsedB.season));
    });

    return {for (final name in semesterNames) name: _coursesBySemester[name]!};
  }

  // Get total credits for a semester
  double getTotalCreditsForSemester(String semesterKey) {
    final courses = _coursesBySemester[semesterKey] ?? [];
    double total = 0.0;

    for (final course in courses) {
      // Use stored credit points directly from the course model
      total += course.creditPoints;
    }

    return total;
  } // Get course with details (updated return type)

  StudentCourseWithDetails? getCourseWithDetails(
    String semesterKey,
    String courseId,
  ) {
    final courses = _coursesBySemester[semesterKey];
    if (courses == null) return null;

    StudentCourse? studentCourse;
    try {
      studentCourse = courses.firstWhere(
        (course) => course.courseId == courseId,
      );
    } catch (e) {
      return null;
    } // Create a basic course details object using stored credit points
    final courseDetails = EnhancedCourseDetails(
      courseNumber: studentCourse.courseId,
      name: studentCourse.name,
      syllabus: '',
      faculty: '',
      academicLevel: '',
      prerequisites: '',
      adjacentCourses: '',
      noAdditionalCredit: '',
      points:
          studentCourse.creditPoints
              .toString(), // Convert credit points to string format
      responsible: '',
      notes: '',
      exams: {},
      schedule: [],
    );

    return StudentCourseWithDetails(
      studentCourse: studentCourse,
      courseDetails: courseDetails,
    );
  }

  static ({String season, int year}) parseSemester(String semesterName) {
    final parts = semesterName.split(' ');
    final season = parts[0];
    final yearPart = parts.length > 1 ? parts[1] : '';

    int year;
    if (yearPart.contains('-')) {
      final years = yearPart.split('-');
      year = int.tryParse(years.last) ?? 0; // Use the later year for sorting
    } else {
      year = int.tryParse(yearPart) ?? 0;
    }

    return (season: season, year: year);
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

  // Search for courses in the current semester
  Future<List<CourseSearchResult>> searchCourses({
    String? courseId,
    String? courseName,
    String? faculty,
     String? selectedSemester,
    int pastSemestersToInclude = 0,
  }) async {

     if (selectedSemester != null) {
    final parsed = _parseSemesterCode(selectedSemester);
    if (parsed == null) {
      debugPrint('❌ Invalid selectedSemester format: $selectedSemester');
      return [];
    }
    final (year, semesterCode) = parsed;
    return await CourseService.searchCourses(
      year: year,
      semester: semesterCode,
      courseId: courseId,
      courseName: courseName,
      faculty: faculty,
    );
  }
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
      final allSemesters = await GlobalConfigService.getAvailableSemesters();
      debugPrint('📅 All semesters fetched:');
      for (var s in allSemesters) {
        debugPrint('  ${parseSemester(s).season} ${parseSemester(s).year}');
      }
      // ✅ Sort them based on custom order (Winter < Spring < Summer)
      allSemesters.sort((a, b) {
        final parsedA = parseSemester(a);
        final parsedB = parseSemester(b);

        final yearCompare = parsedA.year.compareTo(parsedB.year);
        if (yearCompare != 0) return yearCompare;

        // Season order: Winter < Spring < Summer
        final seasonOrder = {'Winter': 0, 'Spring': 1, 'Summer': 2};
        return seasonOrder[parsedA.season]!.compareTo(
          seasonOrder[parsedB.season]!,
        );
      });

      debugPrint('📅 Sorted semesters:');
      for (var s in allSemesters) {
        debugPrint('  ${parseSemester(s).season} ${parseSemester(s).year}');
      }

      debugPrint(
        '🎯 Current semester: ${_currentSemester!.semester} ${_currentSemester!.year}',
      );

      // ✅ Find the current semester index
      final currentIndex = allSemesters.indexWhere((s) {
        final parsed = _parseSemesterCode(s);
        if (parsed == null) return false;
        final (year, code) = parsed;
        debugPrint(
          '🔍 Checking semester: $s (year: $year, code: $code)',
        );
        return year == _currentSemester!.year &&
            code == _currentSemester!.semester;
      });

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
        debugPrint('  ${parseSemester(s).season} ${parseSemester(s).year}');
      }
      final Map<String, CourseSearchResult> resultMap = {};

      for (final sem in selectedSemesters) {
        final parsed = _parseSemesterCode(sem);
        if (parsed == null) {
          debugPrint('❌ Invalid semester format: $sem');
          continue;
        }
        final (year, semesterCode) = parsed;
        final res = await CourseService.searchCourses(
          year: year,
          semester: semesterCode,
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

  StudentCourse? getCourseById(String semester, String courseId) {
    final semCourses = _coursesBySemester[semester];
    if (semCourses == null) return null;

    try {
      return semCourses.firstWhere((c) => c.courseId == courseId);
    } catch (_) {
      return null; // course not found
    }
  }

  List<String> getMissingPrerequisites(
    String semesterKey,
    List<List<String>> prereqGroups,
  ) {
    final sortedKeys = sortedCoursesBySemester.keys.toList();
    final currentIndex = sortedKeys.indexOf(semesterKey);
    if (currentIndex == -1) {
      // If semester is unknown, assume nothing taken
      return prereqGroups.expand((g) => g).toSet().toList();
    }

    final previousKeys = sortedKeys.sublist(0, currentIndex);

    final takenCourseIds = <String>{
      for (final sem in previousKeys)
        ..._coursesBySemester[sem]!.map((c) => c.courseId),
    };

    // If ANY group is fully satisfied, return empty list (no missing)
    for (final group in prereqGroups) {
      if (group.every((id) => takenCourseIds.contains(id))) {
        return []; // At least one group satisfied
      }
    }

    // Otherwise, return all missing IDs from all groups
    final missing = <String>{
      for (final group in prereqGroups)
        ...group.where((id) => !takenCourseIds.contains(id)),
    };

    return missing.toList();
  }

  // Migration method to add credit points to existing courses
  Future<bool> migrateCreditPointsForExistingCourses(String studentId) async {
    debugPrint('🔄 Starting credit points migration for existing courses...');

    try {
      bool hasUpdates = false;

      for (final entry in _coursesBySemester.entries) {
        final semesterKey = entry.key;
        final courses = entry.value;

        for (int i = 0; i < courses.length; i++) {
          final course = courses[i];

          // Check if course already has credit points stored
          if (course.creditPoints > 0) {
            debugPrint(
              '✅ Course ${course.courseId} already has credit points: ${course.creditPoints}',
            );
            continue;
          }

          debugPrint(
            '🔍 Migrating credit points for course: ${course.courseId}',
          );

          // Fetch credit points from course details
          double creditPoints = 3.0; // Default fallback
          try {
            final courseDetails = await CourseService.getCourseDetails(
              _currentSemester?.year ?? 2024,
              _currentSemester?.semester ?? 200,
              course.courseId,
            );

            if (courseDetails != null && courseDetails.creditPoints > 0) {
              creditPoints = courseDetails.creditPoints;
              debugPrint(
                '📚 Found credit points for ${course.courseId}: $creditPoints',
              );
            } else {
              debugPrint(
                '⚠️ No credit points found for ${course.courseId}, using default: $creditPoints',
              );
            }
          } catch (e) {
            debugPrint(
              '❌ Error fetching credit points for ${course.courseId}: $e',
            );
          }

          // Update course with credit points
          final updatedCourse = course.copyWith(creditPoints: creditPoints);
          courses[i] = updatedCourse;

          // Update in Firestore
          try {
            await FirebaseFirestore.instance
                .collection('Students')
                .doc(studentId)
                .collection('Courses-per-Semesters')
                .doc(semesterKey)
                .collection('Courses')
                .doc(course.courseId)
                .update({'Credit_points': creditPoints});

            debugPrint(
              '✅ Updated credit points for ${course.courseId} in Firestore',
            );
            hasUpdates = true;
          } catch (e) {
            debugPrint(
              '❌ Failed to update ${course.courseId} in Firestore: $e',
            );
          }
        }
      }

      if (hasUpdates) {
        notifyListeners();
        debugPrint('🎉 Credit points migration completed successfully!');
      } else {
        debugPrint('ℹ️ No courses needed migration');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Credit points migration failed: $e');
      return false;
    }
  }

  List<List<String>> parseRawPrerequisites(String rawPrereqs) {
    final parsed = <List<String>>[];
    final orGroups = rawPrereqs.split(RegExp(r'\s*או\s*'));
    for (final group in orGroups) {
      final andGroup =
          group
              .replaceAll(RegExp(r'[^\d\s]'), '')
              .trim()
              .split(RegExp(r'\s+'))
              .where((id) => RegExp(r'^\d{8}$').hasMatch(id))
              .toList();
      if (andGroup.isNotEmpty) parsed.add(andGroup);
    }
    return parsed;
  }

Future<String> getClosestAvailableSemester(String requestedSemester) async {
  final available = await GlobalConfigService.getAvailableSemesters();

  if (available.contains(requestedSemester)) {
    return requestedSemester;
  }

  final requested = parseSemester(requestedSemester);

  // Filter semesters with the same season
  final sameSeason = available.where((s) => parseSemester(s).season == requested.season).toList();

  if (sameSeason.isEmpty) {
    return available.last; // Fallback if no season match
  }

  // Sort by absolute year difference
  sameSeason.sort((a, b) {
    final yearA = parseSemester(a).year;
    final yearB = parseSemester(b).year;
    return (yearA - requested.year).abs().compareTo(
      (yearB - requested.year).abs(),
    );
  });

  return sameSeason.first;
}



}
