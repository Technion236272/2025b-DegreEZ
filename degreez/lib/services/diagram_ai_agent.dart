import 'dart:convert';
import 'dart:io';
import 'pdf_service.dart';
import 'ai/base_ai_service.dart';
import 'ai/ai_config.dart';
import 'ai/ai_utils.dart';

class DiagramAiAgent extends BaseAiService {
  Map<String, dynamic>? _extractedCourseData;
  DiagramAiAgent() : super(
    modelName: AiConfig.defaultModel,
    systemInstruction: "${AiConfig.documentAnalysisInstruction} "
        "Analyze the provided PDF document and extract all course information into a structured JSON format. "
        "The JSON should have a 'courses' array where each course object contains: "
        "- courseId: the course identifier (e.g., '0094252', '0094041') "
        "- Name: the full course name "
        "- Credit_points: numeric value of credit points "
        "- Final_grade: the grade received (if available) "
        "- Semester: the semester season only (e.g., 'Fall', 'Spring', 'Winter', 'Summer') "
        "- Year: the academic year (e.g., '2023-2024' for academic year or '2024' for calendar year) "
        "IMPORTANT: Separate semester and year into different fields. "
        "If you see '2022-2023 Winter', extract Semester as 'Winter' and Year as '2022-2023'. "
        "Extract exactly as shown in the original format. Be precise with course IDs and names.",
    generationConfig: AiUtils.createJsonConfig(AiUtils.createCourseExtractionSchema()),
  );
  /// Step 1: Import a PDF file (grade sheet) using existing PdfService
  Future<File?> importPdfFile() async {
    try {
      // Use the existing PdfService which already handles validation and size checks
      return await PdfService.pickPdfFile();
    } catch (e) {
      throw Exception('Failed to import PDF file: ${e.toString()}');
    }
  }
  /// Step 2: Send the PDF file with the extraction prompt to Gemini
  Future<Map<String, dynamic>> extractCourseDataFromPdf(File pdfFile) async {
    try {
      // Read PDF as bytes
      final pdfBytes = await pdfFile.readAsBytes();
        // Create the specific prompt for course data extraction
      const prompt = "Can you create a JSON file where keys are the course IDs and the values are the rest of content about each course? "
                   "Extract all course information from this grade sheet. For each course, include: "
                   "- courseId: the exact course ID (like '0094252', '0094041') "
                   "- Name: the complete course name "
                   "- Credit_points: the credit value as a number "
                   "- Final_grade: the grade received (if shown) "
                   "- Semester: ONLY the semester season (like 'Fall', 'Spring', 'Winter', 'Summer') "
                   "- Year: ONLY the academic year (like '2022-2023' or '2024') "
                   "CRITICAL: If you see something like '2022-2023 Winter', split it into Semester: 'Winter' and Year: '2022-2023'. "
                   "Structure it as a courses array with these exact field names. Be precise and extract exactly as shown.";
        // Use base class method for content generation with file
      final response = await generateContentWithFile(
        prompt: prompt,
        fileBytes: pdfBytes,
        mimeType: AiConfig.pdfMimeType,
      );
      
      if (response.text != null && response.text!.isNotEmpty) {
        // Parse the JSON response
        final jsonData = json.decode(response.text!);
        
        // Step 3: Save the reply in JSON format in a variable
        _extractedCourseData = jsonData;
        
        return jsonData;
      } else {
        throw Exception('No response received from AI model');
      }    } catch (e) {
      final errorMessage = AiUtils.handleAiError(e);
      throw Exception('Failed to extract course data: $errorMessage');
    }
  }

  /// Get the extracted course data (Step 3 result)
  Map<String, dynamic>? get extractedCourseData => _extractedCourseData;

  /// Clear the extracted data
  void clearExtractedData() {
    _extractedCourseData = null;
  }

  /// Complete workflow: Import PDF and extract course data
  Future<Map<String, dynamic>?> processGradeSheet() async {
    try {
      // Step 1: Import PDF file
      final pdfFile = await importPdfFile();
      if (pdfFile == null) {
        return null; // User cancelled file selection
      }

      // Step 2 & 3: Extract and save course data
      final courseData = await extractCourseDataFromPdf(pdfFile);
      
      return courseData;
    } catch (e) {
      rethrow; // Let the UI handle the error display
    }
  }  /// Convert extracted data to a format suitable for the app's course models
  List<Map<String, dynamic>> getCoursesForApp() {
    if (_extractedCourseData == null || _extractedCourseData!['courses'] == null) {
      return [];
    }

    final courses = _extractedCourseData!['courses'] as List<dynamic>;
    return _normalizeCoursesData(courses);
  }

  /// Get courses organized by semester and year
  Map<String, List<Map<String, dynamic>>> getCoursesBySemester() {
    final courses = getCoursesForApp();
    final Map<String, List<Map<String, dynamic>>> coursesBySemester = {};

    for (final course in courses) {
      final semester = course['Semester'] as String? ?? 'Unknown';
      final year = course['Year'] as String? ?? '';
      
      // Create a combined key for better organization
      String semesterKey;
      if (year.isNotEmpty && semester != 'Unknown') {
        semesterKey = '$year $semester';
      } else if (year.isNotEmpty) {
        semesterKey = year;
      } else if (semester != 'Unknown') {
        semesterKey = semester;
      } else {
        semesterKey = 'Unknown Semester';
      }
      
      if (!coursesBySemester.containsKey(semesterKey)) {
        coursesBySemester[semesterKey] = [];
      }
      coursesBySemester[semesterKey]!.add(course);
    }

    // Sort semester keys chronologically
    final sortedKeys = coursesBySemester.keys.toList()
      ..sort(_compareSemesterKeys);
    
    final sortedCoursesBySemester = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      sortedCoursesBySemester[key] = coursesBySemester[key]!;
    }

    return sortedCoursesBySemester;
  }

  /// Compare semester keys for chronological sorting
  int _compareSemesterKeys(String a, String b) {
    // Extract year from semester key
    final yearRegex = RegExp(r'(\d{4}(-\d{4})?|\d{4})');
    final yearMatchA = yearRegex.firstMatch(a);
    final yearMatchB = yearRegex.firstMatch(b);
    
    if (yearMatchA != null && yearMatchB != null) {
      final yearA = yearMatchA.group(1)!;
      final yearB = yearMatchB.group(1)!;
      
      // Compare years first
      final yearComparison = yearA.compareTo(yearB);
      if (yearComparison != 0) return yearComparison;
      
      // If same year, compare semesters
      const semesterOrder = ['Fall', 'Winter', 'Spring', 'Summer'];
      final semesterA = _extractSemesterFromKey(a);
      final semesterB = _extractSemesterFromKey(b);
      
      final indexA = semesterOrder.indexOf(semesterA);
      final indexB = semesterOrder.indexOf(semesterB);
      
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }
    }
    
    // Fallback to alphabetical
    return a.compareTo(b);
  }

  /// Extract semester name from semester key
  String _extractSemesterFromKey(String key) {
    const semesters = ['Fall', 'Winter', 'Spring', 'Summer'];
    for (final semester in semesters) {
      if (key.contains(semester)) return semester;
    }
    return '';
  }

  /// Export extracted data as formatted JSON string
  String exportAsJson({bool prettyPrint = true}) {
    if (_extractedCourseData == null) {
      return '{}';
    }

    if (prettyPrint) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(_extractedCourseData);
    } else {
      return json.encode(_extractedCourseData);
    }
  }
  /// Validates and normalizes course data for consistent display
  List<Map<String, dynamic>> _normalizeCoursesData(List<dynamic> courses) {
    return courses.map((course) {
      if (course is! Map<String, dynamic>) {
        return <String, dynamic>{};
      }
      
      // Handle legacy semester format (e.g., "2022-2023 Winter" -> Semester: "Winter", Year: "2022-2023")
      String semester = course['Semester']?.toString() ?? 'Unknown';
      String year = course['Year']?.toString() ?? '';
      
      // If semester contains year information, split it
      if (semester.contains(' ') && year.isEmpty) {
        final parts = semester.split(' ');
        if (parts.length >= 2) {
          // Check if first part looks like a year (contains digits and possibly dash)
          if (parts[0].contains(RegExp(r'\d'))) {
            year = parts[0];
            semester = parts.sublist(1).join(' ');
          } else {
            // Last part might be the year
            year = parts.last.contains(RegExp(r'\d')) ? parts.last : '';
            semester = parts.sublist(0, parts.length - (year.isEmpty ? 0 : 1)).join(' ');
          }
        }
      }
      
      return <String, dynamic>{
        'courseId': course['courseId']?.toString() ?? 'N/A',
        'Name': course['Name']?.toString() ?? 'Unknown Course',
        'Credit_points': _parseNumber(course['Credit_points']),
        'Final_grade': course['Final_grade']?.toString() ?? '',
        'Semester': semester.trim(),
        'Year': year.trim(),
      };
    }).where((course) => course['courseId'] != 'N/A').toList();
  }
  
  /// Helper method to safely parse numbers
  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
  /// Get summary statistics of extracted courses
  Map<String, dynamic> getExtractionSummary() {
    final courses = getCoursesForApp();
    final coursesBySemester = getCoursesBySemester();
    final coursesByYear = getCoursesByYear();
    final uniqueYears = getUniqueYears();
    final uniqueSemesters = getUniqueSemesters();
    
    // Calculate total credits
    final totalCredits = courses.fold<double>(
      0.0, 
      (sum, course) => sum + (course['Credit_points'] as double? ?? 0.0)
    );
    
    // Count courses with grades
    final coursesWithGrades = courses.where(
      (course) => course['Final_grade']?.toString().isNotEmpty == true
    ).length;
    
    return {
      'totalCourses': courses.length,
      'totalSemesters': coursesBySemester.length,
      'totalCredits': totalCredits,
      'coursesWithGrades': coursesWithGrades,
      'coursesWithoutGrades': courses.length - coursesWithGrades,
      'uniqueYears': uniqueYears,
      'uniqueSemesters': uniqueSemesters,
      'yearRange': uniqueYears.isEmpty ? '' : '${uniqueYears.first} - ${uniqueYears.last}',
      'semesterBreakdown': coursesBySemester.map(
        (semester, courses) => MapEntry(semester, courses.length)
      ),
      'yearBreakdown': coursesByYear.map(
        (year, courses) => MapEntry(year, courses.length)
      ),
    };
  }

  /// Get courses organized by year only
  Map<String, List<Map<String, dynamic>>> getCoursesByYear() {
    final courses = getCoursesForApp();
    final Map<String, List<Map<String, dynamic>>> coursesByYear = {};

    for (final course in courses) {
      final year = course['Year'] as String? ?? 'Unknown Year';
      
      if (!coursesByYear.containsKey(year)) {
        coursesByYear[year] = [];
      }
      coursesByYear[year]!.add(course);
    }

    // Sort years
    final sortedKeys = coursesByYear.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    final sortedCoursesByYear = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      sortedCoursesByYear[key] = coursesByYear[key]!;
    }

    return sortedCoursesByYear;
  }

  /// Get courses organized by semester season only
  Map<String, List<Map<String, dynamic>>> getCoursesBySemesterSeason() {
    final courses = getCoursesForApp();
    final Map<String, List<Map<String, dynamic>>> coursesBySeason = {};

    for (final course in courses) {
      final semester = course['Semester'] as String? ?? 'Unknown Semester';
      
      if (!coursesBySeason.containsKey(semester)) {
        coursesBySeason[semester] = [];
      }
      coursesBySeason[semester]!.add(course);
    }

    return coursesBySeason;
  }

  /// Get unique years from extracted courses
  List<String> getUniqueYears() {
    final courses = getCoursesForApp();
    final years = courses
        .map((course) => course['Year'] as String? ?? '')
        .where((year) => year.isNotEmpty)
        .toSet()
        .toList();
    
    years.sort();
    return years;
  }

  /// Get unique semesters from extracted courses
  List<String> getUniqueSemesters() {
    final courses = getCoursesForApp();
    final semesters = courses
        .map((course) => course['Semester'] as String? ?? '')
        .where((semester) => semester.isNotEmpty && semester != 'Unknown')
        .toSet()
        .toList();
    
    // Sort by typical semester order
    const semesterOrder = ['Fall', 'Winter', 'Spring', 'Summer'];
    semesters.sort((a, b) {
      final indexA = semesterOrder.indexOf(a);
      final indexB = semesterOrder.indexOf(b);
      
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }
      return a.compareTo(b);
    });
    
    return semesters;
  }
}
