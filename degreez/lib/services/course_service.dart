// services/course_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourseService {
  static const String baseUrl = 'https://michael-maltsev.github.io/technion-sap-info-fetcher';
  
  // Cache for course data to avoid repeated API calls
  static final Map<String, List<dynamic>> _coursesCache = {};
  static final Map<String, List<SemesterInfo>> _semestersCache = {};

  /// Get available semesters
  static Future<List<SemesterInfo>> getAvailableSemesters() async {
    if (_semestersCache.isNotEmpty) {
      return _semestersCache.values.first;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/last_semesters.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final semesters = data.map((item) => SemesterInfo.fromJson(item)).toList();
        _semestersCache['semesters'] = semesters;
        return semesters;
      }
    } catch (e) {
      throw Exception('Error fetching semesters: $e');
    }
    return [];
  }

  /// Get all courses for a specific semester
  static Future<List<dynamic>> getAllCourses(int year, int semester) async {
    final key = '${year}_$semester';
    if (_coursesCache.containsKey(key)) {
      return _coursesCache[key]!;
    }

    try {
      final url = '$baseUrl/courses_${year}_$semester.json';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> courses = json.decode(response.body);
        _coursesCache[key] = courses;
        return courses;
      }
    } catch (e) {
      throw Exception('Error fetching courses for $year-$semester: $e');
    }
    return [];
  }

  /// Search for courses by various criteria
  static Future<List<CourseSearchResult>> searchCourses({
    required int year,
    required int semester,
    String? courseId,
    String? courseName,
    String? faculty,
    List<String>? days,
    String? timeRange,
  }) async {
    final allCourses = await getAllCourses(year, semester);
    final results = <CourseSearchResult>[];

    for (final courseData in allCourses) {
      final course = EnhancedCourseDetails.fromSapJson(courseData);
      
      // Apply filters
      bool matches = true;
      
      if (courseId != null && courseId.isNotEmpty) {
        matches = matches && course.courseNumber.toLowerCase().contains(courseId.toLowerCase());
      }
      
      if (courseName != null && courseName.isNotEmpty) {
        matches = matches && course.name.toLowerCase().contains(courseName.toLowerCase());
      }
      
      if (faculty != null && faculty.isNotEmpty) {
        matches = matches && course.faculty.toLowerCase().contains(faculty.toLowerCase());
      }
      
      if (days != null && days.isNotEmpty) {
        final courseDays = course.schedule.map((s) => s.day).toSet();
        matches = matches && days.any((day) => courseDays.contains(day));
      }
      
      if (matches) {
        results.add(CourseSearchResult(
          course: course,
          matchScore: _calculateMatchScore(course, courseId, courseName),
        ));
      }
    }
    
    // Sort by match score
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return results;
  }

  /// Get detailed course information
  static Future<EnhancedCourseDetails?> getCourseDetails(int year, int semester, String courseId) async {
    final allCourses = await getAllCourses(year, semester);
    
    for (final courseData in allCourses) {
      final general = courseData['general'] as Map<String, dynamic>;
      if (general['מספר מקצוע'] == courseId) {
        return EnhancedCourseDetails.fromSapJson(courseData);
      }
    }
    return null;
  }

  /// Get courses by faculty
  static Future<List<EnhancedCourseDetails>> getCoursesByFaculty(int year, int semester, String faculty) async {
    final searchResults = await searchCourses(
      year: year,
      semester: semester,
      faculty: faculty,
    );
    return searchResults.map((result) => result.course).toList();
  }

  /// Get prerequisites for a course
  static Future<List<String>> getCoursePrerequisites(int year, int semester, String courseId) async {
    final course = await getCourseDetails(year, semester, courseId);
    if (course == null || course.prerequisites.isEmpty) return [];
    
    // Parse prerequisites string to extract course IDs
    final prerequisiteIds = <String>[];
    final regex = RegExp(r'\b\d{8}\b'); // 8-digit course IDs
    final matches = regex.allMatches(course.prerequisites);
    
    for (final match in matches) {
      prerequisiteIds.add(match.group(0)!);
    }
    
    return prerequisiteIds;
  }

  /// Check for schedule conflicts
  static bool hasScheduleConflict(List<ScheduleEntry> schedule1, List<ScheduleEntry> schedule2) {
    for (final entry1 in schedule1) {
      for (final entry2 in schedule2) {
        if (entry1.day == entry2.day && _timesOverlap(entry1.time, entry2.time)) {
          return true;
        }
      }
    }
    return false;
  }

  static double _calculateMatchScore(EnhancedCourseDetails course, String? courseId, String? courseName) {
    double score = 0.0;
    
    if (courseId != null && course.courseNumber.toLowerCase().contains(courseId.toLowerCase())) {
      score += 10.0;
      if (course.courseNumber.toLowerCase().startsWith(courseId.toLowerCase())) {
        score += 5.0; // Boost for prefix matches
      }
    }
    
    if (courseName != null && course.name.toLowerCase().contains(courseName.toLowerCase())) {
      score += 8.0;
    }
    
    return score;
  }
  static bool _timesOverlap(String time1, String time2) {
    // Parse time strings like "14:30 - 16:30" and check for overlap
    final timeRange1 = _parseTimeRange(time1);
    final timeRange2 = _parseTimeRange(time2);
    
    if (timeRange1 == null || timeRange2 == null) return false;
    
    // Check if ranges overlap: start1 < end2 && start2 < end1
    return timeRange1.start < timeRange2.end && timeRange2.start < timeRange1.end;
  }

  static TimeRange? _parseTimeRange(String timeStr) {
    final parts = timeStr.split(' - ');
    if (parts.length != 2) return null;
    
    final start = _parseTimeString(parts[0]);
    final end = _parseTimeString(parts[1]);
    if (start == null || end == null) return null;
    
    return TimeRange(start, end);
  }

  static int? _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }


  static int semesterOrderValue(int semesterCode) {
  // 200 = Winter, 201 = Spring, 202 = Summer
  switch (semesterCode) {
    case 200: return 0; // Winter
    case 201: return 1; // Spring
    case 202: return 2; // Summer
    default: return 3;
  }
}

static int compareSemesters(SemesterInfo a, SemesterInfo b) {
if (a.year != b.year) {
    return a.year.compareTo(b.year);
  } else {
    return semesterOrderValue(a.semester).compareTo(semesterOrderValue(b.semester));
  }
}

}

// Enhanced models with all available data
class EnhancedCourseDetails {
  final String courseNumber;
  final String name;
  final String syllabus;
  final String faculty;
  final String academicLevel;
  final String prerequisites;
  final String adjacentCourses;
  final String noAdditionalCredit;
  final String points;
  final String responsible;
  final String notes;
  final Map<String, String> exams;
  final List<ScheduleEntry> schedule;

  EnhancedCourseDetails({
    required this.courseNumber,
    required this.name,
    required this.syllabus,
    required this.faculty,
    required this.academicLevel,
    required this.prerequisites,
    required this.adjacentCourses,
    required this.noAdditionalCredit,
    required this.points,
    required this.responsible,
    required this.notes,
    required this.exams,
    required this.schedule,
  });

  factory EnhancedCourseDetails.fromSapJson(Map<String, dynamic> json) {
    final general = json['general'] as Map<String, dynamic>;
    final scheduleList = json['schedule'] as List<dynamic>;
    
    // Parse exams
    final exams = <String, String>{};
    final examKeys = ['מועד א', 'מועד ב', 'מועד ג', 'בוחן מועד א', 'בוחן מועד ב'];
    for (final key in examKeys) {
      if (general.containsKey(key) && general[key].toString().isNotEmpty) {
        exams[key] = general[key].toString();
      }
    }
    
    return EnhancedCourseDetails(
      courseNumber: general['מספר מקצוע'] ?? '',
      name: general['שם מקצוע'] ?? '',
      syllabus: general['סילבוס'] ?? '',
      faculty: general['פקולטה'] ?? '',
      academicLevel: general['מסגרת לימודים'] ?? '',
      prerequisites: general['מקצועות קדם'] ?? '',
      adjacentCourses: general['מקצועות צמודים'] ?? '',
      noAdditionalCredit: general['מקצועות ללא זיכוי נוסף'] ?? '',
      points: general['נקודות'] ?? '',
      responsible: general['אחראים'] ?? '',
      notes: general['הערות'] ?? '',
      exams: exams,
      schedule: scheduleList.map((s) => ScheduleEntry.fromJson(s)).toList(),
    );
  }

  // Helper methods
  bool get hasPrerequisites => prerequisites.isNotEmpty;
  bool get hasExams => exams.isNotEmpty;
  double get creditPoints => double.tryParse(points) ?? 0.0;
  
  List<String> get scheduleDays => schedule.map((s) => s.day).toSet().toList();
  
  String get scheduleString {
    if (schedule.isEmpty) return 'לא מתוכנן';
    return schedule.map((s) => '${s.day} ${s.time}').join(', ');
  }
}

class SemesterInfo {
  final int year;
  final int semester;
  final String startDate;
  final String endDate;

  SemesterInfo({
    required this.year,
    required this.semester,
    required this.startDate,
    required this.endDate,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      year: json['year'],
      semester: json['semester'],
      startDate: json['start'],
      endDate: json['end'],
    );
  }

  String get semesterName {
    switch (semester) {
      case 200: return 'Winter $year-${year + 1}';
      case 201: return 'Spring $year';
      case 202: return 'Summer $year';
      default: return 'Semester $semester $year';
    }
  }

  String get semesterKey => semesterName.replaceAll(' ', ' ');
}

class CourseSearchResult {
  final EnhancedCourseDetails course;
  final double matchScore;

  CourseSearchResult({
    required this.course,
    required this.matchScore,
  });
}

// Enhanced schedule entry with all available data
class ScheduleEntry {
  final int group;
  final String type;
  final String day;
  final String time;
  final String building;
  final int room;
  final String staff;
  final int eventId;

  ScheduleEntry({
    required this.group,
    required this.type,
    required this.day,
    required this.time,
    required this.building,
    required this.room,
    required this.staff,
    required this.eventId,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      group: json['קבוצה'] ?? 0,
      type: json['סוג'] ?? '',
      day: json['יום'] ?? '',
      time: json['שעה'] ?? '',
      building: json['בניין'] ?? '',
      room: json['חדר'] ?? 0,
      staff: json['מרצה/מתרגל'] ?? '',
      eventId: json['מס.'] ?? 0,
    );
  }

  String get fullLocation {
    if (building.isEmpty) return '';
    if (room == 0) return building;
    return '$building-$room';
  }

  bool get hasStaff => staff.isNotEmpty;
}

// Helper class for time range operations
class TimeRange {
  final int start;
  final int end;

  TimeRange(this.start, this.end);
}