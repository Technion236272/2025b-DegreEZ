// lib/models/course_recommendation_models.dart

/// Model for course recommendation request
class CourseRecommendationRequest {
  final int year;
  final int semester;
  final String? catalogFilePath;
  final String userContext;
  final DateTime requestTime;
   final String semesterDisplayName;

  CourseRecommendationRequest({
    required this.year,
    required this.semester,
    this.catalogFilePath,
    required this.userContext,
    required this.requestTime,
    required this.semesterDisplayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'semester': semester,
      'catalogFilePath': catalogFilePath,
      'userContext': userContext,
      'requestTime': requestTime.toIso8601String(),
      'semesterDisplayName': semesterDisplayName,
    };
  }

    factory CourseRecommendationRequest.fromJson(Map<String, dynamic> json) {
    return CourseRecommendationRequest(
      year: json['year'],
      semester: json['semester'],
      catalogFilePath: json['catalogFilePath'],
      userContext: json['userContext'],
      requestTime: DateTime.parse(json['requestTime']),
      semesterDisplayName: json['semesterDisplayName'],
    );
  }

}

/// Model for candidate courses identified by AI
class CandidateCourses {
  final Map<String, String> courses; // courseId -> courseName
  final String reasoning;

  CandidateCourses({
    required this.courses,
    required this.reasoning,
  });

  factory CandidateCourses.fromJson(Map<String, dynamic> json) {
    return CandidateCourses(
      courses: Map<String, String>.from(json['courses'] ?? {}),
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courses': courses,
      'reasoning': reasoning,
    };
  }
}

/// Model for detailed course information used in recommendations
class CourseRecommendationDetails {
  final String courseId;
  final String courseName;
  final double creditPoints;
  final String prerequisites;
  final String description;
  final List<String> schedule;
  final String faculty;
  final bool isAvailable;

  CourseRecommendationDetails({
    required this.courseId,
    required this.courseName,
    required this.creditPoints,
    required this.prerequisites,
    required this.description,
    required this.schedule,
    required this.faculty,
    this.isAvailable = true,
  });

  factory CourseRecommendationDetails.fromCourseService(
    dynamic enhancedCourseDetails,
  ) {
    return CourseRecommendationDetails(
      courseId: enhancedCourseDetails.courseNumber,
      courseName: enhancedCourseDetails.name,
      creditPoints: double.tryParse(enhancedCourseDetails.points) ?? 3.0,
      prerequisites: enhancedCourseDetails.prerequisites,
      description: enhancedCourseDetails.syllabus,
      schedule: enhancedCourseDetails.schedule
          .map<String>((s) => '${s.day} ${s.time}')
          .toList(),
      faculty: enhancedCourseDetails.faculty,
      isAvailable: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'creditPoints': creditPoints,
      'prerequisites': prerequisites,
      'description': description,
      'schedule': schedule,
      'faculty': faculty,
      'isAvailable': isAvailable,
    };
  }
}

/// Model for final course recommendation
class CourseRecommendation {
  final String courseId;
  final String courseName;
  final double creditPoints;
  final String reason;
  final int priority; // 1 = highest priority
  final String category; // e.g., "Core", "Elective", "Prerequisites"

  CourseRecommendation({
    required this.courseId,
    required this.courseName,
    required this.creditPoints,
    required this.reason,
    required this.priority,
    required this.category,
  });

  factory CourseRecommendation.fromJson(Map<String, dynamic> json) {
    return CourseRecommendation(
      courseId: json['courseId'],
      courseName: json['courseName'],
      creditPoints: (json['creditPoints'] as num).toDouble(),
      reason: json['reason'],
      priority: json['priority'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'creditPoints': creditPoints,
      'reason': reason,
      'priority': priority,
      'category': category,
    };
  }
}

/// Model for complete recommendation response
class CourseRecommendationResponse {
  final List<CourseRecommendation> recommendations;
  final double totalCreditPoints;
  final String summary;
  final String reasoning;
  final DateTime generatedAt;
  final CourseRecommendationRequest originalRequest;

  CourseRecommendationResponse({
    required this.recommendations,
    required this.totalCreditPoints,
    required this.summary,
    required this.reasoning,
    required this.generatedAt,
    required this.originalRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'totalCreditPoints': totalCreditPoints,
      'summary': summary,
      'reasoning': reasoning,
      'generatedAt': generatedAt.toIso8601String(),
      'originalRequest': originalRequest.toJson(),
    };
  }

    factory CourseRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return CourseRecommendationResponse(
      recommendations: (json['recommendations'] as List)
          .map((r) => CourseRecommendation.fromJson(r))
          .toList(),
      totalCreditPoints: (json['totalCreditPoints'] as num).toDouble(),
      summary: json['summary'] as String,
      reasoning: json['reasoning'] as String,
      generatedAt: DateTime.parse(json['generatedAt']),
      originalRequest: CourseRecommendationRequest.fromJson(
        json['originalRequest'],
      ),
    );
  }

}