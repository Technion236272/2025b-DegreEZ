import 'package:cloud_firestore/cloud_firestore.dart';

// models/student_model.dart
class StudentModel {
  final String id;
  final String name;
  final String major;
  final String faculty;
  final String preferences;
  final String semester;
  final String catalog; // selecting the catalog for the student
  final String themeMode; // 'light', 'dark', or 'system' for theme preference
  

  StudentModel({
    required this.id,
    required this.name,
    required this.major,
    required this.faculty,
    required this.preferences,
    required this.semester,
    required this.catalog,
    this.themeMode = 'dark', // Default to dark mode for existing users
  });
  // Factory constructor to create a StudentModel from Firestore data
  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StudentModel(
      id: doc.id, //  this is the real Firestore document ID
      name: data['Name'] ?? '',
      major: data['Major'] ?? '',
      faculty: data['Faculty'] ?? '',
      preferences: data['Preferences'] ?? '',
      semester:
          data['Semester']?.toString() ??
          '1', // Convert to String and provide default
      catalog: data['Catalog'] ?? '',
      themeMode: data['ThemeMode'] ?? 'dark', // Default to dark mode
    );
  }
  // Method to convert the StudentModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'Id': id,
      'Name': name,
      'Major': major,
      'Faculty': faculty,
      'Preferences': preferences,
      'Semester': semester, // Now stored as String
      'Catalog': catalog,
      'ThemeMode': themeMode,
    };
  }
  StudentModel copyWith({
    String? name,
    String? major,
    String? preferences,
    String? catalog,
    String? faculty,
    String? semester,
    String? themeMode,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      major: major ?? this.major,
      faculty: faculty ?? this.faculty,
      preferences: preferences ?? this.preferences,
      semester: semester ?? this.semester,
      catalog: catalog ?? this.catalog,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// ✨ Enhanced StudentCourse model with schedule selection using existing fields
class StudentCourse {
  final String courseId;
  final String name;
  final String finalGrade;
  final String lectureTime;  // Stores selected lecture schedule: "day time" format
  final String tutorialTime; // Stores selected tutorial schedule: "day time" format
  final String labTime;      // Stores selected lab schedule: "day time" format
  final String workshopTime; // Stores selected workshop schedule: "day time" format
  final double creditPoints; // Stores credit points for the course

  String? note;
  final List<Map<String, List<String>>>? prerequisites;
  StudentCourse({
    required this.courseId,
    required this.name,
    required this.finalGrade,
    required this.lectureTime,
    required this.tutorialTime,
    required this.labTime,
    required this.workshopTime,
    required this.creditPoints,
    this.note,
    this.prerequisites,
  });

  factory StudentCourse.fromFirestore(Map<String, dynamic> data) {
    final raw = data['prerequisites'];
    List<Map<String, List<String>>>? parsedPrereqs;

    if (raw is List) {
      parsedPrereqs =
          raw.map<Map<String, List<String>>>((group) {
            if (group is Map && group['and'] is List) {
              final ids = List<String>.from(
                group['and'].map((e) => e.toString()),
              );
              return {'and': ids};
            }
            return {'and': []};
          }).toList();
    }    return StudentCourse(
      courseId: data['Course_Id'] ?? '',
      name: data['Name'] ?? '',
      finalGrade: data['Final_grade'] ?? '',
      lectureTime: data['Lecture_time'] ?? '',
      tutorialTime: data['Tutorial_time'] ?? '',
      labTime: data['Lab_time'] ?? '',
      workshopTime: data['Workshop_time'] ?? '',
      creditPoints: (data['Credit_points'] as num?)?.toDouble() ?? 3.0, // Default to 3.0 if not specified
      note: data['Note'] ?? '',
      prerequisites: parsedPrereqs,
    );
  }
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{
      'Course_Id': courseId,
      'Name': name,
      'Final_grade': finalGrade,
      'Lecture_time': lectureTime,
      'Tutorial_time': tutorialTime,
      'Lab_time': labTime,
      'Workshop_time': workshopTime,
      'Credit_points': creditPoints,
      'Note': note ?? '',
    };

    if (prerequisites != null) {
      data['prerequisites'] = prerequisites;
    }

    return data;
  }
  StudentCourse copyWith({
    String? finalGrade,
    String? note,
    String? lectureTime,
    String? tutorialTime,
    String? labTime,
    String? workshopTime,
    double? creditPoints,
    List<Map<String, List<String>>>? prerequisites,
  }) {
    return StudentCourse(
      courseId: courseId,
      name: name,
      finalGrade: finalGrade ?? this.finalGrade,
      lectureTime: lectureTime ?? this.lectureTime,
      tutorialTime: tutorialTime ?? this.tutorialTime,
      labTime: labTime ?? this.labTime,
      workshopTime: workshopTime ?? this.workshopTime,
      creditPoints: creditPoints ?? this.creditPoints,
      note: note ?? this.note,
      prerequisites: prerequisites ?? this.prerequisites,
    );
  }

  // Helper methods for schedule selection
  bool get hasSelectedLecture => lectureTime.isNotEmpty;
  bool get hasSelectedTutorial => tutorialTime.isNotEmpty;
  bool get hasSelectedLab => labTime.isNotEmpty;
  bool get hasSelectedWorkshop => workshopTime.isNotEmpty;
  bool get hasCompleteScheduleSelection => hasSelectedLecture || hasSelectedTutorial || hasSelectedLab || hasSelectedWorkshop;

  // Helper to get selection summary
  String get selectionSummary {
    if (!hasCompleteScheduleSelection) {
      return 'All times shown';
    }

    final parts = <String>[];
    if (hasSelectedLecture) parts.add('Lecture');
    if (hasSelectedTutorial) parts.add('Tutorial');
    if (hasSelectedLab) parts.add('Lab');
    if (hasSelectedWorkshop) parts.add('Workshop');
    if (parts.isEmpty) {
      return 'No selections made';
    }
    return '${parts.join(' + ')} selected';
  }

  // Helper to count selections
  int get selectionCount {
    int count = 0;
    if (hasSelectedLecture) count++;
    if (hasSelectedTutorial) count++;
    if (hasSelectedLab) count++;
    if (hasSelectedWorkshop) count++;
    return count;
  }

  // Helper to format schedule string from day and time
  static String formatScheduleString(String day, String time) {
    return '$day $time';
  }

  // Helper to parse schedule string back to day and time
  Map<String, String>? parseScheduleString(String scheduleString) {
    if (scheduleString.isEmpty) return null;

    final parts = scheduleString.split(' ');
    if (parts.length < 2) return null;

    return {
      'day': parts[0],
      'time': parts.sublist(1).join(' '), // In case time has spaces
    };
  }
}

// Helper class to combine student course with API details
class StudentCourseWithDetails {
  final StudentCourse studentCourse;
  final dynamic courseDetails; // Will be EnhancedCourseDetails from service

  StudentCourseWithDetails({required this.studentCourse, this.courseDetails});
}
