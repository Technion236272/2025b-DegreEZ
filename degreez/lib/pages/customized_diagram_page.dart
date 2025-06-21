// lib/pages/degree_progress_page.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/widgets/semester_timeline.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/course_card.dart';
import '../widgets/add_course_dialog.dart';
import '../services/diagram_ai_agent.dart';
import '../services/GlobalConfigService.dart';
import '../services/course_service.dart';

// Data structure to track course addition results
class CourseAdditionResult {
  final String semesterName;
  final String courseId;
  final String courseName;
  final bool isSuccess;
  final String? errorMessage;
  final bool wasUpdated; // true if course existed and was updated, false if newly added

  CourseAdditionResult({
    required this.semesterName,
    required this.courseId,
    required this.courseName,
    required this.isSuccess,
    this.errorMessage,
    this.wasUpdated = false,
  });
}

// Summary data structure
class ImportSummary {
  final int totalCourses;
  final int successfullyAdded;
  final int successfullyUpdated;
  final int failed;
  final int semestersAdded;
  final List<CourseAdditionResult> results;

  ImportSummary({
    required this.totalCourses,
    required this.successfullyAdded,
    required this.successfullyUpdated,
    required this.failed,
    required this.semestersAdded,
    required this.results,
  });

  int get totalSuccess => successfullyAdded + successfullyUpdated;
}

class CustomizedDiagramPage extends StatefulWidget {
  const CustomizedDiagramPage({super.key});

  @override
  State<CustomizedDiagramPage> createState() => _CustomizedDiagramPageState();
}

class _CustomizedDiagramPageState extends State<CustomizedDiagramPage> {
  late ScrollController _scrollController;
  final List<GlobalKey> _semesterKeys = [];
  int _currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get responsive grid count
  int _getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 6;
    if (screenWidth > 800) return 5;
    if (screenWidth > 600) return 4;
    return 3;
  }

  // Helper method to scroll to specific semester
  void _scrollToSemester(int index) {
    if (index < _semesterKeys.length &&
        _semesterKeys[index].currentContext != null) {
      final context = _semesterKeys[index].currentContext!;
      final renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      _scrollController.animateTo(
        _scrollController.offset +
            position.dy -
            150, // Account for timeline height
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentSemesterIndex = index;
      });
    }
  }

  // Helper method to build timeline data
  List<SemesterTimelineData> _buildTimelineData(
    Map<String, List<StudentCourse>> semesters,
  ) {
    return semesters.entries.map((entry) {
      final courses = entry.value;
      final completedCourses =
          courses.where((c) => c.finalGrade.isNotEmpty).length;

      // Calculate total credits by summing up credit points from all courses
      final totalCredits = courses.fold<double>(
        0.0,
        (sum, course) => sum + course.creditPoints,
      );

      SemesterStatus status;
      if (courses.isEmpty) {
        status = SemesterStatus.empty;
      } else if (completedCourses == courses.length) {
        status = SemesterStatus.completed;
      } else if (completedCourses > 0) {
        status = SemesterStatus.current;
      } else {
        status = SemesterStatus.planned;
      }

      return SemesterTimelineData(
        name: entry.key,
        status: status,
        completedCourses: completedCourses,
        totalCourses: courses.length,
        totalCredits: totalCredits,
      );
    }).toList();
  }

  // Enhanced: Callback to refresh UI when course is updated
  void _onCourseUpdated() {
    setState(() {
      // This will trigger a rebuild and refresh the course data
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CustomizedDiagramNotifier(),
      child: Scaffold(
        backgroundColor: AppColorsDarkMode.mainColor,
        body: Consumer2<StudentProvider, CourseProvider>(
          builder: (context, studentNotifier, courseNotifier, _) {
            final courseNotifier = context.read<CourseProvider>();
            if (studentNotifier.isLoading && studentNotifier.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (studentNotifier.error != '' && studentNotifier.error != null) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDarkMode.mainColor,
                        AppColorsDarkMode.accentColorDarker,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsDarkMode.shadowColor,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: AppColorsDarkMode.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${studentNotifier.error}',
                        style: TextStyle(
                          color: AppColorsDarkMode.errorColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }            final semesters = courseNotifier.sortedCoursesBySemester;
            if (semesters.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDarkMode.mainColor,
                        AppColorsDarkMode.accentColorDarker,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsDarkMode.shadowColorStrong,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 64,
                        color: AppColorsDarkMode.secondaryColor,
                      ),                      SizedBox(height: 16),
                      Text(
                        'No courses to display',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add courses to see your degree progress',
                        style: TextStyle(
                          color: AppColorsDarkMode.secondaryColorDim,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Ensure we have enough keys for the semesters
            while (_semesterKeys.length < semesters.length) {
              _semesterKeys.add(GlobalKey());
            }

            // Detect device orientation
            final orientation = MediaQuery.of(context).orientation;

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add the semester timeline
                  SemesterTimeline(
                    semesters: _buildTimelineData(semesters),
                    currentSemesterIndex: _currentSemesterIndex,
                    onSemesterTap: _scrollToSemester,
                  ),

                  // Enhanced: Updated instruction text
                  Padding(
                    padding: EdgeInsets.only(left: 25, top: 10, bottom: 5),
                    child: AutoSizeText(
                      'Tap a course for quick actions \nLong press to view prerequisites'
                      '\n(Long press the same course to disable prerequisites view)',
                      style: TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                      minFontSize: 10,
                      maxFontSize: 14,
                      maxLines: 3,
                    ),
                  ),

                  // Semester list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: semesters.length,
                      itemBuilder: (context, index) {
                        final semesterKey = semesters.keys.elementAt(index);
                        final semester = {
                          'semester': index + 1,
                          'name': semesterKey,
                          'courses': semesters[semesterKey]!,
                        };

                        return Container(
                          key: _semesterKeys[index],
                          child:
                              orientation == Orientation.portrait
                                  ? _buildVerticalSemesterSection(
                                    context,
                                    semester,
                                    studentNotifier,
                                  )
                                  : _buildVerticalSemesterSection(
                                    context,
                                    semester,
                                    studentNotifier,
                                  ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // AI Grade Sheet Import Button
            FloatingActionButton(
              heroTag: "ai_import",
              onPressed: () => _showAiImportDialog(context),
              backgroundColor: AppColorsDarkMode.primaryColor,
              child: const Icon(Icons.smart_toy),
              tooltip: 'Import Grade Sheet with AI',
            ),
            const SizedBox(height: 12),
            // Add Semester Button
            FloatingActionButton(
              heroTag: "add_semester",
              onPressed: () {
                _showAddSemesterDialog(context);
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Semester',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSemesterDialog(BuildContext context) async {
    String? selectedSeason = await GlobalConfigService.getCurrentSemester();
    int currentYear = DateTime.now().year;
    String selectedYear =
        selectedSeason == 'Winter'
            ? '${currentYear - 1}-$currentYear'
            : '$currentYear';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: AppColorsDarkMode.secondaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: AppColorsDarkMode.accentColor,
              title: const Text(
                'Add New Semester',
                style: TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Season Dropdown
                  DropdownButtonFormField<String>(
                    iconEnabledColor: AppColorsDarkMode.secondaryColor,
                    value: selectedSeason,
                    style: const TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      labelStyle: const TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColorsDarkMode.borderPrimary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColorsDarkMode.surfaceColor,
                    ),
                    dropdownColor: AppColorsDarkMode.surfaceColor,
                    items:
                        ['Winter', 'Spring', 'Summer'].map((season) {
                          return DropdownMenuItem<String>(
                            value: season,
                            child: Text(
                              season,
                              style: const TextStyle(
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSeason = value;
                          selectedYear =
                              value == 'Winter'
                                  ? '${currentYear - 1}-$currentYear'
                                  : '$currentYear';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Year Dropdown
                  DropdownButtonFormField<String>(
                    iconEnabledColor: AppColorsDarkMode.secondaryColor,
                    value: selectedYear,
                    style: const TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Year',
                      labelStyle: const TextStyle(
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColorsDarkMode.borderPrimary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColorsDarkMode.surfaceColor,
                    ),
                    dropdownColor: AppColorsDarkMode.surfaceColor,
                    items: List.generate(11, (index) {
                      int baseYear = currentYear - 5 + index;
                      final yearLabel =
                          selectedSeason == 'Winter'
                              ? '${baseYear}-${baseYear + 1}'
                              : '$baseYear';
                      return DropdownMenuItem<String>(
                        value: yearLabel,
                        child: Text(
                          yearLabel,
                          style: const TextStyle(
                            color: AppColorsDarkMode.secondaryColor,
                          ),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColorDim,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final semesterName = '$selectedSeason $selectedYear';
                    context.read<CourseProvider>().addSemester(
                      context.read<StudentProvider>().student!.id,
                      semesterName,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Vertical layout for portrait mode - enhanced with responsive grid and update callback
  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentProvider studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = context
        .read<CourseProvider>()
        .getTotalCreditsForSemester(semesterName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsDarkMode.mainColor,
                AppColorsDarkMode.accentColorDarker,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColorsDarkMode.shadowColorStrong,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semesterName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColorsDarkMode.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${totalCredits.toStringAsFixed(1)} credits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColorsDarkMode.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    tooltip: 'Add Course',
                    onPressed: () {
                      AddCourseDialog.show(
                        context,
                        semesterName,
                        onCourseAdded: (_) => _onCourseUpdated(),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    tooltip: 'Delete Semester',
                    onPressed: () {
                      _confirmDeleteSemester(
                        context,
                        semesterName,
                        studentNotifier.student!.id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ), // Display message if no courses
        courses.isEmpty
            ? Container(
              margin: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 8.0,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsDarkMode.borderPrimary,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsDarkMode.shadowColor,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'No courses in this semester',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ),
            )
            : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(
                  context,
                ), // Enhanced: responsive grid
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final courseWithDetails = context
                    .read<CourseProvider>()
                    .getCourseWithDetails(semesterName, course.courseId);
                return CourseCard(
                  direction: DirectionValues.vertical,
                  course: course,
                  courseDetails: courseWithDetails?.courseDetails,
                  semester: semesterName,
                  onCourseUpdated:
                      _onCourseUpdated, // Enhanced: Add update callback
                );
              },
            ),
      ],
    );
  }

  void _confirmDeleteSemester(
    BuildContext context,
    String semesterName,
    String studentId,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: AppColorsDarkMode.secondaryColorDim,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColorsDarkMode.accentColorDark,
            title: const Text(
              'Delete Semester',
              style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
            content: Text(
              'Are you sure you want to delete "$semesterName"? This will remove all courses in it.',
              style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Provider.of<CourseProvider>(
                    context,
                    listen: false,
                  ).deleteSemester(studentId, semesterName);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  // Enhanced: Trigger UI refresh
                  _onCourseUpdated();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Enhanced: AI Grade Sheet Import Dialog
  void _showAiImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.smart_toy,
              color: AppColorsDarkMode.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 0),
            Text(
              'AI Grade Sheet Import',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
              
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import your courses automatically from a grade sheet or transcript PDF.',
                style: TextStyle(color: AppColorsDarkMode.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorsDarkMode.borderPrimary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        color: AppColorsDarkMode.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Select a PDF grade sheet or transcript\n'
                      '2. AI extracts course information automatically\n'
                      '3. Review and import the extracted courses',
                      style: TextStyle(
                        color: AppColorsDarkMode.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startAiImport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('Start Import'),
          ),
        ],
      ),
    );
  }
  // Enhanced: Start AI Import Process
  void _startAiImport() async {
    try {
      _showSnackBar('Starting AI grade sheet import...', isLoading: true);
      
      final aiAgent = DiagramAiAgent();
      final courseData = await aiAgent.processGradeSheet();
      
      if (courseData != null) {
        final courses = aiAgent.getCoursesForApp();
        _showSnackBar('Successfully extracted ${courses.length} courses!', isSuccess: true);
        
        // Add courses and get summary
        final summary = await _addCoursesToUser(courses);
        
        // Show the results dialog
        _displayExtractedCoursesDialog(summary, aiAgent);

      } else {
        _showSnackBar('Import cancelled by user.');
      }
    } catch (e) {
      _showSnackBar('Error during AI import: ${e.toString()}', isError: true);
    }
  }

  // Method to add AI-imported courses to user's account using existing functionality
  Future<ImportSummary> _addCoursesToUser(List<Map<String, dynamic>> courses) async {
    final List<CourseAdditionResult> results = [];
    
    if (courses.isEmpty) {
      return ImportSummary(
        totalCourses: 0,
        successfullyAdded: 0,
        successfullyUpdated: 0,
        failed: 0,
        semestersAdded: 0,
        results: [],
      );
    }
    
    try {
      final courseProvider = context.read<CourseProvider>();
      final studentProvider = context.read<StudentProvider>();
      final studentId = studentProvider.student?.id;
      
      if (studentId == null) {
        _showSnackBar('Student ID not found', isError: true);
        return ImportSummary(
          totalCourses: courses.length,
          successfullyAdded: 0,
          successfullyUpdated: 0,
          failed: courses.length,
          semestersAdded: 0,
          results: courses.map((course) => CourseAdditionResult(
            semesterName: 'Unknown',
            courseId: course['courseId'] as String? ?? 'Unknown',
            courseName: course['Name'] as String? ?? 'Unknown Course',
            isSuccess: false,
            errorMessage: 'Student ID not found',
          )).toList(),
        );
      }

      // Group courses by semester/year
      final Map<String, List<Map<String, dynamic>>> coursesBySemester = {};
      
      for (final course in courses) {
        final semester = course['Semester'] as String? ?? 'Unknown';
        final year = course['Year'] as String? ?? 'Unknown';
        // Extract the right year from "YYYY-YYYY" format (e.g., "2024-2025" -> "2025")
        final rightYear = year.contains('-') ? year.split('-').last.trim() : year;
        final semesterKey = (semester == "Winter") ? '$semester $year' : '$semester $rightYear';

        coursesBySemester.putIfAbsent(semesterKey, () => []);
        coursesBySemester[semesterKey]!.add(course);
      }

      int totalCoursesAdded = 0;
      int totalCoursesUpdated = 0;
      int totalSemestersAdded = 0;

      // Process each semester
      for (final entry in coursesBySemester.entries) {
        final semesterName = entry.key;
        final semesterCourses = entry.value;
        
        // Check if semester already exists
        bool semesterExists = courseProvider.sortedCoursesBySemester.containsKey(semesterName);
        
        // Add semester if it doesn't exist (using existing FAB functionality)
        if (!semesterExists) {
          final success = await courseProvider.addSemester(studentId, semesterName);
          if (success) {
            totalSemestersAdded++;
            _showSnackBar('Added semester: $semesterName');
          } else {
            _showSnackBar('Failed to add semester: $semesterName', isError: true);
            // Add failed results for all courses in this semester
            for (final courseData in semesterCourses) {
              results.add(CourseAdditionResult(
                semesterName: semesterName,
                courseId: courseData['courseId'] as String? ?? 'Unknown',
                courseName: courseData['Name'] as String? ?? 'Unknown Course',
                isSuccess: false,
                errorMessage: 'Failed to create semester',
              ));
            }
            continue; // Skip courses for this semester if semester creation failed
          }
        }
        
        // Add courses to the semester (replicating AddCourseDialog functionality)
        for (final courseData in semesterCourses) {
          final courseId = courseData['courseId'] as String? ?? '';
          final courseName = courseData['Name'] as String? ?? 'Unknown Course';
          final grade = courseData['Final_grade'] as String? ?? '';

          
          // Check if course already exists in this semester
          final existingCourses = courseProvider.getCoursesForSemester(semesterName);
          final courseExists = existingCourses.any((c) => c.courseId == courseId);
          
          if (courseExists) {
            // If course exists, just update the grade
            if (grade.isNotEmpty) {
              final success = await courseProvider.updateCourseGrade(
                studentId, 
                semesterName, 
                courseId, 
                grade
              );
              if (success) {
                totalCoursesUpdated++;
                results.add(CourseAdditionResult(
                  semesterName: semesterName,
                  courseId: courseId,
                  courseName: courseName,
                  isSuccess: true,
                  wasUpdated: true,
                ));
              } else {
                results.add(CourseAdditionResult(
                  semesterName: semesterName,
                  courseId: courseId,
                  courseName: courseName,
                  isSuccess: false,
                  errorMessage: 'Failed to update grade',
                  wasUpdated: true,
                ));
              }
            } else {
              results.add(CourseAdditionResult(
                semesterName: semesterName,
                courseId: courseId,
                courseName: courseName,
                isSuccess: true,
                wasUpdated: true,
                errorMessage: 'Course already exists (no grade to update)',
              ));
            }
          } else {
            // Search for course details (same as AddCourseDialog)
            final fallbackSemester = await courseProvider.getClosestAvailableSemester(semesterName);
            final searchResults = await courseProvider.searchCourses(
              courseId: courseId,
              selectedSemester: fallbackSemester,
            );
            
            // Find the course in search results
            EnhancedCourseDetails? courseDetails;
            for (final result in searchResults) {
              if (result.course.courseNumber == courseId) {
                courseDetails = result.course;
                break;
              }
            }
            
            if (courseDetails != null) {
              // Create StudentCourse from EnhancedCourseDetails (same as AddCourseDialog)
              final course = StudentCourse(
                courseId: courseDetails.courseNumber,
                name: courseDetails.name,
                finalGrade: grade, // Set the grade from AI import
                lectureTime: '',
                tutorialTime: '',
                labTime: '',
                workshopTime: '',
                creditPoints: courseDetails.creditPoints,
              );

              // Add course to semester (using existing functionality)
              final success = await courseProvider.addCourseToSemester(
                studentId,
                semesterName,
                course,
              );
              
              if (success) {
                totalCoursesAdded++;
                results.add(CourseAdditionResult(
                  semesterName: semesterName,
                  courseId: courseId,
                  courseName: courseName,
                  isSuccess: true,
                ));
              } else {
                results.add(CourseAdditionResult(
                  semesterName: semesterName,
                  courseId: courseId,
                  courseName: courseName,
                  isSuccess: false,
                  errorMessage: 'Failed to add course to semester',
                ));
              }
            } else {
              results.add(CourseAdditionResult(
                semesterName: semesterName,
                courseId: courseId,
                courseName: courseName,
                isSuccess: false,
                errorMessage: 'Course not found in course catalog',
              ));
              _showSnackBar('Course $courseId not found in course catalog');
            }
          }
        }
      }

      // Create and return summary
      final summary = ImportSummary(
        totalCourses: courses.length,
        successfullyAdded: totalCoursesAdded,
        successfullyUpdated: totalCoursesUpdated,
        failed: results.where((r) => !r.isSuccess).length,
        semestersAdded: totalSemestersAdded,
        results: results,
      );

      // Show final summary
      if (summary.totalSuccess > 0 || totalSemestersAdded > 0) {
        _showSnackBar(
          'Import completed! Added $totalSemestersAdded semesters, ${summary.successfullyAdded} new courses, and updated ${summary.successfullyUpdated} existing courses.',
          isSuccess: true
        );
        
        // Trigger UI update
        _onCourseUpdated();
      } else {
        _showSnackBar('No courses were successfully processed.', isError: true);
      }
      
      return summary;
      
    } catch (e) {
      _showSnackBar('Error adding courses: ${e.toString()}', isError: true);
      return ImportSummary(
        totalCourses: courses.length,
        successfullyAdded: 0,
        successfullyUpdated: 0,
        failed: courses.length,
        semestersAdded: 0,
        results: courses.map((course) => CourseAdditionResult(
          semesterName: 'Error',
          courseId: course['courseId'] as String? ?? 'Unknown',
          courseName: course['Name'] as String? ?? 'Unknown Course',
          isSuccess: false,
          errorMessage: e.toString(),
        )).toList(),
      );
    }
  }
  // Enhanced: Show Import Results Dialog
  void _displayExtractedCoursesDialog(ImportSummary summary, DiagramAiAgent aiAgent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [            Icon(
              summary.totalSuccess > 0 ? Icons.check_circle : Icons.warning,
              color: summary.totalSuccess > 0 ? AppColorsDarkMode.successColor : AppColorsDarkMode.warningColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Import Results',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorsDarkMode.borderPrimary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: AppColorsDarkMode.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Import Summary',
                          style: TextStyle(
                            color: AppColorsDarkMode.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),                    Row(
                      children: [
                        _buildSummaryChip('Total Courses', summary.totalCourses.toString(), AppColorsDarkMode.primaryColor),
                        const SizedBox(width: 8),
                        _buildSummaryChip('Added', summary.successfullyAdded.toString(), AppColorsDarkMode.successColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSummaryChip('Updated', summary.successfullyUpdated.toString(), AppColorsDarkMode.warningColor),
                        const SizedBox(width: 8),
                        _buildSummaryChip('Failed', summary.failed.toString(), AppColorsDarkMode.errorColor),
                      ],
                    ),
                    if (summary.semestersAdded > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSummaryChip('New Semesters', summary.semestersAdded.toString(), AppColorsDarkMode.secondaryColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
                // Course Results List
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppColorsDarkMode.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detailed Results:',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildResultsBySemester(summary.results),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),          if (summary.failed > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showFailedCoursesDetail(summary.results.where((r) => !r.isSuccess).toList(), summary, aiAgent);
              },              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsDarkMode.primaryColor,
                foregroundColor: AppColorsDarkMode.textPrimary,
              ),
              child: const Text('Review Failed'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRawJsonDialog(aiAgent, summary);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.surfaceColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('View Raw Data'),
          ),
        ],
      ),
    );
  }

  // Helper method to build summary chips
  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to sort semesters chronologically
  List<MapEntry<String, List<CourseAdditionResult>>> _sortSemestersByYear(
    Map<String, List<CourseAdditionResult>> resultsBySemester
  ) {
    final entries = resultsBySemester.entries.toList();
    
    entries.sort((a, b) {
      final semesterA = a.key;
      final semesterB = b.key;
      
      // Extract year and season from semester name (e.g., "Winter 2023-2024", "Spring 2024")
      final partsA = semesterA.split(' ');
      final partsB = semesterB.split(' ');
      
      if (partsA.length < 2 || partsB.length < 2) return 0;
      
      final seasonA = partsA[0];
      final yearStrA = partsA[1];
      final seasonB = partsB[0];
      final yearStrB = partsB[1];
      
      // Extract year for comparison
      int yearA, yearB;
      
      if (yearStrA.contains('-')) {
        // Winter format: "2023-2024" -> use the second year (2024)
        yearA = int.tryParse(yearStrA.split('-').last) ?? 0;
      } else {
        // Spring/Summer format: "2024" -> use as is
        yearA = int.tryParse(yearStrA) ?? 0;
      }
      
      if (yearStrB.contains('-')) {
        yearB = int.tryParse(yearStrB.split('-').last) ?? 0;
      } else {
        yearB = int.tryParse(yearStrB) ?? 0;
      }
      
      // Compare by year first
      if (yearA != yearB) {
        return yearA.compareTo(yearB);
      }
      
      // If same year, compare by season order: Winter -> Spring -> Summer
      final seasonOrder = {'Winter': 1, 'Spring': 2, 'Summer': 3};
      final orderA = seasonOrder[seasonA] ?? 4;
      final orderB = seasonOrder[seasonB] ?? 4;
      
      return orderA.compareTo(orderB);
    });
    
    return entries;
  }

  // Helper method to build results grouped by semester
  List<Widget> _buildResultsBySemester(List<CourseAdditionResult> results) {
    final Map<String, List<CourseAdditionResult>> resultsBySemester = {};
    
    for (final result in results) {
      resultsBySemester.putIfAbsent(result.semesterName, () => []);
      resultsBySemester[result.semesterName]!.add(result);
    }

    // Sort semesters chronologically by year and season
    final sortedEntries = _sortSemestersByYear(resultsBySemester);

    return sortedEntries.map((entry) {
      final semesterName = entry.key;
      final semesterResults = entry.value;
      final successCount = semesterResults.where((r) => r.isSuccess).length;
      final failedCount = semesterResults.length - successCount;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorsDarkMode.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorsDarkMode.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColorsDarkMode.primaryColor,
                  size: 16,
                ),                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        semesterName,
                        style: TextStyle(
                          color: AppColorsDarkMode.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${semesterResults.length} course${semesterResults.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColorsDarkMode.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (successCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(                      color: AppColorsDarkMode.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$successCount ✓',
                      style: TextStyle(
                        color: AppColorsDarkMode.successColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (failedCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(                      color: AppColorsDarkMode.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$failedCount ✗',
                      style: TextStyle(
                        color: AppColorsDarkMode.errorColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ...semesterResults.map((result) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(                color: result.isSuccess 
                    ? AppColorsDarkMode.successColor.withOpacity(0.1)
                    : AppColorsDarkMode.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: result.isSuccess 
                      ? AppColorsDarkMode.successColor.withOpacity(0.3)
                      : AppColorsDarkMode.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.isSuccess ? Icons.check_circle : Icons.error,
                    color: result.isSuccess ? AppColorsDarkMode.successColor : AppColorsDarkMode.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.courseId}: ${result.courseName}',
                          style: TextStyle(
                            color: AppColorsDarkMode.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (result.errorMessage != null && result.errorMessage!.isNotEmpty)
                          Text(
                            result.errorMessage!,                            style: TextStyle(
                              color: result.isSuccess 
                                  ? AppColorsDarkMode.textSecondary
                                  : AppColorsDarkMode.errorColor,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (result.wasUpdated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.warningColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Updated',
                        style: TextStyle(
                          color: AppColorsDarkMode.warningColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (result.isSuccess)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),                      child: Text(
                        'Added',
                        style: TextStyle(
                          color: AppColorsDarkMode.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            )),
          ],
        ),
      );
    }).toList();
  }
  // Method to show detailed failed courses dialog
  void _showFailedCoursesDetail(List<CourseAdditionResult> failedResults, ImportSummary summary, DiagramAiAgent aiAgent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [                Icon(
                  Icons.error_outline,
                  color: AppColorsDarkMode.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Failed Courses (${failedResults.length})',
                  style: TextStyle(color: AppColorsDarkMode.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Import Results',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColorsDarkMode.textSecondary,
                  size: 16,
                ),
                Text(
                  'Failed Courses',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following courses could not be imported:',
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: failedResults.map((result) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(                        color: AppColorsDarkMode.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColorsDarkMode.errorColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: AppColorsDarkMode.errorColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${result.courseId}: ${result.courseName}',
                                  style: TextStyle(
                                    color: AppColorsDarkMode.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColorsDarkMode.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                result.semesterName,
                                style: TextStyle(
                                  color: AppColorsDarkMode.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (result.errorMessage != null && result.errorMessage!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColorsDarkMode.surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [                                  Icon(
                                    Icons.info_outline,
                                    color: AppColorsDarkMode.warningColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      result.errorMessage!,
                                      style: TextStyle(
                                        color: AppColorsDarkMode.textSecondary,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _displayExtractedCoursesDialog(summary, aiAgent);
            },
            icon: Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColorsDarkMode.textPrimary,
            ),
            label: Text(
              'Back to Summary',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
  // Enhanced: Show Raw JSON Dialog
  void _showRawJsonDialog(DiagramAiAgent aiAgent, ImportSummary summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: AppColorsDarkMode.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Extracted JSON Data',
                  style: TextStyle(color: AppColorsDarkMode.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Import Results',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColorsDarkMode.textSecondary,
                  size: 16,
                ),
                Text(
                  'Raw Data',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
          child: Container(
            decoration: BoxDecoration(
              color: AppColorsDarkMode.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColorsDarkMode.borderPrimary),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                aiAgent.exportAsJson(),
                style: TextStyle(
                  color: AppColorsDarkMode.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _displayExtractedCoursesDialog(summary, aiAgent);
            },
            icon: Icon(
              Icons.arrow_back,
              size: 16,
              color: AppColorsDarkMode.textPrimary,
            ),
            label: Text(
              'Back to Summary',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced: Show SnackBar helper method
  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false, bool isLoading = false}) {
    Color backgroundColor;
    Color textColor = AppColorsDarkMode.textPrimary;
    IconData? icon;    if (isError) {
      backgroundColor = AppColorsDarkMode.errorColor;
      icon = Icons.error;
    } else if (isSuccess) {
      backgroundColor = AppColorsDarkMode.successColor;
      icon = Icons.check_circle;
    } else if (isLoading) {
      backgroundColor = AppColorsDarkMode.primaryColor;
      icon = Icons.hourglass_empty;
    } else {
      backgroundColor = AppColorsDarkMode.surfaceColor;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isLoading ? 2 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
