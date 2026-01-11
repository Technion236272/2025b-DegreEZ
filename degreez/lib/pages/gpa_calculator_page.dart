import 'package:degreez/widgets/text_form_field_with_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/calculate_gpa_function.dart';

class WhatIfCourse {
  final String name;
  final double grade;
  final double credits;
  final bool isModified;
  final String? originalCourseId;

  WhatIfCourse({
    required this.name,
    required this.grade,
    required this.credits,
    this.isModified = false,
    this.originalCourseId,
  });
}

class ModifiedCourse {
  final String originalCourseId;
  final String name;
  final double originalGrade;
  final double newGrade;
  final double credits;
  final String semesterKey;

  ModifiedCourse({
    required this.originalCourseId,
    required this.name,
    required this.originalGrade,
    required this.newGrade,
    required this.credits,
    required this.semesterKey,
  });
}

class GpaCalculatorPage extends StatefulWidget {
  const GpaCalculatorPage({super.key});

  @override
  State<GpaCalculatorPage> createState() => _GpaCalculatorPageState();
}

class _GpaCalculatorPageState extends State<GpaCalculatorPage> {
  final List<WhatIfCourse> _whatIfCourses = [];
  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _gradeController = TextEditingController();
  bool _isLoadingCourseDetails = false;

  // Track excluded courses and modified courses
  final Set<String> _excludedCourseIds = <String>{};
  final Map<String, ModifiedCourse> _modifiedCourses =
      <String, ModifiedCourse>{};
  
  bool _areAllSemestersExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseDetailsIfNeeded();
    });
    // Set default values
    _creditsController.text = '3.0';
    _gradeController.text = '85';
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _creditsController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _loadCourseDetailsIfNeeded() async {
    final courseProvider = context.read<CourseProvider>();
    final coursesBySemester = courseProvider.coursesBySemester;

    if (coursesBySemester.isEmpty) return;

    setState(() {
      _isLoadingCourseDetails = true;
    });

    try {
      // Load course details for courses that don't have them cached
      for (final semesterCourses in coursesBySemester.values) {
        for (final course in semesterCourses) {
          final courseDetails = courseProvider.getCourseWithDetails(
            coursesBySemester
                .keys
                .first, // We need semester key, using first one
            course.courseId,
          );

          if (courseDetails?.courseDetails == null) {
            // Try to load course details from API
            final currentSemester = courseProvider.currentSemester;
            if (currentSemester != null) {
              try {
                // No longer needed - using stored credit points
              } catch (e) {
                // Course details not available for current semester, which is expected
              }
            }
          }
        }
      }
    } catch (e) {
      // Handle errors silently for now
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCourseDetails = false;
        });
      }
    }
  }

  void _addWhatIfCourse() {
    if (_courseNameController.text.trim().isEmpty ||
        _creditsController.text.trim().isEmpty ||
        _gradeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final credits = double.tryParse(_creditsController.text.trim());
    final grade = double.tryParse(_gradeController.text.trim());

    if (credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credit hours')),
      );
      return;
    }

    if (grade == null || grade < 0 || grade > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a grade between 0 and 100')),
      );
      return;
    }
    setState(() {
      _whatIfCourses.add(
        WhatIfCourse(
          name: _courseNameController.text.trim(),
          grade: grade,
          credits: credits,
          isModified: false,
          originalCourseId: null,
        ),
      );
      _courseNameController.clear();
      _creditsController.text = '3.0';
      _gradeController.text = '85';
    });
  }

  void _removeWhatIfCourse(int index) {
    setState(() {
      _whatIfCourses.removeAt(index);
    });
  }

  Color _getGradeColor(double grade) {
    final themeProvider = context.read<ThemeProvider>();
    return themeProvider.getGradeColor(grade);
  }

  String _getGradeLabel(double grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 80) return 'Very Good';
    if (grade >= 70) return 'Good';
    if (grade >= 60) return 'Pass';
    return 'Fail';
  }

  void _toggleCourseExclusion(String courseId) {
    setState(() {
      if (_excludedCourseIds.contains(courseId)) {
        _excludedCourseIds.remove(courseId);
      } else {
        _excludedCourseIds.add(courseId);
        // If course was modified, remove the modification when excluding
        _modifiedCourses.remove(courseId);
      }
    });
  }

  void _showModifyGradeDialog(GpaCalculationItem course) {
    final gradeController = TextEditingController(
      text: course.grade.toString(),
    );
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.mainColor, // Changed to night black
          title: Text('Modify Grade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.name, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Current Grade: ${course.grade.toStringAsFixed(1)}'),
              const SizedBox(height: 16),
              textFormFieldWithStyle(label: 'New Grade (0-100)', controller: gradeController, example: "100", context: context)
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',style: TextStyle(color: context.read<ThemeProvider>().secondaryColor),),
            ),
            TextButton(
                            style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
      }
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
    }),
                  ),
              onPressed: () {
                final newGrade = double.tryParse(gradeController.text.trim());
                if (newGrade != null && newGrade >= 0 && newGrade <= 100) {
                  _modifyCourseGrade(course, newGrade);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid grade between 0 and 100',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Apply',
                style: TextStyle(color: themeProvider.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _modifyCourseGrade(GpaCalculationItem course, double newGrade) {
    setState(() {
      // Add original course to excluded list
      _excludedCourseIds.add(course.courseId);

      // Add modified course to what-if courses
      final modifiedCourse = ModifiedCourse(
        originalCourseId: course.courseId,
        name: '${course.name} (Modified)',
        originalGrade: course.grade,
        newGrade: newGrade,
        credits: course.credits,
        semesterKey: course.semesterKey,
      );

      _modifiedCourses[course.courseId] = modifiedCourse;

      // Add to what-if courses for calculation
      _whatIfCourses.add(
        WhatIfCourse(
          name: '${course.name} (Modified)',
          grade: newGrade,
          credits: course.credits,
          isModified: true,
          originalCourseId: course.courseId,
        ),
      );
    });
  }

  void _removeModifiedCourse(String originalCourseId) {
    setState(() {
      // Remove from excluded courses
      _excludedCourseIds.remove(originalCourseId);

      // Remove from modified courses
      _modifiedCourses.remove(originalCourseId);

      // Remove from what-if courses
      _whatIfCourses.removeWhere(
        (course) =>
            course.isModified && course.originalCourseId == originalCourseId,
      );
    });
  }

  void _resetAllModifications() {
    setState(() {
      _excludedCourseIds.clear();
      _modifiedCourses.clear();
      _whatIfCourses.removeWhere((course) => course.isModified);
    });
  }

  void _resetIndividualCourse(String courseId) {
    setState(() {
      // Remove from excluded courses (if it was excluded)
      _excludedCourseIds.remove(courseId);

      // Remove from modified courses (if it was modified)
      _modifiedCourses.remove(courseId);
      // Remove any what-if course that was created from this modification
      _whatIfCourses.removeWhere(
        (course) => course.isModified && course.originalCourseId == courseId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: themeProvider.mainColor,
          body: Consumer2<StudentProvider, CourseProvider>(
            builder: (context, studentProvider, courseProvider, _) {
              if (studentProvider.isLoading ||
                  courseProvider.loadingState.isLoadingCourses) {
                return const Center(child: CircularProgressIndicator());
              }

              if (studentProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${studentProvider.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              final coursesBySemester = courseProvider.sortedCoursesBySemester;
              final completedCourses = getCompletedCourses(
                coursesBySemester,
                courseProvider,
              );
              final completedCoursesWithExecluded = getCompletedCourses(
                coursesBySemester,
                courseProvider,
                excludedCourseIds: _excludedCourseIds
              );
              final currentResult = calculateAverage(completedCourses);

              // Calculate projected average including what-if courses
              final allCourses = [
                ...completedCoursesWithExecluded,
                ..._whatIfCourses.map(
                  (course) => GpaCalculationItem(
                    name: course.name,
                    courseId: '',
                    grade: course.grade,
                    credits: course.credits,
                    isWhatIf: true,
                    semesterKey: 'what-if',
                  ),
                ),
              ];
              final projectedResult = calculateAverage(allCourses);

              // Extract GPA and credits from results
              final currentAverage = currentResult.gpa;
              final projectedAverage = projectedResult.gpa;
              final totalCompletedCredits = currentResult.totalCredits;
              final totalProjectedCredits = projectedResult.totalCredits;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Average Summary Cards
                      _buildAverageSummaryCards(
                        themeProvider,
                        currentAverage,
                        projectedAverage,
                        completedCoursesWithExecluded.length,
                        totalCompletedCredits,
                        totalProjectedCredits,
                      ),

                      const SizedBox(height: 24),

                      // Statistics Row
                      _buildStatisticsRow(
                        themeProvider,
                        completedCoursesWithExecluded,
                        _whatIfCourses,
                      ),

                      const SizedBox(height: 24),

                      // Current Courses Section
                      _buildCurrentCoursesSection(
                        themeProvider,
                        completedCoursesWithExecluded, //change to completedCourses
                      ),

                      const SizedBox(height: 24),

                      // What-If Courses Section
                      _buildWhatIfSection(themeProvider),

                      const SizedBox(height: 24),

                      // Add What-If Course Form
                      _buildAddCourseForm(themeProvider),

                      if (_isLoadingCourseDetails) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeProvider.cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading course details...',
                                style: TextStyle(
                                  color: themeProvider.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAverageSummaryCards(
    ThemeProvider themeProvider,
    double currentAverage,
    double projectedAverage,
    int completedCoursesCount,
    double totalCompletedCredits,
    double totalProjectedCredits,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: themeProvider.borderPrimary.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Current GPA',
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentAverage.toStringAsFixed(2),
                      style: TextStyle(
                        color: _getGradeColor(currentAverage),
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getGradeColor(currentAverage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getGradeColor(currentAverage).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getGradeLabel(currentAverage).toUpperCase(),
                        style: TextStyle(
                          color: _getGradeColor(currentAverage),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '$completedCoursesCount Courses',
                           style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                         Container(width: 1, height: 12, color: themeProvider.borderPrimary),
                        const SizedBox(width: 8),
                         Icon(Icons.access_time_filled, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${totalCompletedCredits.toStringAsFixed(1)} Credits',
                           style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_whatIfCourses.isNotEmpty) ...[
                Container(width: 1, height: 140, color: themeProvider.borderPrimary),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Projected',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 14,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                       const SizedBox(height: 12),
                      Text(
                        projectedAverage.toStringAsFixed(2),
                        style: TextStyle(
                          color: _getGradeColor(projectedAverage),
                          fontSize: 48,
                          height: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                       const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(projectedAverage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getGradeColor(projectedAverage).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _getGradeLabel(projectedAverage).toUpperCase(),
                          style: TextStyle(
                            color: _getGradeColor(projectedAverage),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                             letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '+${_whatIfCourses.length} What-If',
                        style: TextStyle(
                          color: themeProvider.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                         'Total: ${totalProjectedCredits.toStringAsFixed(1)} Credits',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(
    ThemeProvider themeProvider,
    List<GpaCalculationItem> completedCourses,
    List<WhatIfCourse> whatIfCourses,
  ) {
    if (completedCourses.isEmpty) return const SizedBox.shrink();

    // Calculate grade distribution by ranges
    final gradeRanges = <String, int>{
      '90+': 0,
      '80-89': 0,
      '70-79': 0,
      '60-69': 0,
      '<60': 0,
    };

    int maxCount = 0;
    for (final course in completedCourses) {
      String key;
      if (course.grade >= 90) {
        key = '90+';
      } else if (course.grade >= 80) {
        key = '80-89';
      } else if (course.grade >= 70) {
        key = '70-79';
      } else if (course.grade >= 60) {
        key = '60-69';
      } else {
        key = '<60';
      }
      
      gradeRanges[key] = (gradeRanges[key] ?? 0) + 1;
      if (gradeRanges[key]! > maxCount) maxCount = gradeRanges[key]!;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
         border: Border.all(
          color: themeProvider.borderPrimary.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grade Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeProvider.textPrimary),
              ),
              Icon(Icons.bar_chart, color: themeProvider.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140, // Increased height to prevent overflow
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: gradeRanges.entries.map((entry) {
                final count = entry.value;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                
                Color rangeColor;
                if (entry.key == '90+' || entry.key == '80-89') {
                  rangeColor = themeProvider.successColor;
                } else if (entry.key == '70-79') {
                  rangeColor = themeProvider.primaryColor;
                } else if (entry.key == '60-69') {
                  rangeColor = themeProvider.warningColor;
                } else {
                  rangeColor = themeProvider.errorColor;
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (count > 0)
                      Text(
                        count.toString(),
                        style: TextStyle(
                          color: rangeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Container(
                          width: 12,
                          height: 80 * value + (count > 0 ? 4 : 2), // Min height
                          decoration: BoxDecoration(
                            color: count > 0 ? rangeColor : themeProvider.borderPrimary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      }
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: themeProvider.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCoursesSection(
    ThemeProvider themeProvider,
    List<GpaCalculationItem> completedCourses,
  ) {
    final hasModifications =
        _excludedCourseIds.isNotEmpty || _modifiedCourses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completed Courses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to exclude • Long press to modify',
                    style: TextStyle(
                      color: themeProvider.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
                onTap: () {
                  setState(() {
                    _areAllSemestersExpanded = !_areAllSemestersExpanded;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.textSecondary.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeProvider.textSecondary.withAlpha(128),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _areAllSemestersExpanded ? Icons.unfold_less : Icons.unfold_more,
                        size: 14,
                        color: themeProvider.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _areAllSemestersExpanded ? 'Collapse All' : 'Expand All',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasModifications)
              GestureDetector(
                onTap: _resetAllModifications,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.textSecondary.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeProvider.textSecondary.withAlpha(128),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: themeProvider.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset All',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (hasModifications) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: themeProvider.primaryColor.withAlpha(76),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_excludedCourseIds.length} excluded • ${_modifiedCourses.length} modified',
                    style: TextStyle(
                      color: themeProvider.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (completedCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeProvider.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: themeProvider.borderPrimary.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: themeProvider.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'No completed courses found',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Add courses with numerical grades (0-100) to see your average',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Group courses by semester
          ...completedCourses
              .fold<Map<String, List<GpaCalculationItem>>>({}, (acc, course) {
                acc.putIfAbsent(course.semesterKey, () => []).add(course);
                return acc;
              })
              .entries
              .map(
                (semesterEntry) => _buildSemesterSection(
                  themeProvider,
                  semesterEntry.key,
                  semesterEntry.value,
                ),
              ),
      ],
    );
  }

  Widget _buildSemesterSection(
    ThemeProvider themeProvider,
    String semesterKey,
    List<GpaCalculationItem> courses,
  ) {
    // Filter out excluded courses for calculation
    final activeCourses =
        courses
            .where((course) => !_excludedCourseIds.contains(course.courseId))
            .toList();

    final semesterResult = calculateAverage(activeCourses);
    final semesterAverage = semesterResult.gpa;
    final totalCredits = courses.fold<double>(
      0.0,
      (sum, course) => sum + course.credits,
    );
    final activeCredits = activeCourses.fold<double>(
      0.0,
      (sum, course) => sum + course.credits,
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderPrimary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('$semesterKey-$_areAllSemestersExpanded'), // Force rebuild when toggle changes
          backgroundColor: themeProvider.cardColor,
          collapsedBackgroundColor: themeProvider.cardColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          initiallyExpanded: _areAllSemestersExpanded,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  semesterKey,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (activeCourses.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(semesterAverage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getGradeColor(semesterAverage).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    semesterAverage.toStringAsFixed(2),
                     style: TextStyle(
                      color: _getGradeColor(semesterAverage),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              activeCredits != totalCredits 
                  ? '${activeCredits.toStringAsFixed(1)} / ${totalCredits.toStringAsFixed(1)} credits • ${courses.length - activeCourses.length} excluded'
                  : '${totalCredits.toStringAsFixed(1)} credits',
               style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          children: courses.map((course) => _buildCourseCard(themeProvider, course)).toList(),
        ),
      ),
    );
  }

  Widget _buildWhatIfSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'What-If Scenarios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeProvider.textSecondary.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.secondaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                '${_whatIfCourses.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add potential courses to see how they would affect your average',
          style: TextStyle(color: themeProvider.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        if (_whatIfCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeProvider.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: themeProvider.borderPrimary.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_graph_outlined,
                  size: 48,
                  color: themeProvider.primaryColor.withOpacity(0.5),
                ),
                SizedBox(height: 12),
                Text(
                  'Explore "What-If" Scenarios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeProvider.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Add courses below to see potential GPA impact',
                  style: TextStyle(
                    color: themeProvider.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._whatIfCourses.asMap().entries.map((entry) {
            final index = entry.key;
            final course = entry.value;
            return _buildWhatIfCourseCard(themeProvider, course, index);
          }),
      ],
    );
  }

  Widget _buildCourseCard(
    ThemeProvider themeProvider,
    GpaCalculationItem course,
  ) {
    final isExcluded = _excludedCourseIds.contains(course.courseId);
    final isModified = _modifiedCourses.containsKey(course.courseId);

    return InkWell(
      onTap: () => _toggleCourseExclusion(course.courseId),
      onLongPress: () => _showModifyGradeDialog(course),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isExcluded 
              ? themeProvider.mainColor.withOpacity(0.5) 
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: themeProvider.borderPrimary.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getGradeColor(course.grade).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getGradeColor(course.grade).withOpacity(isExcluded ? 0.3 : 0.8),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  course.grade.toStringAsFixed(0),
                  style: TextStyle(
                    color: _getGradeColor(course.grade).withOpacity(isExcluded ? 0.5 : 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isExcluded ? TextDecoration.lineThrough : null,
                    decorationColor: themeProvider.errorColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isExcluded ? themeProvider.textSecondary : themeProvider.textPrimary,
                      decoration: isExcluded ? TextDecoration.lineThrough : null,
                      decorationColor: themeProvider.errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeProvider.surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${course.credits} Cr',
                          style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (course.courseId.isNotEmpty) ...[
                        const SizedBox(width: 8),
                         Text(
                          course.courseId,
                          style: TextStyle(
                            color: themeProvider.textTertiary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
             if (isExcluded || isModified)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isExcluded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: themeProvider.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EXC',
                        style: TextStyle(
                          color: themeProvider.errorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isModified)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'MOD',
                            style: TextStyle(
                              color: themeProvider.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _resetIndividualCourse(course.courseId),
                          child: Icon(Icons.refresh, size: 16, color: themeProvider.primaryColor),
                        )
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatIfCourseCard(
    ThemeProvider themeProvider,
    WhatIfCourse course,
    int index,
  ) {
    return Dismissible(
      key: ValueKey('whatif_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: themeProvider.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
         if (course.isModified && course.originalCourseId != null) {
            _removeModifiedCourse(course.originalCourseId!);
         } else {
            _removeWhatIfCourse(index);
         }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: course.isModified 
              ? themeProvider.primaryColor.withOpacity(0.05) 
              : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: course.isModified
                ? themeProvider.primaryColor.withOpacity(0.3)
                : themeProvider.borderPrimary.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: themeProvider.getGradeColor(course.grade).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.getGradeColor(course.grade),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  course.grade.toStringAsFixed(0),
                  style: TextStyle(
                    color: themeProvider.getGradeColor(course.grade),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (course.isModified)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MODIFIED',
                          style: TextStyle(
                            color: themeProvider.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeProvider.surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${course.credits} Cr',
                          style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                       Text(
                        'What-If',
                        style: TextStyle(
                          color: themeProvider.textTertiary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
             IconButton(
              onPressed: () {
                if (course.isModified && course.originalCourseId != null) {
                  _removeModifiedCourse(course.originalCourseId!);
                } else {
                  _removeWhatIfCourse(index);
                }
              },
              icon: Icon(
                Icons.close_rounded,
                color: themeProvider.textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCourseForm(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.borderPrimary.withOpacity(0.5),
        ),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.add_circle, color: themeProvider.primaryColor),
               const SizedBox(width: 8),
              Text(
                'Add What-If Course',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          textFormFieldWithStyle(
            label: 'Course Name',
            controller: _courseNameController,
            example: 'e.g., Advanced Mathematics',
            context: context,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: textFormFieldWithStyle(label: 'Credits', controller: _creditsController, example: '3.0', context: context)
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: textFormFieldWithStyle(label: 'Grade', controller: _gradeController, example: '95', context: context)
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addWhatIfCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add & Calculate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
