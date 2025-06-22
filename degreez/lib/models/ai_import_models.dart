// lib/models/ai_import_models.dart

/// Data structure to track course addition results during AI import
class CourseAdditionResult {
  final String semesterName;
  final String courseId;
  final String courseName;
  final bool isSuccess;
  final String? errorMessage;
  final bool wasUpdated; // true if course existed and was updated, false if newly added

  CourseAdditionResult({
    required this.semesterName,
    required this.courseId,
    required this.courseName,
    required this.isSuccess,
    this.errorMessage,
    this.wasUpdated = false,
  });

  @override
  String toString() {
    return 'CourseAdditionResult(semesterName: $semesterName, courseId: $courseId, '
           'courseName: $courseName, isSuccess: $isSuccess, wasUpdated: $wasUpdated, '
           'errorMessage: $errorMessage)';
  }
}

/// Summary data structure for AI import process
class ImportSummary {
  final int totalCourses;
  final int successfullyAdded;
  final int successfullyUpdated;
  final int failed;
  final int semestersAdded;
  final List<CourseAdditionResult> results;

  ImportSummary({
    required this.totalCourses,
    required this.successfullyAdded,
    required this.successfullyUpdated,
    required this.failed,
    required this.semestersAdded,
    required this.results,
  });

  /// Total successful operations (added + updated)
  int get totalSuccess => successfullyAdded + successfullyUpdated;

  /// Check if import was completely successful
  bool get isCompleteSuccess => failed == 0 && totalCourses > 0;

  /// Check if import had partial success
  bool get hasPartialSuccess => totalSuccess > 0 && failed > 0;

  /// Check if import completely failed
  bool get isCompleteFailure => totalSuccess == 0 && totalCourses > 0;

  @override
  String toString() {
    return 'ImportSummary(totalCourses: $totalCourses, successfullyAdded: $successfullyAdded, '
           'successfullyUpdated: $successfullyUpdated, failed: $failed, semestersAdded: $semestersAdded)';
  }
}
