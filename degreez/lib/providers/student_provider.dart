// providers/student_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'theme_provider.dart';

class StudentProvider with ChangeNotifier {
  StudentModel? _student;
  bool _isLoading = false;
  String? _error;

  // Getters
  StudentModel? get student => _student;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasStudent => _student != null;

  // Fetch student data with proper error handling
  Future<bool> fetchStudentData(String userId) async {
    if (_isLoading) return false; // Prevent concurrent calls
    
    _setLoadingState(true);
    
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Students')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        _student = StudentModel.fromFirestore(docSnapshot);
        _error = null;
        _notifyListeners();
        return true;
      } else {
        _setError('Student not found');
        return false;
      }
    } catch (e) {
      _setError('Failed to fetch student: $e');
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  // Create student with optimistic update
  Future<bool> createStudent(StudentModel student) async {
    // Optimistic update
    _student = student;
    _notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(student.id)
          .set(student.toFirestore());
      
      _error = null;
      return true;
    } catch (e) {
      // Rollback on error
      _student = null;
      _setError('Failed to create student: $e');
      return false;
    }
  }
  // Update student profile with optimistic update
  Future<bool> updateStudentProfile({
    required String name,
    required String major,
    required String preferences,
    required String faculty,
    required String catalog,
    required String semester, // Changed from int to String
    String? themeMode, // Optional theme mode parameter
  }) async {
    if (_student == null) return false;

    // Store old data for rollback
    final oldStudent = _student!;
    
    // Optimistic update
    _student = _student!.copyWith(
      name: name,
      major: major,
      preferences: preferences,
      faculty: faculty,
      catalog: catalog,
      semester: semester,
      themeMode: themeMode ?? _student!.themeMode, // Preserve existing if not provided
    );
    _notifyListeners();

    try {
      final updateData = {
        'Name': name,
        'Major': major,
        'Preferences': preferences,
        'Faculty': faculty,
        'Catalog': catalog,
        'Semester': semester, // Now stored as String
      };
      
      // Only update theme mode if provided
      if (themeMode != null) {
        updateData['ThemeMode'] = themeMode;
      }
      
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(_student!.id)
          .update(updateData);
      
      _error = null;
      return true;
    } catch (e) {
      // Rollback on error
      _student = oldStudent;
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  // Load student's theme preference and apply it to theme provider
  Future<void> loadAndApplyThemePreference(ThemeProvider themeProvider) async {
    if (_student?.themeMode != null) {
      try {
        final themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == _student!.themeMode,
          orElse: () => AppThemeMode.dark, // Default fallback
        );
        await themeProvider.setThemeMode(themeMode);
      } catch (e) {
        debugPrint('Error applying student theme preference: $e');
      }
    }
  }

  void clear() {
    _student = null;
    _error = null;
    _isLoading = false;
    _notifyListeners();
  }

  // Private methods to reduce notifyListeners calls
  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    _notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }
}
