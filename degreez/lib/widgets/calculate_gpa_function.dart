import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:flutter/material.dart';

// Helper classes for GPA calculation
class GpaCalculationItem {
  final String name;
  final String courseId;
  final double grade;
  final double credits;
  final bool isWhatIf;
  final String semesterKey;
  final bool isExcluded;
  final bool isModified;

  GpaCalculationItem({
    required this.name,
    required this.courseId,
    required this.grade,
    required this.credits,
    this.isWhatIf = false,
    required this.semesterKey,
    this.isExcluded = false,
    this.isModified = false,
  });
}


class GpaCalculationResult {
  final double gpa;
  final double totalCredits;

  GpaCalculationResult({required this.gpa, required this.totalCredits});
}

GpaCalculationResult calculateAverage(List<GpaCalculationItem> courses) {
    debugPrint(
      'DEBUG: _calculateAverage called with ${courses.length} courses',
    );

    if (courses.isEmpty) {
      debugPrint('DEBUG: No courses provided to _calculateAverage');
      return GpaCalculationResult(gpa: 0.0, totalCredits: 0.0);
    }

    double totalPoints = 0.0;
    double totalCredits = 0.0;

    for (final course in courses) {
      debugPrint(
        'DEBUG: Processing ${course.name}: ${course.credits} credits, ${course.grade} grade',
      );
      // Use the grade as-is (percentage), weighted by credits
      final weightedPoints = course.grade * course.credits;
      totalPoints += weightedPoints;
      totalCredits += course.credits;

      debugPrint(
        'DEBUG: ${course.name} - grade: ${course.grade}, weightedPoints: $weightedPoints',
      );
      debugPrint(
        'DEBUG: Running totals - totalPoints: $totalPoints, totalCredits: $totalCredits',
      );
    }

    final gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;

    debugPrint(
      'DEBUG: Final calculation - totalPoints: $totalPoints, totalCredits: $totalCredits, gpa: $gpa',
    );

    // Round up to 1 decimal place (e.g., 87.61 -> 87.7, 86.63 -> 86.7)
    final roundedGpa = (gpa * 10).ceilToDouble() / 10;

    return GpaCalculationResult(gpa: roundedGpa, totalCredits: totalCredits);
  }

    List<GpaCalculationItem> getCompletedCourses(
    Map<String, List<StudentCourse>> coursesBySemester,
    CourseProvider courseProvider,
    {Set<String> excludedCourseIds = const {}}
  ) {
    final List<GpaCalculationItem> completedCourses = [];

    debugPrint('DEBUG: Starting _getCompletedCourses');
    debugPrint('DEBUG: coursesBySemester.length = ${coursesBySemester.length}');

    for (final entry in coursesBySemester.entries) {
      final semesterKey = entry.key;
      final semesterCourses = entry.value;

      debugPrint(
        'DEBUG: Processing semester $semesterKey with ${semesterCourses.length} courses',
      );

      for (final course in semesterCourses) {
        debugPrint(
          'DEBUG: Course ${course.name} - finalGrade: "${course.finalGrade}", creditPoints: ${course.creditPoints}',
        );

        // Skip excluded courses
        if (excludedCourseIds.contains(course.courseId)) {
          debugPrint('DEBUG: Skipping excluded course ${course.name}');
          continue;
        }

        // Check if the course has a numerical grade
        if (course.finalGrade.isNotEmpty) {
          final grade = double.tryParse(course.finalGrade);
          debugPrint('DEBUG: Parsed grade for ${course.name}: $grade');

          if (grade != null && grade >= 0 && grade <= 100) {
            // Use stored credit points directly from the course model
            final credits = course.creditPoints;

            debugPrint(
              'DEBUG: Adding course ${course.name} with grade $grade and credits $credits',
            );
            for (final completedCourse in completedCourses.toList())
            {
              if(course.name == completedCourse.name)
              {
                completedCourses.removeWhere((val){return val.name==course.name;});
              }

            }

            completedCourses.add(
              GpaCalculationItem(
                name: course.name,
                courseId: course.courseId,
                grade: grade,
                credits: credits,
                isWhatIf: false,
                semesterKey: semesterKey,
                isExcluded: false,
                isModified: false,
              ),
            );
          } else {
            debugPrint('DEBUG: Grade $grade not valid for ${course.name}');
          }
        } else {
          debugPrint('DEBUG: No finalGrade for ${course.name}');
        }
      }
    }

    debugPrint(
      'DEBUG: Total completed courses found: ${completedCourses.length}',
    );
    for (final course in completedCourses) {
      debugPrint(
        'DEBUG: Course ${course.name}: ${course.credits} credits, ${course.grade} grade',
      );
    }

    return completedCourses;
  }