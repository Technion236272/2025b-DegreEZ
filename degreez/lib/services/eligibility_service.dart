import 'package:degreez/services/course_service.dart';
import 'package:degreez/models/student_model.dart';

class EligibilityService {
  /// Fetches all courses for a given semester and year.
  static Future<List<dynamic>> fetchCoursesForSemester(int year, int semester) async {
    return await CourseService.getAllCourses(year, semester);
  }

  static Future<List<dynamic>> fetchCoursesForSemesterFromFaculty(int year, int semester) async {
    
    // This method is currently not implemented.
    return [];
  }
  
  static List<List<String>> parseRawPrerequisites(String rawPrereqs) {
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

  /// Filters courses to only those for which the user has completed all prerequisites.
  /// [completedCourseIds] is a set of course IDs the user has completed (e.g., passed).
  static Future<List<dynamic>> filterEligibleCourses({
    required int year,
    required int semester,
    required Set<String> completedCourseIds,
  }) async {
    final courses = await fetchCoursesForSemester(year, semester);
    final eligibleCourses = <dynamic>[];

    for (final courseData in courses) {
      final courseId = courseData['general']?['מספר מקצוע'] ?? courseData['courseNumber'];
      final rawPrereqs = courseData['general']?['מקצועות קדם'] ?? '';
      final prereqGroups = parseRawPrerequisites(rawPrereqs);
      // If no prereqs, or any group is fully satisfied, keep the course
      if (prereqGroups.isEmpty || prereqGroups.any((group) => group.every((id) => completedCourseIds.contains(id)))) {
        eligibleCourses.add(courseData);
      }
    }
    return eligibleCourses;
  }
}
