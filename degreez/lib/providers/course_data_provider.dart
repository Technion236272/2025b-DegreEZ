// providers/course_data_provider.dart
import 'package:flutter/foundation.dart';
import '../services/course_service.dart';

class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, Duration validFor) 
      : expiry = DateTime.now().add(validFor);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

class CourseDataProvider with ChangeNotifier {
  SemesterInfo? _currentSemester;
  final Map<String, CacheEntry<EnhancedCourseDetails>> _courseDetailsCache = {};
  final Map<String, CacheEntry<List<SemesterInfo>>> _semestersCache = {};
  bool _isLoadingCurrentSemester = false;
  String? _error;

  // Getters
  SemesterInfo? get currentSemester => _currentSemester;
  bool get isLoadingCurrentSemester => _isLoadingCurrentSemester;
  String? get error => _error;

  Future<void> initialize() async {
    await fetchCurrentSemester();
  }

  Future<bool> fetchCurrentSemester() async {
    if (_isLoadingCurrentSemester) return false;

    _isLoadingCurrentSemester = true;
    notifyListeners();

    try {
      final semesters = await getAvailableSemesters();
      if (semesters.isNotEmpty) {
        _currentSemester = semesters.first;
        _error = null;
        return true;
      } else {
        _error = 'No semesters available';
        return false;
      }
    } catch (e) {
      _error = 'Failed to fetch current semester: $e';
      // Fallback
      _currentSemester = SemesterInfo(
        year: 2024,
        semester: 200,
        startDate: '',
        endDate: '',
      );
      return false;
    } finally {
      _isLoadingCurrentSemester = false;
      notifyListeners();
    }
  }

  Future<List<SemesterInfo>> getAvailableSemesters() async {
    const cacheKey = 'semesters';
    final cached = _semestersCache[cacheKey];

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final semesters = await CourseService.getAvailableSemesters();
      _semestersCache[cacheKey] = CacheEntry(semesters, Duration(hours: 24));
      return semesters;
    } catch (e) {
      debugPrint('Error fetching semesters: $e');
      // Return cached data even if expired, or empty list
      return cached?.data ?? [];
    }
  }

  Future<EnhancedCourseDetails?> getCourseDetails(String courseId) async {
    final cached = _courseDetailsCache[courseId];
    
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    if (_currentSemester == null) {
      await fetchCurrentSemester();
      if (_currentSemester == null) return null;
    }

    try {
      final details = await CourseService.getCourseDetails(
        _currentSemester!.year,
        _currentSemester!.semester,
        courseId,
      );

      if (details != null) {
        _courseDetailsCache[courseId] = CacheEntry(details, Duration(hours: 2));
        notifyListeners(); // Notify for UI updates
      }

      return details;
    } catch (e) {
      debugPrint('Error fetching course details for $courseId: $e');
      // Return expired cache if available
      return cached?.data;
    }
  }

  void invalidateCourseCache(String courseId) {
    _courseDetailsCache.remove(courseId);
    notifyListeners();
  }

  void clearCache() {
    _courseDetailsCache.clear();
    _semestersCache.clear();
    notifyListeners();
  }

  void clear() {
    _currentSemester = null;
    _courseDetailsCache.clear();
    _semestersCache.clear();
    _error = null;
    _isLoadingCurrentSemester = false;
    notifyListeners();
  }
}
