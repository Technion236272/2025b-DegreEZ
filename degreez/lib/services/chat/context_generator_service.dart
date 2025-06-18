import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/course_provider.dart';

class ContextGeneratorService {
  static String generateUserContext(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    final student = studentProvider.student;
    final coursesBySemester = courseProvider.coursesBySemester;
    
    if (student == null) {
      return "";
    }
    
    final contextParts = <String>[
      "--- User Academic Context ---",
      "Student Name: ${student.name}",
      "Major: ${student.major}",
      "Faculty: ${student.faculty}",
      "Current Semester: ${student.semester}",
      "Catalog: ${student.catalog}",
      "Preferences: ${student.preferences}",
    ];
    
    if (coursesBySemester.isNotEmpty) {
      contextParts.add("\n--- Course Information by Semester ---");
      
      for (final entry in coursesBySemester.entries) {
        final semesterKey = entry.key;
        final courses = entry.value;
        if (courses.isNotEmpty) {
          contextParts.add("\nSemester $semesterKey:");
          for (final course in courses) {
            final courseInfo = [
              "  • ${course.name} (${course.courseId})",
              if (course.finalGrade.isNotEmpty) "Grade: ${course.finalGrade}",
              "Credits: ${course.creditPoints}",
              if (course.note != null && course.note!.isNotEmpty) "Note: ${course.note}",
            ].join(", ");
            contextParts.add(courseInfo);
          }
        }
      }
    }
    
    contextParts.add("\n--- End Context ---\n");
    return contextParts.join("\n");
  }

  // Check if user message contains context-relevant keywords
  static bool containsContextRelevantKeywords(String message) {
    final lowercaseMessage = message.toLowerCase();
    
    final contextKeywords = [
      // Course-related terms
      'course', 'courses', 'class', 'classes', 'subject', 'subjects',
      'semester', 'credit', 'credits', 'grade', 'grades', 'gpa',
      'study plan', 'academic plan', 'degree plan', 'curriculum',
      'major', 'minor', 'faculty', 'department',
      
      // Specific course actions
      'register', 'enroll', 'drop', 'add',
      'schedule', 'timetable', 'calendar',
      'exam', 'exams', 'test', 'tests', 'assignment', 'assignments',
      'professor', 'instructor', 'teacher',
      
      // Academic planning
      'graduation', 'graduate', 'requirements', 'prerequisite',
      'electives', 'elective', 'optional courses',
      'prerequisite', 'prerequisites', 'pre-req',
      'core courses', 'mandatory courses', 'compulsory',
      
      // Academic advice seeking
      'should i take', 'what courses', 'which courses',
      'recommend courses', 'suggest courses',
      'plan my', 'help me plan', 'advice on',
      
      // Personal academic references
      'what am i', 'what have i', 'how many',
      'do i need', 'can i graduate', 'when will i',
      'my academic', 'my studies',
    ];
    
    return contextKeywords.any((keyword) => lowercaseMessage.contains(keyword));
  }
}
