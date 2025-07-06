import 'package:flutter/foundation.dart';
import '../course_service.dart';
import '../../models/course_recommendation_models.dart';
import '../../providers/course_provider.dart';

/// Service for validating course candidates before optimization
/// 
/// This service implements course validation by:
/// 1. Fetching student course information from CourseProvider
/// 2. Filtering candidate courses based on completion status, prerequisites, and parallel courses
/// 3. Using CourseProvider.getMissingPrerequisites() for accurate prerequisite validation
/// 
/// The service uses the same prerequisite checking logic as the add course widget,
/// ensuring consistent behavior throughout the application.
class CandidateValidationService {
  final CourseProvider courseProvider;
  
  CandidateValidationService(this.courseProvider);
  
  /// Get all valid course candidates for the target semester
  Future<List<dynamic>> getValidCandidates(
    CourseRecommendationRequest request,
  ) async {
    debugPrint('🔍 Starting candidate validation for semester: ${request.semesterDisplayName}');
    
    // Step 1: Fetch all courses from target semester
    final allCourses = await _fetchCoursesFromTargetSemester(request.semesterDisplayName);
    debugPrint('📚 Found ${allCourses.length} courses in target semester');
    
    // Step 2: Get student's academic history
    final studentCourses = await _fetchStudentCourses(request.userContext);
    debugPrint('🎓 Found ${studentCourses.length} courses in student history');
    
    // Step 3: Filter courses based on student's academic status
    final validCourses = await _filterCourses(allCourses, studentCourses, request.semesterDisplayName);
    debugPrint('✅ Filtered to ${validCourses.length} valid candidates');
    
    // step 4: minimize the valid courses' size by cutting unnecessary data about them
    // we keep general -> courseId, faculty, creditPoints, syllabus
    _minimizeCourseData(validCourses);

    return validCourses;
  }
  
  /// Fetch all courses available in the target semester
  Future<List<dynamic>> _fetchCoursesFromTargetSemester(
    String semesterDisplayName,
  ) async {
    try {
      // Parse target semester
      final fallbackSemester = await CourseProvider()
          .getClosestAvailableSemester(semesterDisplayName);
      final parsed = CourseProvider().parseSemesterCode(fallbackSemester);
      
      if (parsed == null) {
        throw Exception('Could not parse semester: $semesterDisplayName');
      }
      
      final (apiYear, semesterCode) = parsed;
      
      // Fetch all courses from the semester
      final allCourses = await CourseService.getAllCourses(apiYear, semesterCode);
      
      // Return courses as-is since we'll minimize the data later
      return allCourses;
      
    } catch (e) {
      debugPrint('❌ Error fetching courses from target semester: $e');
      rethrow;
    }
  }
  
  /// Fetch student's completed courses from CourseProvider
  Future<List<dynamic>> _fetchStudentCourses(String userContext) async {
    try {
      debugPrint('📝 Fetching student courses from CourseProvider');
      
      // Use the provided CourseProvider instance instead of creating a new one
      final allCourses = courseProvider.coursesBySemester;
      debugPrint('📊 CourseProvider has ${allCourses.length} semesters with courses');
      
      // flatten all courses into a single list regardless of semester
      final flattenedCourses = allCourses.values.expand((courses) => courses).toList();
      debugPrint('📚 Total courses found: ${flattenedCourses.length}');
      
      // Convert StudentCourse objects to maps for bracket notation access
      final coursesAsMaps = flattenedCourses.map((course) => {
        'courseId': course.courseId,
        'finalGrade': course.finalGrade,
        'name': course.name,
        'creditPoints': course.creditPoints,
      }).toList();
      
      return coursesAsMaps;

    } catch (e) {
      debugPrint('❌ Error fetching student courses: $e');
      return [];
    }
  }
    
  /// Filter courses based on student's academic history
  Future<List<dynamic>> _filterCourses(
    List<dynamic> allCourses,
    List<dynamic> studentCourses,
    String semesterDisplayName,
  ) async {
    final validCourses = <dynamic>[];
    
    for (final course in allCourses) {
      final courseId = course['general']?['מספר מקצוע']?.toString() ?? '';
      
      // Skip if course ID is empty
      if (courseId.isEmpty) continue;

      if(courseId == "02340236") {
        // Special case handling for course 02340236
        debugPrint('🔍 Special handling for course: $courseId');
        // Implement any specific logic for this course here
      }

      // Filter A: Remove if course is already completed
      // implemented as a separate method
      if (await _isCourseCompleted(course, studentCourses)) {
        debugPrint('🚫 Skipping completed course: $courseId');
        continue;
      }
      
      // Filter B: Remove if prerequisites are missing
      // implemented as a separate method
      if (!await _hasRequiredPrerequisites(course, studentCourses, semesterDisplayName)) {
        debugPrint('🚫 Skipping course with missing prerequisites: $courseId');
        continue;
      }
      
      // Filter C: Remove if course is parallel to a taken course
      if (await _isParallelToTakenCourse(course, studentCourses)) {
        debugPrint('🚫 Skipping parallel course: $courseId');
        continue;
      }
      
      // Course passed all filters - add to valid candidates
      validCourses.add(course);
    }
    final courseCount = validCourses.length;
    debugPrint('📚 Total valid courses found: $courseCount');
    return validCourses;
  }
  
  /// Check if student has already completed this course
  Future<bool> _isCourseCompleted(
    dynamic course,
    List<dynamic> studentCourses,
  ) async {
    final courseId = course['general']?['מספר מקצוע']?.toString() ?? '';
    debugPrint('🔍 Checking if course $courseId is completed');
    // Check if course ID is in studentCourses
    for (final studentCourse in studentCourses) {
      if (studentCourse['courseId'] == courseId &&
          studentCourse['finalGrade'] != null &&
          double.tryParse(studentCourse['finalGrade']) != null &&
          double.parse(studentCourse['finalGrade']) >= 60.0) {
        debugPrint('✅ Course $courseId is completed with passing grade');
        return true; // Course is completed with passing grade
      }
    }
    return false;
  }
  
  /// Check if student has required prerequisites for this course
  /// Uses CourseProvider.getMissingPrerequisites() like the add course widget
  Future<bool> _hasRequiredPrerequisites(
    dynamic course,
    List<dynamic> studentCourses,
    String semesterDisplayName,
  ) async {
    final courseId = course['general']?['מספר מקצוע']?.toString() ?? '';
    final rawPrereqs = course['general']?['מקצועות קדם']?.toString() ?? '';
    
    debugPrint('🔍 Checking prerequisites for course $courseId');
    
    // If no prerequisites, course is available
    if (rawPrereqs.isEmpty) {
      debugPrint('✅ No prerequisites required for $courseId');
      return true;
    }
    
    try {
      // Parse prerequisites using the same logic as add course widget
      final parsedPrereqs = <List<String>>[];
      final orGroups = rawPrereqs.split(RegExp(r'\s*או\s*'));

      for (final group in orGroups) {
        final andGroup = group
            .replaceAll(RegExp(r'[^\d\s]'), '')
            .trim()
            .split(RegExp(r'\s+'))
            .where((id) => RegExp(r'^\d{8}$').hasMatch(id))
            .toList();

        if (andGroup.isNotEmpty) parsedPrereqs.add(andGroup);
      }
      
      if (parsedPrereqs.isEmpty) {
        debugPrint('✅ No valid prerequisite groups found for $courseId');
        return true;
      }
      
      // Check if student has missing prerequisites using CourseProvider
      final missingPrereqs = courseProvider.getMissingPrerequisites(
        semesterDisplayName,
        parsedPrereqs,
      );
      
      final hasAllPrereqs = missingPrereqs.isEmpty;
      debugPrint(
        hasAllPrereqs 
          ? '✅ All prerequisites satisfied for $courseId'
          : '❌ Missing prerequisites for $courseId: ${missingPrereqs.join(', ')}'
      );
      
      return hasAllPrereqs;
      
    } catch (e) {
      debugPrint('⚠️ Error checking prerequisites for $courseId: $e');
      return false; // If error, assume prerequisites not met
    }
  }
  
  /// Check if course is parallel to a course already taken by student
  Future<bool> _isParallelToTakenCourse(
    dynamic course,
    List<dynamic> studentCourses,
  ) async {
    final courseId = course['general']?['מספר מקצוע']?.toString() ?? '';
    debugPrint('🔍 Checking if course $courseId is parallel to taken courses');
    
    try {
      // Get the parallel courses list from the course document
      final parallelCourses = course['general']?['מקצועות ללא זיכוי נוסף'];
      
      if (parallelCourses == null) {
        debugPrint('✅ No parallel courses found for $courseId');
        return false;
      }
      
      // Convert to list of strings
      List<String> parallelCourseIds = [];
      if (parallelCourses is String) {
        // If it's a string, split by common delimiters
        parallelCourseIds = parallelCourses
            .split(RegExp(r'[,\s]+'))
            .where((id) => id.isNotEmpty)
            .map((id) => id.trim())
            .toList();
      } else if (parallelCourses is List) {
        // If it's already a list, convert to strings
        parallelCourseIds = parallelCourses
            .map((item) => item.toString().trim())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      
      if (parallelCourseIds.isEmpty) {
        debugPrint('✅ No valid parallel course IDs found for $courseId');
        return false;
      }
      
      debugPrint('📋 Found ${parallelCourseIds.length} parallel courses for $courseId: ${parallelCourseIds.join(', ')}');
      
      // Check if any of the parallel courses are completed by the student
      for (final parallelCourseId in parallelCourseIds) {
        // Create a dummy course object to check if it's completed
        final dummyCourse = {
          'general': {
            'מספר מקצוע': parallelCourseId,
          }
        };
        
        if (await _isCourseCompleted(dummyCourse, studentCourses)) {
          debugPrint('🚫 Found completed parallel course: $parallelCourseId for course $courseId');
          return true;
        }
      }
      
      debugPrint('✅ No parallel courses are completed for $courseId');
      return false;
      
    } catch (e) {
      debugPrint('⚠️ Error checking parallel courses for $courseId: $e');
      return false; // If error, assume no parallel courses
    }
  }
  
  /// Minimize course data by removing unnecessary fields and keeping only essential fields in general
  void _minimizeCourseData(List<dynamic> courses) {
    for (var course in courses) {
      course.remove('schedule');
      course.remove('metadata');
      
      // Keep only specific fields in the general object
      if (course['general'] is Map<String, dynamic>) {
        final general = course['general'] as Map<String, dynamic>;
        final filteredGeneral = <String, dynamic>{};
        
        // Keep only the fields you need
        if (general.containsKey('מספר מקצוע')) {
          filteredGeneral['מספר מקצוע'] = general['מספר מקצוע'];
        }
        if (general.containsKey('פקולטה')) {
          filteredGeneral['פקולטה'] = general['פקולטה'];
        }
        if (general.containsKey('נקודות זכות')) {
          filteredGeneral['נקודות זכות'] = general['נקודות זכות'];
        }
        if (general.containsKey('סילבוס')) {
          filteredGeneral['סילבוס'] = general['סילבוס'];
        }
        if (general.containsKey('שם מקצוע')) {
          filteredGeneral['שם מקצוע'] = general['שם מקצוע'];
        }
        if (general.containsKey('נקודות')) {
          filteredGeneral['נקודות'] = general['נקודות'];
        }
        
        // Replace the general object with the filtered version
        course['general'] = filteredGeneral;
      }
    }
  }
}
