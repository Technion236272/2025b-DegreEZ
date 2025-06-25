// lib/constants/introductory_courses.dart

/// Constants for introductory/prerequisite courses that are completed before starting Technion
/// These are not actual Technion courses but are requirements for admission
class IntroductoryCourses {
  /// Set of introductory course IDs that students complete before Technion
  static const Set<String> introductoryCourseIds = {
    '01130013', // Introductory Physics 1
    '01130014', // Introductory Physics 2
    '01030015', // Introductory Mathematics 1
  };

  /// Map of introductory course details
  static const Map<String, IntroductoryCourseData> introductoryCoursesData = {
    '01130013': IntroductoryCourseData(
      courseId: '01130013',
      name: 'Introductory Physics 1',
      creditPoints: 0.0, // Usually no credit points for prerequisites
      defaultSemester: 'Pre-Technion',
      defaultYear: 'Preparation',
      isExemption: true,
    ),
    '01130014': IntroductoryCourseData(
      courseId: '01130014',
      name: 'Introductory Physics 2',
      creditPoints: 0.0, // Usually no credit points for prerequisites
      defaultSemester: 'Pre-Technion',
      defaultYear: 'Preparation',
      isExemption: true,
    ),
    '01030015': IntroductoryCourseData(
      courseId: '01030015',
      name: 'Introductory Mathematics 1',
      creditPoints: 0.0, // Usually no credit points for prerequisites
      defaultSemester: 'Pre-Technion',
      defaultYear: 'Preparation',
      isExemption: true,
    ),
  };

  /// Check if a course ID is an introductory course
  static bool isIntroductoryCourse(String courseId) {
    return introductoryCourseIds.contains(courseId);
  }

  /// Get introductory course data by ID
  static IntroductoryCourseData? getIntroductoryCourseData(String courseId) {
    return introductoryCoursesData[courseId];
  }

  /// Get all introductory courses as a list
  static List<IntroductoryCourseData> getAllIntroductoryCourses() {
    return introductoryCoursesData.values.toList();
  }
}

/// Data structure for introductory course information
class IntroductoryCourseData {
  final String courseId;
  final String name;
  final double creditPoints;
  final String defaultSemester;
  final String defaultYear;
  final bool isExemption;

  const IntroductoryCourseData({
    required this.courseId,
    required this.name,
    required this.creditPoints,
    required this.defaultSemester,
    required this.defaultYear,
    this.isExemption = true,
  });

  /// Convert to the format expected by the course data structure
  Map<String, dynamic> toImportFormat() {
    return {
      'courseId': courseId,
      'Name': name,
      'Credit_points': 0.0, // Usually no credit points for prerequisites
      'Final_grade': 'Exemption without points', // As shown in the image
      'Semester': defaultSemester,
      'Year': defaultYear,
    };
  }
}
