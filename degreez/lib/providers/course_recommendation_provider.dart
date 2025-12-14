// lib/providers/course_recommendation_provider.dart

import 'dart:typed_data';
import 'package:degreez/providers/course_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/course_recommendation_models.dart';
import '../services/course_recommendation_service.dart';
import '../services/chat/context_generator_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CourseRecommendationProvider extends ChangeNotifier {
  CourseRecommendationService? _recommendationService;

  // Initialize the service when we have a CourseProvider
  void _initializeService(CourseProvider courseProvider) {
    _recommendationService ??= CourseRecommendationService(courseProvider);
  }

  // State variables
  bool _isLoading = false;
  String? _error;
  CourseRecommendationResponse? _currentRecommendation;
  List<CourseRecommendationResponse> _previousRecommendations = [];

  // Form state
  int? _selectedYear;
  int? _selectedSemester;
  String? _catalogFilePath;
  Uint8List? _catalogFileBytes; // NEW: Store file bytes for web platform
  List<Map<String, dynamic>> _availableSemesters = [];
  bool _fastMode = true; // NEW: Fast mode toggle - default to ON

  // Feedback state
  RecommendationSession? _currentSession;
  bool _isProcessingFeedback = false;

  Future<List<Map<String, dynamic>>> getStudentSemesterList(
    String studentId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot =
        await firestore
            .collection('Students')
            .doc(studentId)
            .collection('Courses-per-Semesters')
            .get();

    final semesters = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final semesterKey = doc.id; // e.g., "Winter 2024-2025"
      final parsed = CourseProvider().parseSemesterCode(
        semesterKey,
      ); // (int, int)?
      if (parsed == null) continue;

      final (year, semesterCode) = parsed;

      semesters.add({
        'display': semesterKey,
        'year': year,
        'semester': semesterCode,
      });
    }

    // Sort by year + semesterCode (Winter < Spring < Summer)
    semesters.sort((a, b) {
      int getSortYear(String semesterName) {
        final parts = semesterName.split(' ');
        final yearPart = parts.length > 1 ? parts[1] : '';

        if (yearPart.contains('-')) {
          final years = yearPart.split('-');
          return int.tryParse(years.last) ?? 0; // Use later year
        }
        return int.tryParse(yearPart) ?? 0;
      }

      int getSeasonOrder(String semesterName) {
        final season = semesterName.split(' ').first;
        const order = {'Winter': 0, 'Spring': 1, 'Summer': 2};
        return order[season] ?? 99;
      }

      final yearA = getSortYear(a['display']);
      final yearB = getSortYear(b['display']);
      if (yearA != yearB) return yearA.compareTo(yearB);

      final seasonA = getSeasonOrder(a['display']);
      final seasonB = getSeasonOrder(b['display']);
      return seasonA.compareTo(seasonB);
    });

    return semesters;
  }

  // Manual semester options - no need to fetch from Firestore
  /*static const List<Map<String, dynamic>> _manualSemesters = [
    // 2024
    {'display': 'Winter 2023-2024', 'year': 2024, 'semester': 200},
    {'display': 'Spring 2024', 'year': 2024, 'semester': 201},
    {'display': 'Summer 2024', 'year': 2024, 'semester': 202},

    // 2025
    {'display': 'Winter 2024-2025', 'year': 2025, 'semester': 200},
    {'display': 'Spring 2025', 'year': 2025, 'semester': 201},
    {'display': 'Summer 2025', 'year': 2025, 'semester': 202},

    // 2026
    {'display': 'Winter 2025-2026', 'year': 2026, 'semester': 200},
    {'display': 'Spring 2026', 'year': 2026, 'semester': 201},
    {'display': 'Summer 2026', 'year': 2026, 'semester': 202},
  ];
*/
  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessingFeedback => _isProcessingFeedback;
  String? get error => _error;
  CourseRecommendationResponse? get currentRecommendation => _currentRecommendation;
  RecommendationSession? get currentSession => _currentSession;
  List<CourseRecommendationResponse> get previousRecommendations =>
      _previousRecommendations;
  int? get selectedYear => _selectedYear;
  int? get selectedSemester => _selectedSemester;  String? get catalogFilePath => _catalogFilePath;
  Uint8List? get catalogFileBytes => _catalogFileBytes; // NEW: Get file bytes for web
  List<Map<String, dynamic>> get availableSemesters => _availableSemesters;
  bool get fastMode => _fastMode; // NEW: Fast mode getter

  bool get canGenerateRecommendations =>
      _selectedYear != null && _selectedSemester != null && !_isLoading;

  /// Initialize the provider - no async operations needed now
  void initialize() {
    // Nothing to initialize since we're using manual semesters
    notifyListeners();
  }

  Future<void> loadAvailableSemesters(String studentId) async {
    _availableSemesters = await getStudentSemesterList(studentId);
    notifyListeners();
  }

  /// Set the selected semester and year
  void setSelectedSemester(int year, int semester) {
    _selectedYear = year;
    _selectedSemester = semester;
    _error = null;
    notifyListeners();
  }
  /// Set the catalog file path
  void setCatalogFilePath(String? filePath) {
    _catalogFilePath = filePath;
    notifyListeners();
  }

  /// Set the catalog file bytes (for web platform)
  void setCatalogFileBytes(Uint8List? bytes) {
    _catalogFileBytes = bytes;
    notifyListeners();
  }

  /// Set both catalog file path and bytes (convenience method)
  void setCatalogFile(String? filePath, Uint8List? bytes) {
    _catalogFilePath = filePath;
    _catalogFileBytes = bytes;
    notifyListeners();
  }

  /// Clear catalog file
  void clearCatalogFile() {
    _catalogFilePath = null;
    _catalogFileBytes = null;
    notifyListeners();
  }

Future<void> _saveRecommendationToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonList = _previousRecommendations
      .take(10)
      .map((r) => r.toJson())
      .toList();
  await prefs.setString('recommendation_history', jsonEncode(jsonList));
}


Future<void> loadSavedRecommendation() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('recommendation_history');
  if (jsonString != null) {
    try {
      final decoded = jsonDecode(jsonString) as List;
      _previousRecommendations = decoded
          .map((json) => CourseRecommendationResponse.fromJson(json))
          .toList();

      notifyListeners(); // Only updates history tab
    } catch (e) {
      debugPrint('Failed to load saved recommendation history: $e');
    }
  }
}

  /// Set fast mode
  void setFastMode(bool fastMode) {
    _fastMode = fastMode;
    notifyListeners();
  }

  /// Generate course recommendations
  Future<void> generateRecommendations(BuildContext context, CourseProvider courseProvider) async {
    if (!canGenerateRecommendations) {
      _error = 'Please select a semester and year first';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Generate user context
      final userContext = ContextGeneratorService.generateUserContext(context);      // Create recommendation request
      final request = CourseRecommendationRequest(
        year: _selectedYear!,
        semester: _selectedSemester!,
        catalogFilePath: kIsWeb ? null : _catalogFilePath, // Only use path on non-web
        catalogFileBytes: _catalogFileBytes, // NEW: Pass bytes for web platform
        userContext: userContext,
        requestTime: DateTime.now(),
        semesterDisplayName: getSemesterDisplayName(
          _selectedYear!,
          _selectedSemester!,
        ),
      );

      // Initialize session for interactive feedback
      _initializeSession(request);

      // Initialize the service with the CourseProvider
      _initializeService(courseProvider);
      
      // Generate recommendations
      final response = await _recommendationService!.generateRecommendations(
        request,
        fastMode: _fastMode, // Use provider's fast mode setting
      );

      // Update state
      _currentRecommendation = response;
      _previousRecommendations.insert(0, response);

      // Extract course sets from the response and store in session
      // The response contains the final 2 sets, but we need to get the course sets format
      // For now, convert the response back to course sets for the feedback system
      final courseSets = _convertResponseToCourseSets(response);
      _currentSession = _currentSession!.copyWith(
        currentRecommendations: courseSets,
        validCandidates: response.validCandidates, // NEW: Store valid candidates for feedback optimization
        conversation: [
          ConversationMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            isUser: false,
            content: 'Here are your personalized course recommendations! ${response.summary}',
            timestamp: DateTime.now(),
            recommendations: courseSets,
          ),
        ],
      );

      // Keep only last 10 recommendations
      if (_previousRecommendations.length > 10) {
        _previousRecommendations = _previousRecommendations.take(10).toList();
      }
      await _saveRecommendationToStorage();
    } catch (e) {
      _error = 'Failed to generate recommendations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear current recommendation
  void clearCurrentRecommendation() {
    _currentRecommendation = null;
    notifyListeners();
  }

  /// Clear all recommendations
  void clearAllRecommendations() {
    _currentRecommendation = null;
    _previousRecommendations.clear();
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get formatted semester display name
  String getSemesterDisplayName(int year, int semester) {
    String semesterName;
    switch (semester) {
      case 200:
        semesterName = 'Winter $year-${year + 1}'; // Academic year spans 2 years
        break;
      case 201:
        semesterName = 'Spring ${year + 1}';
        break;
      case 202:
        semesterName = 'Summer $year';
        break;
      default:
        semesterName = 'Semester $semester $year';
    }
    return semesterName;
  }

  /// Get the current selected semester as display string
  String? get selectedSemesterDisplay {
    if (_selectedYear == null || _selectedSemester == null) return null;
    return getSemesterDisplayName(_selectedYear!, _selectedSemester!);
  }



  /// Check if a course is already taken by the student
  bool isCourseAlreadyTaken(String courseId, BuildContext context) {
    // This would need to be implemented based on your existing course provider
    // You'd check against the student's completed courses
    return false; // Placeholder
  }

  /// Export recommendations to a shareable format
  Map<String, dynamic> exportRecommendations() {
    if (_currentRecommendation == null) return {};

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'semester': getSemesterDisplayName(_selectedYear!, _selectedSemester!),
      'recommendations': _currentRecommendation!.toJson(),
    };
  }

  /// Set a previous recommendation as the current one
  void setCurrentRecommendation(CourseRecommendationResponse recommendation) {
    _currentRecommendation = recommendation;
    _selectedYear = recommendation.originalRequest.year;
    _selectedSemester = recommendation.originalRequest.semester;
    notifyListeners();
  }

  Future<void> _saveAllRecommendationsToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final listJson = _previousRecommendations
      .map((r) => r.toJson()) // ensure `toJson()` exists
      .toList();
  await prefs.setString('recommendation_history', jsonEncode(listJson));
}

  void deleteRecommendationAt(int index) async {
  if (index >= 0 && index < _previousRecommendations.length) {
    _previousRecommendations.removeAt(index);
    await _saveAllRecommendationsToStorage(); // persist new list
    notifyListeners();
  }

}

  /// Process user feedback and get updated recommendations
  Future<void> processFeedback(UserFeedback feedback) async {
    if (_currentSession == null) {
      throw Exception('No active recommendation session');
    }

    _isProcessingFeedback = true;
    notifyListeners();

    try {
      // Add user feedback to conversation
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: true,
        content: feedback.message,
        timestamp: DateTime.now(),
        feedback: feedback,
      );

      // Create feedback processing request
      final request = FeedbackProcessingRequest(
        session: _currentSession!.copyWith(
          conversation: [..._currentSession!.conversation, userMessage],
        ),
        feedback: feedback,
      );

      // Process feedback through the service
      final feedbackResponse = await _recommendationService!.processFeedback(request);

      // Update current session with the improved course sets
      _currentSession = _currentSession!.copyWith(
        conversation: [
          ..._currentSession!.conversation,
          userMessage,
          ConversationMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            isUser: false,
            content: feedbackResponse.explanation,
            timestamp: DateTime.now(),
            recommendations: feedbackResponse.updatedRecommendations,
          ),
        ],
        currentRecommendations: feedbackResponse.updatedRecommendations,
        lastUpdated: DateTime.now(),
      );

      // Convert course sets back to CourseRecommendationResponse format for UI compatibility
      final updatedRecommendation = _convertCourseSetsToResponse(
        feedbackResponse.updatedRecommendations,
        feedbackResponse.explanation,
        _currentSession!.originalRequest,
      );

      _currentRecommendation = updatedRecommendation;
      _error = null;

      debugPrint('✅ Feedback processed successfully - ${feedbackResponse.updatedRecommendations.length} sets updated');
    } catch (e) {
      _error = 'Failed to process feedback: $e';
      debugPrint('❌ Error processing feedback: $e');
    } finally {
      _isProcessingFeedback = false;
      notifyListeners();
    }
  }

  /// Initialize a new recommendation session
  void _initializeSession(CourseRecommendationRequest request) {
    _currentSession = RecommendationSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      originalRequest: request,
      conversation: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      isActive: true,
    );
  }

  /// Get conversation history for UI display
  List<ConversationMessage> getConversationHistory() {
    return _currentSession?.conversation ?? [];
  }

  /// End current session
  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(isActive: false);
    }
    notifyListeners();
  }

  /// Convert course sets to CourseRecommendationResponse for UI compatibility
  CourseRecommendationResponse _convertCourseSetsToResponse(
    List<CourseSet> courseSets,
    String explanation,
    CourseRecommendationRequest originalRequest,
  ) {
    final recommendations = <CourseRecommendation>[];
    
    // Convert each course set to multiple CourseRecommendation objects
    for (final set in courseSets) {
      final isPrimary = set.setId == 1; // Assume first set is primary
      for (int i = 0; i < set.courses.length; i++) {
        final course = set.courses[i];
        recommendations.add(CourseRecommendation(
          courseId: course.courseId,
          courseName: course.courseName,
          creditPoints: course.creditPoints, // Use actual credit points from course
          reason: set.reasoning,
          priority: isPrimary ? 1 : set.setId, // Primary gets priority 1
          category: isPrimary ? 'Primary Set' : 'Set ${set.setId}',
        ));
      }
    }

    return CourseRecommendationResponse(
      recommendations: recommendations,
      totalCreditPoints: recommendations.fold(0.0, (sum, rec) => sum + rec.creditPoints),
      summary: explanation,
      reasoning: 'Updated recommendations based on your feedback',
      generatedAt: DateTime.now(),
      originalRequest: originalRequest,
    );
  }

  /// Convert CourseRecommendationResponse back to CourseSet format for feedback system
  List<CourseSet> _convertResponseToCourseSets(CourseRecommendationResponse response) {
    // Group recommendations by category/priority to reconstruct sets
    final setMap = <String, List<CourseRecommendation>>{};
    
    for (final recommendation in response.recommendations) {
      final setKey = recommendation.category.isNotEmpty 
          ? recommendation.category 
          : 'Set ${recommendation.priority}';
      setMap.putIfAbsent(setKey, () => []).add(recommendation);
    }

    final courseSets = <CourseSet>[];
    var setId = 1;

    for (final entry in setMap.entries) {
      final courses = entry.value.map((rec) => CourseInSet(
        courseId: rec.courseId,
        courseName: rec.courseName,
        creditPoints: rec.creditPoints, // Preserve actual credit points
      )).toList();

      final totalCredits = entry.value.fold(0.0, (sum, rec) => sum + rec.creditPoints);
      final reasoning = entry.value.isNotEmpty 
          ? entry.value.first.reason 
          : 'Course set ${entry.key}';

      courseSets.add(CourseSet(
        setId: setId++,
        courses: courses,
        totalCredits: totalCredits,
        reasoning: reasoning,
      ));
    }

    return courseSets;
  }

  /// Get current course sets for feedback (from session)
  List<CourseSet> getCurrentCourseSets() {
    return _currentSession?.currentRecommendations ?? [];
  }

  /// Clear conversation history for current session
  void clearConversationHistory() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        conversation: [],
      );
      notifyListeners();
    }
  }
}
