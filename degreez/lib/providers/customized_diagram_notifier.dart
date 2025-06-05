import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:degreez/services/course_service.dart';
import 'package:degreez/models/student_model.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class CustomizedDiagramNotifier extends ChangeNotifier {
  
  // Private field to store the current user
  CourseCardColorPalette? _cardColorPalette;
  String? _focusedCourseId;
  Set<String> _highlightedCourseIds = {};

  CourseCardColorPalette? get cardColorPalette => _cardColorPalette;
  
  // Constructor: listen to auth state changes
  CustomizedDiagramNotifier() {
    _initCustomizedDiagram();
    notifyListeners();
    }
  
  // Initialize user on startup
  void _initCustomizedDiagram() {
    _cardColorPalette = CourseCardColorPalette1();
  }
  
  /// Sign in with Google account
  void switchPalette()  {
    if (cardColorPalette!.id==1)
    {_cardColorPalette = CourseCardColorPalette2();}
    else{
      _cardColorPalette = CourseCardColorPalette1();
    }
    notifyListeners();
  }


String? get focusedCourseId => _focusedCourseId;
Set<String> get highlightedCourseIds => _highlightedCourseIds;

void focusOnCourseWithStoredPrereqs(
  StudentCourse course,
  Map<String, List<StudentCourse>> allCoursesBySemester,
) {
  if (_focusedCourseId == course.courseId) {
    clearFocus();
    return;
  }

  final prereqIds = course.prerequisites ?? [];
  debugPrint('🔍 Looking for prereqs: ${prereqIds.join(', ')}');

  // Search all semesters for matching prerequisite course IDs
  final matchingCourses = <String>{};
  for (final semesterCourses in allCoursesBySemester.values) {
     debugPrint('📘 Courses in semester: ${semesterCourses.map((c) => c.courseId).join(', ')}');
    for (final c in semesterCourses) {
      if (prereqIds.contains(c.courseId)) {
        matchingCourses.add(c.courseId);
      }
    }
  }

  _focusedCourseId = course.courseId;
  _highlightedCourseIds = {course.courseId, ...matchingCourses};
  notifyListeners();
}



void clearFocus() {
  _focusedCourseId = null;
  _highlightedCourseIds.clear();
  notifyListeners();
}

}