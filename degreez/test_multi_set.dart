// Test file to verify the new multi-set functionality
import 'dart:convert';
import 'package:flutter/cupertino.dart';

import 'lib/models/course_recommendation_models.dart';

void main() {
  // Test JSON parsing for the new multi-set structure
  final testJson = {
    "courseSets": [
      {
        "courses": [
          {"id": "234114", "name": "מבני נתונים"},
          {"id": "236343", "name": "תכנות מערכות"},
          {"id": "234218", "name": "מבוא לאלגוריתמים"}
        ],
        "totalCredits": 15.0,
        "reasoning": "Focus on core CS fundamentals"
      },
      {
        "courses": [
          {"id": "234107", "name": "חישוביות"},
          {"id": "236360", "name": "מערכות הפעלה"},
          {"id": "236503", "name": "בסיסי נתונים"}
        ],
        "totalCredits": 16.5,
        "reasoning": "Systems-oriented approach"
      }
      // ... would have 8 more sets
    ],
    "overallReasoning": "Providing diverse strategic approaches for course selection"
  };

  try {
    final response = MultiSetCandidateResponse.fromJson(testJson);
    debugPrint('✅ Successfully parsed ${response.courseSets.length} course sets');
    
    for (int i = 0; i < response.courseSets.length; i++) {
      final set = response.courseSets[i];
      debugPrint('Set ${set.setId}: ${set.courses.length} courses, ${set.totalCredits} credits');
      debugPrint('  Reasoning: ${set.reasoning}');
      for (final course in set.courses) {
        debugPrint('  - ${course.courseId}: ${course.courseName}');
      }
      debugPrint('');
    }
    
    debugPrint('Overall reasoning: ${response.overallReasoning}');
    
  } catch (e) {
    debugPrint('❌ Error parsing JSON: $e');
  }
}
