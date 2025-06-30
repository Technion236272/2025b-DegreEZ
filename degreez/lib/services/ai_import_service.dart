// lib/services/ai_import_service.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_import_models.dart';
import '../models/student_model.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';
import '../services/course_service.dart';
import '../constants/introductory_courses.dart';
import 'diagram_ai_agent.dart';

/// Service class to handle AI-powered course import functionality
/// Separates the business logic from UI components
class AiImportService {
  /// Processes AI import and returns summary of results
  static Future<ImportSummary> processAiImport(BuildContext context) async {
    try {
      // Initialize AI Agent
      final aiAgent = DiagramAiAgent();
      
      // Process grade sheet through AI
      final courseData = await aiAgent.processGradeSheet();
      
      if (courseData == null) {
        // User cancelled the import
        return ImportSummary(
          totalCourses: 0,
          successfullyAdded: 0,
          successfullyUpdated: 0,
          failed: 0,
          semestersAdded: 0,
          results: [],
        );
      }
      
      // Get extracted courses
      final courses = aiAgent.getCoursesForApp();
      
      // Add courses to user's account
      return await _addCoursesToUser(context, courses);
      
    } catch (e) {
      // Return failed summary
      return ImportSummary(
        totalCourses: 0,
        successfullyAdded: 0,
        successfullyUpdated: 0,
        failed: 1,
        semestersAdded: 0,
        results: [
          CourseAdditionResult(
            semesterName: 'Error',
            courseId: 'N/A',
            courseName: 'Import Process',
            isSuccess: false,
            errorMessage: e.toString(),
          ),
        ],
      );
    }
  }

  /// Internal method to add AI-imported courses to user's account
  static Future<ImportSummary> _addCoursesToUser(
    BuildContext context, 
    List<Map<String, dynamic>> courses
  ) async {
    final List<CourseAdditionResult> results = [];
    
    if (courses.isEmpty) {
      return ImportSummary(
        totalCourses: 0,
        successfullyAdded: 0,
        successfullyUpdated: 0,
        failed: 0,
        semestersAdded: 0,
        results: [],
      );
    }
    
    try {
      final courseProvider = context.read<CourseProvider>();
      final studentProvider = context.read<StudentProvider>();
      final studentId = studentProvider.student?.id;
      
      if (studentId == null) {
        return ImportSummary(
          totalCourses: courses.length,
          successfullyAdded: 0,
          successfullyUpdated: 0,
          failed: courses.length,
          semestersAdded: 0,
          results: courses.map((course) => CourseAdditionResult(
            semesterName: 'Unknown',
            courseId: course['courseId'] as String? ?? 'Unknown',
            courseName: course['Name'] as String? ?? 'Unknown Course',
            isSuccess: false,
            errorMessage: 'Student ID not found',
          )).toList(),
        );
      }

      // Group courses by semester/year
      final coursesBySemester = _groupCoursesBySemester(courses);

      int totalCoursesAdded = 0;
      int totalCoursesUpdated = 0;
      int totalSemestersAdded = 0;

      // Process each semester
      for (final entry in coursesBySemester.entries) {
        final semesterName = entry.key;
        final semesterCourses = entry.value;
        
        // Handle semester creation
        final semesterResult = await _handleSemesterCreation(
          courseProvider, studentId, semesterName
        );
        
        if (semesterResult.wasCreated) {
          totalSemestersAdded++;
        }
        
        if (!semesterResult.exists) {
          // Add failed results for all courses in this semester
          for (final courseData in semesterCourses) {
            results.add(CourseAdditionResult(
              semesterName: semesterName,
              courseId: courseData['courseId'] as String? ?? 'Unknown',
              courseName: courseData['Name'] as String? ?? 'Unknown Course',
              isSuccess: false,
              errorMessage: 'Failed to create semester',
            ));
          }
          continue;
        }
        // Process courses in this semester
        final semesterResults = await _processSemesterCourses(
          context, courseProvider, studentId, semesterName, semesterCourses
        );
        
        results.addAll(semesterResults.results);
        totalCoursesAdded += semesterResults.added;
        totalCoursesUpdated += semesterResults.updated;
      }

      // Create and return summary
      return ImportSummary(
        totalCourses: courses.length,
        successfullyAdded: totalCoursesAdded,
        successfullyUpdated: totalCoursesUpdated,
        failed: results.where((r) => !r.isSuccess).length,
        semestersAdded: totalSemestersAdded,
        results: results,
      );
      
    } catch (e) {
      return ImportSummary(
        totalCourses: courses.length,
        successfullyAdded: 0,
        successfullyUpdated: 0,
        failed: courses.length,
        semestersAdded: 0,
        results: courses.map((course) => CourseAdditionResult(
          semesterName: 'Error',
          courseId: course['courseId'] as String? ?? 'Unknown',
          courseName: course['Name'] as String? ?? 'Unknown Course',
          isSuccess: false,
          errorMessage: e.toString(),
        )).toList(),
      );
    }
  }

  /// Groups courses by semester for processing
  static Map<String, List<Map<String, dynamic>>> _groupCoursesBySemester(
    List<Map<String, dynamic>> courses
  ) {
    final Map<String, List<Map<String, dynamic>>> coursesBySemester = {};
    
    for (final course in courses) {
      final semester = course['Semester'] as String? ?? 'Unknown';
      final year = course['Year'] as String? ?? 'Unknown';
      
      // Extract the right year from "YYYY-YYYY" format (e.g., "2024-2025" -> "2025")
      final rightYear = year.contains('-') ? year.split('-').last.trim() : year;
      final semesterKey = (semester == "Winter") ? '$semester $year' : '$semester $rightYear';

      coursesBySemester.putIfAbsent(semesterKey, () => []);
      coursesBySemester[semesterKey]!.add(course);
    }
    
    return coursesBySemester;
  }

  /// Handles semester creation if needed
  static Future<SemesterCreationResult> _handleSemesterCreation(
    CourseProvider courseProvider, 
    String studentId, 
    String semesterName
  ) async {
    final semesterExists = courseProvider.sortedCoursesBySemester.containsKey(semesterName);
    
    if (!semesterExists) {
      final success = await courseProvider.addSemester(studentId, semesterName);
      return SemesterCreationResult(
        exists: success,
        wasCreated: success,
      );
    }
    
    return SemesterCreationResult(
      exists: true,
      wasCreated: false,
    );
  }

  /// Processes all courses for a specific semester
  static Future<SemesterProcessingResult> _processSemesterCourses(
    BuildContext context,
    CourseProvider courseProvider,
    String studentId,
    String semesterName,
    List<Map<String, dynamic>> semesterCourses,
  ) async {
    final List<CourseAdditionResult> results = [];
    int added = 0;
    int updated = 0;

    for (final courseData in semesterCourses) {
      final courseResult = await _processSingleCourse(
        context, courseProvider, studentId, semesterName, courseData
      );
      
      results.add(courseResult);
      
      if (courseResult.isSuccess) {
        if (courseResult.wasUpdated) {
          updated++;
        } else {
          added++;
        }
      }
    }

    return SemesterProcessingResult(
      results: results,
      added: added,
      updated: updated,
    );
  }

  /// Processes a single course addition/update
  static Future<CourseAdditionResult> _processSingleCourse(
    BuildContext context,
    CourseProvider courseProvider,
    String studentId,
    String semesterName,
    Map<String, dynamic> courseData,
  ) async {
    final courseId = courseData['courseId'] as String? ?? '';
    final courseName = courseData['Name'] as String? ?? 'Unknown Course';
    final grade = courseData['Final_grade'] as String? ?? '';

    // Check if course already exists in this semester
    final existingCourses = courseProvider.getCoursesForSemester(semesterName);
    final courseExists = existingCourses.any((c) => c.courseId == courseId);
    
    if (courseExists) {
      return await _updateExistingCourse(
        courseProvider, studentId, semesterName, courseId, courseName, grade
      );
    } else {
      return await _addNewCourse(
        context, courseProvider, studentId, semesterName, courseData
      );
    }
  }

  /// Updates an existing course's grade
  static Future<CourseAdditionResult> _updateExistingCourse(
    CourseProvider courseProvider,
    String studentId,
    String semesterName,
    String courseId,
    String courseName,
    String grade,
  ) async {
    if (grade.isNotEmpty) {
      final success = await courseProvider.updateCourseGrade(
        studentId, semesterName, courseId, grade
      );
      
      return CourseAdditionResult(
        semesterName: semesterName,
        courseId: courseId,
        courseName: courseName,
        isSuccess: success,
        wasUpdated: true,
        errorMessage: success ? null : 'Failed to update grade',
      );
    } else {
      return CourseAdditionResult(
        semesterName: semesterName,
        courseId: courseId,
        courseName: courseName,
        isSuccess: true,
        wasUpdated: true,
        errorMessage: 'Course already exists (no grade to update)',
      );
    }
  }

  /// Adds a new course to the semester
  static Future<CourseAdditionResult> _addNewCourse(
    BuildContext context,
    CourseProvider courseProvider,
    String studentId,
    String semesterName,
    Map<String, dynamic> courseData,
  ) async {
    final courseId = courseData['courseId'] as String? ?? '';
    final courseName = courseData['Name'] as String? ?? 'Unknown Course';
    final grade = courseData['Final_grade'] as String? ?? '';

    // Search for course details
    final fallbackSemester = await courseProvider.getClosestAvailableSemester(semesterName);
    final searchResults = await courseProvider.searchCourses(
      courseId: courseId,
      selectedSemester: fallbackSemester,
    );
    
    // Find the course in search results
    EnhancedCourseDetails? courseDetails;
    for (final result in searchResults) {
      if (result.course.courseNumber == courseId) {
        courseDetails = result.course;
        break;
      }
    }
    
    if (courseDetails != null) {
      // Create StudentCourse from EnhancedCourseDetails
      final course = StudentCourse(
        courseId: courseDetails.courseNumber,
        name: courseDetails.name,
        finalGrade: grade,
        lectureTime: '',
        tutorialTime: '',
        labTime: '',
        workshopTime: '',
        creditPoints: courseDetails.creditPoints,
      );

      // Add course to semester
      
      final success = await courseProvider.addCourseToSemester(
        studentId, semesterName, course,fallbackSemester
      );
      
      return CourseAdditionResult(
        semesterName: semesterName,
        courseId: courseId,
        courseName: courseName,
        isSuccess: success,
        errorMessage: success ? null : 'Failed to add course to semester',
      );
    } else {
      // Check if this is an introductory course (prerequisite before Technion)
      if (IntroductoryCourses.isIntroductoryCourse(courseId)) {
        final introData = IntroductoryCourses.getIntroductoryCourseData(courseId)!;
        
        // Create StudentCourse from introductory course data
        final course = StudentCourse(
          courseId: introData.courseId,
          name: introData.name,
          finalGrade: grade.isNotEmpty ? grade : 'Exemption without points',
          lectureTime: '',
          tutorialTime: '',
          labTime: '',
          workshopTime: '',
          creditPoints: introData.creditPoints,
        );

        // Add introductory course to the semester using hardcoded data
        final success = await courseProvider.addCourseToSemester(
          studentId, semesterName, course, fallbackSemester
        );
        
        return CourseAdditionResult(
          semesterName: semesterName,
          courseId: courseId,
          courseName: courseName,
          isSuccess: success,
          errorMessage: success ? null : 'Failed to add introductory course to semester',
        );
      } else {
        return CourseAdditionResult(
          semesterName: semesterName,
          courseId: courseId,
          courseName: courseName,
          isSuccess: false,
          errorMessage: 'Course not found in course catalog',
        );
      }
    }
  }
}

/// Helper class for semester creation results
class SemesterCreationResult {
  final bool exists;
  final bool wasCreated;

  SemesterCreationResult({
    required this.exists,
    required this.wasCreated,
  });
}

/// Helper class for semester processing results
class SemesterProcessingResult {
  final List<CourseAdditionResult> results;
  final int added;
  final int updated;

  SemesterProcessingResult({
    required this.results,
    required this.added,
    required this.updated,
  });
}
