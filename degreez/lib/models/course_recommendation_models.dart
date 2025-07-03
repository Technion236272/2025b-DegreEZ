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
}

/// Model for a single course in a set
class CourseInSet {
  final String courseId;
  final String courseName; // Hebrew name
  
  CourseInSet({
    required this.courseId,
    required this.courseName,
  });

  factory CourseInSet.fromJson(Map<String, dynamic> json) {
    return CourseInSet(
      courseId: json['id'] ?? json['courseId'] ?? '',
      courseName: json['name'] ?? json['courseName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': courseId,
      'name': courseName,
    };
  }
}

/// Model for a single course set (15-18 credits)
class CourseSet {
  final int setId;
  final List<CourseInSet> courses;
  final double totalCredits;
  final String reasoning;

  CourseSet({
    required this.setId,
    required this.courses,
    required this.totalCredits,
    required this.reasoning,
  });

  factory CourseSet.fromJson(Map<String, dynamic> json, int setId) {
    final coursesList = (json['courses'] as List?)
        ?.map((courseJson) => CourseInSet.fromJson(courseJson))
        .toList() ?? [];
    
    return CourseSet(
      setId: setId,
      courses: coursesList,
      totalCredits: (json['totalCredits'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'courses': courses.map((c) => c.toJson()).toList(),
      'totalCredits': totalCredits,
      'reasoning': reasoning,
    };
  }
}

/// Model for AI response containing 10 candidate course sets
class MultiSetCandidateResponse {
  final List<CourseSet> courseSets; // 10 sets
  final String overallReasoning;
  final DateTime generatedAt;

  MultiSetCandidateResponse({
    required this.courseSets,
    required this.overallReasoning,
    required this.generatedAt,
  });

  factory MultiSetCandidateResponse.fromJson(Map<String, dynamic> json) {
    final setsJson = json['courseSets'] as List? ?? [];
    final courseSets = setsJson
        .asMap()
        .entries
        .map((entry) => CourseSet.fromJson(entry.value, entry.key + 1))
        .toList();

    return MultiSetCandidateResponse(
      courseSets: courseSets,
      overallReasoning: json['overallReasoning'] ?? '',
      generatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseSets': courseSets.map((set) => set.toJson()).toList(),
      'overallReasoning': overallReasoning,
      'generatedAt': generatedAt.toIso8601String(),
    };
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
}

// === FEEDBACK AND INTERACTION MODELS ===

enum FeedbackType {
  like,
  dislike,
  replace,
  modify,
  general,
}

class UserFeedback {
  final String id;
  final FeedbackType type;
  final String message;
  final String? courseId; // For course-specific feedback
  final String? setId; // For set-specific feedback
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  const UserFeedback({
    required this.id,
    required this.type,
    required this.message,
    this.courseId,
    this.setId,
    this.additionalData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'message': message,
        'courseId': courseId,
        'setId': setId,
        'additionalData': additionalData,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UserFeedback.fromJson(Map<String, dynamic> json) => UserFeedback(
        id: json['id'],
        type: FeedbackType.values.firstWhere((e) => e.name == json['type']),
        message: json['message'],
        courseId: json['courseId'],
        setId: json['setId'],
        additionalData: json['additionalData'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class ConversationMessage {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;
  final UserFeedback? feedback; // If this message contains feedback
  final List<CourseSet>? recommendations; // If this message contains recommendations

  const ConversationMessage({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.feedback,
    this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUser': isUser,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'feedback': feedback?.toJson(),
        'recommendations': recommendations?.map((r) => r.toJson()).toList(),
      };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: json['id'],
        isUser: json['isUser'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
        feedback: json['feedback'] != null
            ? UserFeedback.fromJson(json['feedback'])
            : null,
        recommendations: json['recommendations'] != null
            ? (json['recommendations'] as List)
                .asMap()
                .entries
                .map((entry) => CourseSet.fromJson(entry.value, entry.key))
                .toList()
            : null,
      );
}

class RecommendationSession {
  final String sessionId;
  final CourseRecommendationRequest originalRequest;
  final List<ConversationMessage> conversation;
  final List<CourseSet>? currentRecommendations;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isActive;

  const RecommendationSession({
    required this.sessionId,
    required this.originalRequest,
    required this.conversation,
    this.currentRecommendations,
    required this.createdAt,
    required this.lastUpdated,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'originalRequest': originalRequest.toJson(),
        'conversation': conversation.map((m) => m.toJson()).toList(),
        'currentRecommendations':
            currentRecommendations?.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'isActive': isActive,
      };

  factory RecommendationSession.fromJson(Map<String, dynamic> json) =>
      RecommendationSession(
        sessionId: json['sessionId'],
        originalRequest:
            CourseRecommendationRequest.fromJson(json['originalRequest']),
        conversation: (json['conversation'] as List)
            .map((m) => ConversationMessage.fromJson(m))
            .toList(),
        currentRecommendations: json['currentRecommendations'] != null
            ? (json['currentRecommendations'] as List)
                .asMap()
                .entries
                .map((entry) => CourseSet.fromJson(entry.value, entry.key))
                .toList()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        isActive: json['isActive'],
      );

  RecommendationSession copyWith({
    List<ConversationMessage>? conversation,
    List<CourseSet>? currentRecommendations,
    DateTime? lastUpdated,
    bool? isActive,
  }) =>
      RecommendationSession(
        sessionId: sessionId,
        originalRequest: originalRequest,
        conversation: conversation ?? this.conversation,
        currentRecommendations:
            currentRecommendations ?? this.currentRecommendations,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? DateTime.now(),
        isActive: isActive ?? this.isActive,
      );
}

class FeedbackProcessingRequest {
  final RecommendationSession session;
  final UserFeedback feedback;

  const FeedbackProcessingRequest({
    required this.session,
    required this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'session': session.toJson(),
        'feedback': feedback.toJson(),
      };
}

class FeedbackResponse {
  final List<CourseSet> updatedRecommendations;
  final String explanation;
  final bool usedAlgorithm;
  final bool fetchedNewData;

  const FeedbackResponse({
    required this.updatedRecommendations,
    required this.explanation,
    required this.usedAlgorithm,
    required this.fetchedNewData,
  });

  Map<String, dynamic> toJson() => {
        'updatedRecommendations':
            updatedRecommendations.map((r) => r.toJson()).toList(),
        'explanation': explanation,
        'usedAlgorithm': usedAlgorithm,
        'fetchedNewData': fetchedNewData,
      };

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) =>
      FeedbackResponse(
        updatedRecommendations: (json['updatedRecommendations'] as List)
            .asMap()
            .entries
            .map((entry) => CourseSet.fromJson(entry.value, entry.key))
            .toList(),
        explanation: json['explanation'],
        usedAlgorithm: json['usedAlgorithm'] ?? false,
        fetchedNewData: json['fetchedNewData'] ?? false,
      );
}