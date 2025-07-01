// lib/providers/course_recommendation_provider.dart

import 'package:degreez/providers/course_provider.dart';
import 'package:flutter/material.dart';
import '../models/course_recommendation_models.dart';
import '../services/course_recommendation_service.dart';
import '../services/chat/context_generator_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseRecommendationProvider extends ChangeNotifier {
  final CourseRecommendationService _recommendationService =
      CourseRecommendationService();

  // State variables
  bool _isLoading = false;
  String? _error;
  CourseRecommendationResponse? _currentRecommendation;
  List<CourseRecommendationResponse> _previousRecommendations = [];

  // Form state
  int? _selectedYear;
  int? _selectedSemester;
  String? _catalogFilePath;
  List<Map<String, dynamic>> _availableSemesters = [];

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
  String? get error => _error;
  CourseRecommendationResponse? get currentRecommendation =>
      _currentRecommendation;
  List<CourseRecommendationResponse> get previousRecommendations =>
      _previousRecommendations;
  int? get selectedYear => _selectedYear;
  int? get selectedSemester => _selectedSemester;
  String? get catalogFilePath => _catalogFilePath;
  List<Map<String, dynamic>> get availableSemesters => _availableSemesters;


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

  /// Generate course recommendations
  Future<void> generateRecommendations(BuildContext context) async {
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
      final userContext = ContextGeneratorService.generateUserContext(context);

      // Create recommendation request
      final request = CourseRecommendationRequest(
        year: _selectedYear!,
        semester: _selectedSemester!,
        catalogFilePath: _catalogFilePath,
        userContext: userContext,
        requestTime: DateTime.now(),
        semesterDisplayName: getSemesterDisplayName(
          _selectedYear!,
          _selectedSemester!,
        ),
      );

      // Generate recommendations
      final response = await _recommendationService.generateRecommendations(
        request,
      );

      // Update state
      _currentRecommendation = response;
      _previousRecommendations.insert(0, response);

      // Keep only last 10 recommendations
      if (_previousRecommendations.length > 10) {
        _previousRecommendations = _previousRecommendations.take(10).toList();
      }
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
        semesterName =
            'Winter ${year - 1}-$year'; // Academic year spans 2 years
        break;
      case 201:
        semesterName = 'Spring ${year+1}';
        break;
      case 202:
        semesterName = 'Summer ${year+1}';
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

  /// Get recommendation statistics
  Map<String, dynamic> getRecommendationStats() {
    if (_currentRecommendation == null) return {};

    final recommendations = _currentRecommendation!.recommendations;
    final categories = <String, int>{};

    for (final rec in recommendations) {
      categories[rec.category] = (categories[rec.category] ?? 0) + 1;
    }

    return {
      'totalCourses': recommendations.length,
      'totalCredits': _currentRecommendation!.totalCreditPoints,
      'categories': categories,
      'highPriority': recommendations.where((r) => r.priority <= 2).length,
      'mediumPriority': recommendations.where((r) => r.priority == 3).length,
      'lowPriority': recommendations.where((r) => r.priority >= 4).length,
    };
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
      'stats': getRecommendationStats(),
    };
  }

  /// Set a previous recommendation as the current one
  void setCurrentRecommendation(CourseRecommendationResponse recommendation) {
    _currentRecommendation = recommendation;
    notifyListeners();
  }
}
