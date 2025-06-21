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
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
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
            }

            final semesters = courseNotifier.sortedCoursesBySemester;
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
                        color: Colors.black,
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
                      ),
                      SizedBox(height: 16),
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
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
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
              size: 24,
            ),
            const SizedBox(width: 8),
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
        
        // Show the extracted data
        // _showExtractedCoursesDialog(aiAgent);        // for each course here, we use the add method from CourseProvider to add the course to the suitable semester
        // and then update the grade of that course in the user's course list
        await _addCoursesToUser(courses);

      } else {
        _showSnackBar('Import cancelled by user.');
      }
    } catch (e) {
      _showSnackBar('Error during AI import: ${e.toString()}', isError: true);
    }
  }

  // Method to add AI-imported courses to user's account using existing functionality
  Future<void> _addCoursesToUser(List<Map<String, dynamic>> courses) async {
    if (courses.isEmpty) return;
    
    try {
      final courseProvider = context.read<CourseProvider>();
      final studentProvider = context.read<StudentProvider>();
      final studentId = studentProvider.student?.id;
      
      if (studentId == null) {
        _showSnackBar('Student ID not found', isError: true);
        return;
      }

      // Group courses by semester/year
      final Map<String, List<Map<String, dynamic>>> coursesBySemester = {};
      
      for (final course in courses) {
        final semester = course['Semester'] as String? ?? 'Unknown';
        final year = course['Year'] as String? ?? 'Unknown';
        final semesterKey = '$semester $year';
        
        coursesBySemester.putIfAbsent(semesterKey, () => []);
        coursesBySemester[semesterKey]!.add(course);
      }

      int totalCoursesAdded = 0;
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
            continue; // Skip courses for this semester if semester creation failed
          }
        }        // Add courses to the semester (replicating AddCourseDialog functionality)
        for (final courseData in semesterCourses) {
          final courseId = courseData['Course ID'] as String? ?? '';
          final grade = courseData['Grade'] as String? ?? '';
          
          if (courseId.isEmpty) {
            continue; // Skip invalid courses
          }

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
                totalCoursesAdded++;
              }
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
              }
            } else {
              _showSnackBar('Course $courseId not found in course catalog');
            }
          }
        }
      }

      // Show final summary
      if (totalCoursesAdded > 0 || totalSemestersAdded > 0) {
        _showSnackBar(
          'Import completed! Added $totalSemestersAdded semesters and $totalCoursesAdded courses.',
          isSuccess: true
        );
        
        // Trigger UI update
        _onCourseUpdated();
      } else {
        _showSnackBar('No new courses were added. All courses may already exist.', isError: true);
      }
      
    } catch (e) {
      _showSnackBar('Error adding courses: ${e.toString()}', isError: true);
    }
  }

  // Enhanced: Show Extracted Courses Dialog
  void _showExtractedCoursesDialog(DiagramAiAgent aiAgent) {
    final coursesBySemester = aiAgent.getCoursesBySemester();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Courses Extracted',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppColorsDarkMode.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Found ${aiAgent.getCoursesForApp().length} courses organized by semester:',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: coursesBySemester.entries.map((entry) {
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
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.key}',
                                  style: TextStyle(
                                    color: AppColorsDarkMode.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColorsDarkMode.primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${entry.value.length} courses',
                                    style: TextStyle(
                                      color: AppColorsDarkMode.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),...entry.value.map((course) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColorsDarkMode.accentColorDarker,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${course['courseId'] ?? 'N/A'}: ${course['Name'] ?? 'Unknown Course'}',
                                          style: TextStyle(
                                            color: AppColorsDarkMode.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),                                        Row(
                                          children: [
                                            Icon(
                                              Icons.school,
                                              color: AppColorsDarkMode.textSecondary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${course['Credit_points'] ?? 0} credits',
                                              style: TextStyle(
                                                color: AppColorsDarkMode.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (course['Year'] != null && course['Year'].toString().isNotEmpty) ...[
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.calendar_view_week,
                                                color: AppColorsDarkMode.textSecondary,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                course['Year'].toString(),
                                                style: TextStyle(
                                                  color: AppColorsDarkMode.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                            if (course['Final_grade'] != null && course['Final_grade'].toString().isNotEmpty) ...[
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.grade,
                                                color: AppColorsDarkMode.primaryColor,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Grade: ${course['Final_grade']}',
                                                style: TextStyle(
                                                  color: AppColorsDarkMode.primaryColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.accentColorDarker,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: AppColorsDarkMode.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This feature extracts and displays course data. Full integration with the course management system is coming soon.',
                        style: TextStyle(
                          color: AppColorsDarkMode.textSecondary,
                          fontSize: 12,
                        ),
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
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRawJsonDialog(aiAgent);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.surfaceColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('View Raw JSON'),
          ),
        ],
      ),
    );
  }

  // Enhanced: Show Raw JSON Dialog
  void _showRawJsonDialog(DiagramAiAgent aiAgent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
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
            ),
          ),
        ),
        actions: [
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
    IconData? icon;

    if (isError) {
      backgroundColor = AppColorsDarkMode.errorColor;
      icon = Icons.error;
    } else if (isSuccess) {
      backgroundColor = Colors.green.shade700;
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
