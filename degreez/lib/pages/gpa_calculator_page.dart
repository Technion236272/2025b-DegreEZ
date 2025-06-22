import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../color/color_palette.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';

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
  final Map<String, ModifiedCourse> _modifiedCourses = <String, ModifiedCourse>{};

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
            coursesBySemester.keys.first, // We need semester key, using first one
            course.courseId,
          );
          
          if (courseDetails?.courseDetails == null) {
            // Try to load course details from API
            final currentSemester = courseProvider.currentSemester;
            if (currentSemester != null) {              try {
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
  GpaCalculationResult _calculateAverage(List<GpaCalculationItem> courses) {
    debugPrint('DEBUG: _calculateAverage called with ${courses.length} courses');
    
    if (courses.isEmpty) {
      debugPrint('DEBUG: No courses provided to _calculateAverage');
      return GpaCalculationResult(gpa: 0.0, totalCredits: 0.0);
    }
    
    double totalPoints = 0.0;
    double totalCredits = 0.0;
    
    for (final course in courses) {
      debugPrint('DEBUG: Processing ${course.name}: ${course.credits} credits, ${course.grade} grade');
      // Use the grade as-is (percentage), weighted by credits
      final weightedPoints = course.grade * course.credits;
      totalPoints += weightedPoints;
      totalCredits += course.credits;
      
      debugPrint('DEBUG: ${course.name} - grade: ${course.grade}, weightedPoints: $weightedPoints');
      debugPrint('DEBUG: Running totals - totalPoints: $totalPoints, totalCredits: $totalCredits');
    }
    
    final gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    
    debugPrint('DEBUG: Final calculation - totalPoints: $totalPoints, totalCredits: $totalCredits, gpa: $gpa');
    
    return GpaCalculationResult(gpa: gpa, totalCredits: totalCredits);
  }  List<GpaCalculationItem> _getCompletedCourses(
    Map<String, List<StudentCourse>> coursesBySemester,
    CourseProvider courseProvider,
  ) {
    final List<GpaCalculationItem> completedCourses = [];
    
    debugPrint('DEBUG: Starting _getCompletedCourses');
    debugPrint('DEBUG: coursesBySemester.length = ${coursesBySemester.length}');
    
    for (final entry in coursesBySemester.entries) {
      final semesterKey = entry.key;
      final semesterCourses = entry.value;
      
      debugPrint('DEBUG: Processing semester $semesterKey with ${semesterCourses.length} courses');
      
      for (final course in semesterCourses) {
        debugPrint('DEBUG: Course ${course.name} - finalGrade: "${course.finalGrade}", creditPoints: ${course.creditPoints}');
        
        // Skip excluded courses
        if (_excludedCourseIds.contains(course.courseId)) {
          debugPrint('DEBUG: Skipping excluded course ${course.name}');
          continue;
        }
        
        // Check if the course has a numerical grade
        if (course.finalGrade.isNotEmpty) {
          final grade = double.tryParse(course.finalGrade);
          debugPrint('DEBUG: Parsed grade for ${course.name}: $grade');
          
          if (grade != null && grade >= 0 && grade <= 100) {
            // Use stored credit points directly from the course model
            final credits = course.creditPoints;
            
            debugPrint('DEBUG: Adding course ${course.name} with grade $grade and credits $credits');
            
            completedCourses.add(GpaCalculationItem(
              name: course.name,
              courseId: course.courseId,
              grade: grade,
              credits: credits,
              isWhatIf: false,
              semesterKey: semesterKey,
              isExcluded: false,
              isModified: false,
            ));
          } else {
            debugPrint('DEBUG: Grade $grade not valid for ${course.name}');
          }
        } else {
          debugPrint('DEBUG: No finalGrade for ${course.name}');
        }
      }
    }
    
    debugPrint('DEBUG: Total completed courses found: ${completedCourses.length}');
    for (final course in completedCourses) {
      debugPrint('DEBUG: Course ${course.name}: ${course.credits} credits, ${course.grade} grade');
    }
    
    return completedCourses;
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
    }    setState(() {
      _whatIfCourses.add(WhatIfCourse(
        name: _courseNameController.text.trim(),
        grade: grade,
        credits: credits,
        isModified: false,
        originalCourseId: null,
      ));
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
    if (grade >= 80) return AppColorsDarkMode.successColor; // Green for 80+
    if (grade >= 70) return AppColorsDarkMode.warningColor; // Orange for 60-69
    if (grade >= 55) return AppColorsDarkMode.primaryColor; // Blue for 55-69
    return AppColorsDarkMode.errorColor; // Red for below 55
  }

  String _getGradeLabel(double grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 80) return 'Very Good';
    if (grade >= 70) return 'Good';
    if (grade >= 60) return 'Pass';
    return 'Fail';  }

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
    final gradeController = TextEditingController(text: course.grade.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
          title: Text(
            'Modify Grade',
            style: TextStyle(color: AppColorsDarkMode.secondaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Grade: ${course.grade.toStringAsFixed(1)}',
                style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColorsDarkMode.secondaryColor),
                decoration: InputDecoration(
                  labelText: 'New Grade (0-100)',
                  labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColorsDarkMode.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColorsDarkMode.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColorsDarkMode.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppColorsDarkMode.surfaceColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
              ),
            ),
            TextButton(
              onPressed: () {
                final newGrade = double.tryParse(gradeController.text.trim());
                if (newGrade != null && newGrade >= 0 && newGrade <= 100) {
                  _modifyCourseGrade(course, newGrade);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid grade between 0 and 100')),
                  );
                }
              },
              child: Text(
                'Apply',
                style: TextStyle(color: AppColorsDarkMode.primaryColor),
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
      _whatIfCourses.add(WhatIfCourse(
        name: '${course.name} (Modified)',
        grade: newGrade,
        credits: course.credits,
        isModified: true,
        originalCourseId: course.courseId,
      ));
    });
  }

  void _removeModifiedCourse(String originalCourseId) {
    setState(() {
      // Remove from excluded courses
      _excludedCourseIds.remove(originalCourseId);
      
      // Remove from modified courses
      _modifiedCourses.remove(originalCourseId);
      
      // Remove from what-if courses
      _whatIfCourses.removeWhere((course) => 
        course.isModified && course.originalCourseId == originalCourseId);
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
      _whatIfCourses.removeWhere((course) => 
        course.isModified && course.originalCourseId == courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Consumer2<StudentProvider, CourseProvider>(
        builder: (context, studentProvider, courseProvider, _) {
          if (studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses) {
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
          }          final coursesBySemester = courseProvider.sortedCoursesBySemester;
          final completedCourses = _getCompletedCourses(coursesBySemester, courseProvider);
          final currentResult = _calculateAverage(completedCourses);
          
          // Calculate projected average including what-if courses
          final allCourses = [
            ...completedCourses,
            ..._whatIfCourses.map((course) => GpaCalculationItem(
              name: course.name,
              courseId: '',
              grade: course.grade,
              credits: course.credits,
              isWhatIf: true,
              semesterKey: 'what-if',
            )),
          ];
          final projectedResult = _calculateAverage(allCourses);

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
                    currentAverage, 
                    projectedAverage, 
                    completedCourses.length,
                    totalCompletedCredits,
                    totalProjectedCredits,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Row
                  _buildStatisticsRow(completedCourses, _whatIfCourses),
                  
                  const SizedBox(height: 24),
                  
                  // Current Courses Section
                  _buildCurrentCoursesSection(completedCourses),
                  
                  const SizedBox(height: 24),
                  
                  // What-If Courses Section
                  _buildWhatIfSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Add What-If Course Form
                  _buildAddCourseForm(),
                  
                  if (_isLoadingCourseDetails) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppColorsDarkMode.cardDecoration(),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Loading course details...',
                            style: TextStyle(
                              color: AppColorsDarkMode.textSecondary,
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
  }
  Widget _buildAverageSummaryCards(
    double currentAverage, 
    double projectedAverage, 
    int completedCoursesCount,
    double totalCompletedCredits,
    double totalProjectedCredits,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                Text(
                  'Current Average',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentAverage.toStringAsFixed(1),
                  style: TextStyle(
                    color: _getGradeColor(currentAverage),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGradeLabel(currentAverage),
                  style: TextStyle(
                    color: _getGradeColor(currentAverage),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCoursesCount courses',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${totalCompletedCredits.toStringAsFixed(1)} credits',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                Text(
                  'Projected Average',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  projectedAverage.toStringAsFixed(1),
                  style: TextStyle(
                    color: _whatIfCourses.isNotEmpty 
                      ? _getGradeColor(projectedAverage)
                      : _getGradeColor(currentAverage),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGradeLabel(projectedAverage),
                  style: TextStyle(
                    color: _whatIfCourses.isNotEmpty 
                      ? _getGradeColor(projectedAverage)
                      : _getGradeColor(currentAverage),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${completedCoursesCount + _whatIfCourses.length} courses',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${totalProjectedCredits.toStringAsFixed(1)} credits',
                  style: const TextStyle(
                    color: AppColorsDarkMode.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStatisticsRow(List<GpaCalculationItem> completedCourses, List<WhatIfCourse> whatIfCourses) {
    // Calculate grade distribution by ranges
    final gradeRanges = <String, int>{
      '90-100': 0,
      '80-89': 0,
      '70-79': 0,
      '60-69': 0,
      '0-59': 0,
    };

    for (final course in completedCourses) {
      if (course.grade >= 90) {
        gradeRanges['90-100'] = gradeRanges['90-100']! + 1;
      } else if (course.grade >= 80) {
        gradeRanges['80-89'] = gradeRanges['80-89']! + 1;
      } else if (course.grade >= 70) {
        gradeRanges['70-79'] = gradeRanges['70-79']! + 1;
      } else if (course.grade >= 60) {
        gradeRanges['60-69'] = gradeRanges['60-69']! + 1;
      } else {
        gradeRanges['0-59'] = gradeRanges['0-59']! + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grade Distribution',
            style: TextStyle(
              color: AppColorsDarkMode.secondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (completedCourses.isEmpty)
            Text(
              'No completed courses with grades',
              style: TextStyle(
                color: AppColorsDarkMode.secondaryColorDim,
                fontSize: 14,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,              children: gradeRanges.entries.where((entry) => entry.value > 0).map((entry) {
                Color rangeColor;
                if (entry.key == '90-100' || entry.key == '80-89') {rangeColor = AppColorsDarkMode.successColor;} // Green for 80+
                else if (entry.key == '70-79') {rangeColor = AppColorsDarkMode.primaryColor;} // Blue for 70-79
                else if (entry.key == '60-69') {rangeColor = AppColorsDarkMode.warningColor;} // Orange for 60-69
                else {rangeColor = AppColorsDarkMode.errorColor;} // Red for below 60

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rangeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rangeColor.withAlpha(75),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: rangeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }  Widget _buildCurrentCoursesSection(List<GpaCalculationItem> completedCourses) {
    final hasModifications = _excludedCourseIds.isNotEmpty || _modifiedCourses.isNotEmpty;
    
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
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),                  Text(
                    'Tap to exclude • Long press to modify • Click refresh icon to reset individual course',
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColorDim,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),            if (hasModifications)
              GestureDetector(
                onTap: _resetAllModifications,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: AppColorsDarkMode.secondaryColorDim,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset All',
                        style: TextStyle(
                          color: AppColorsDarkMode.secondaryColorDim,
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
              color: AppColorsDarkMode.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorsDarkMode.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColorsDarkMode.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_excludedCourseIds.length} excluded • ${_modifiedCourses.length} modified',
                    style: TextStyle(
                      color: AppColorsDarkMode.primaryColor,
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
            padding: const EdgeInsets.all(20),
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
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: AppColorsDarkMode.secondaryColorDim,
                ),
                SizedBox(height: 12),
                Text(
                  'No completed courses found',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColor,                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add courses with numerical grades (0-100) to see your average',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Group courses by semester
          ...completedCourses.fold<Map<String, List<GpaCalculationItem>>>(
            {},
            (acc, course) {
              acc.putIfAbsent(course.semesterKey, () => []).add(course);
              return acc;
            },
          ).entries.map((semesterEntry) => _buildSemesterSection(semesterEntry.key, semesterEntry.value)),
      ],
    );
  }Widget _buildSemesterSection(String semesterKey, List<GpaCalculationItem> courses) {
    // Filter out excluded courses for calculation
    final activeCourses = courses.where((course) => !_excludedCourseIds.contains(course.courseId)).toList();
    
    final semesterResult = _calculateAverage(activeCourses);
    final semesterAverage = semesterResult.gpa;
    final totalCredits = courses.fold<double>(0.0, (sum, course) => sum + course.credits);
    final activeCredits = activeCourses.fold<double>(0.0, (sum, course) => sum + course.credits);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),            decoration: BoxDecoration(
              color: AppColorsDarkMode.accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterKey,
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (activeCourses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.secondaryColorExtremelyDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorsDarkMode.secondaryColorExtremelyDim,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${semesterAverage.toStringAsFixed(1)} avg',
                      style: TextStyle(
                        color: _getGradeColor(semesterAverage),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (activeCredits != totalCredits) ...[
                      Text(
                        '${activeCredits.toStringAsFixed(1)} / ${totalCredits.toStringAsFixed(1)} credits',
                        style: const TextStyle(
                          color: AppColorsDarkMode.secondaryColorDim,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${courses.length - activeCourses.length} excluded',
                        style: TextStyle(
                          color: AppColorsDarkMode.errorColor,
                          fontSize: 10,
                        ),
                      ),
                    ] else
                      Text(
                        '${totalCredits.toStringAsFixed(1)} credits',
                        style: const TextStyle(
                          color: AppColorsDarkMode.secondaryColorDim,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ...courses.map((course) => _buildCourseCard(course)),
        ],
      ),
    );
  }

  Widget _buildWhatIfSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [            const Text(
              'What-If Scenarios',
              style: TextStyle(
                color: AppColorsDarkMode.secondaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.secondaryColorDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsDarkMode.secondaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                '${_whatIfCourses.length}',
                style: const TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),        const Text(
          'Add potential courses to see how they would affect your average',
          style: TextStyle(
            color: AppColorsDarkMode.secondaryColorDim,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (_whatIfCourses.isEmpty)          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: const Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: AppColorsDarkMode.secondaryColorDim,
                ),
                SizedBox(height: 12),
                Text(
                  'No what-if courses added',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use the form below to explore scenarios',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ..._whatIfCourses.asMap().entries.map((entry) {
            final index = entry.key;
            final course = entry.value;
            return _buildWhatIfCourseCard(course, index);
          }),
      ],
    );
  }  Widget _buildCourseCard(GpaCalculationItem course) {
    final isExcluded = _excludedCourseIds.contains(course.courseId);
    final isModified = _modifiedCourses.containsKey(course.courseId);
    
    return GestureDetector(
      onTap: () => _toggleCourseExclusion(course.courseId),
      onLongPress: () => _showModifyGradeDialog(course),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColorsDarkMode.borderPrimary,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: _getGradeColor(course.grade).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getGradeColor(course.grade),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  course.grade.toStringAsFixed(0),
                  style: TextStyle(
                    color: _getGradeColor(course.grade),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: isExcluded ? TextDecoration.lineThrough : null,
                    decorationColor: AppColorsDarkMode.errorColor,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: isExcluded ? TextDecoration.lineThrough : null,
                      decorationColor: AppColorsDarkMode.errorColor,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${course.credits.toStringAsFixed(1)} credits',
                        style: TextStyle(
                          color: AppColorsDarkMode.secondaryColorDim,
                          fontSize: 12,
                          decoration: isExcluded ? TextDecoration.lineThrough : null,
                          decorationColor: AppColorsDarkMode.errorColor,
                          decorationThickness: 2,
                        ),
                      ),
                      if (course.courseId.isNotEmpty) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: AppColorsDarkMode.secondaryColorDim,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          course.courseId,
                          style: TextStyle(
                            color: AppColorsDarkMode.secondaryColorDim,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            decoration: isExcluded ? TextDecoration.lineThrough : null,
                            decorationColor: AppColorsDarkMode.errorColor,
                            decorationThickness: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExcluded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorsDarkMode.errorColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'EXCLUDED',
                      style: TextStyle(
                        color: AppColorsDarkMode.errorColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isModified)
                  Container(
                    margin: EdgeInsets.only(left: isExcluded ? 8 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorsDarkMode.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'MODIFIED',
                      style: TextStyle(
                        color: AppColorsDarkMode.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),                if (isExcluded || isModified) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Handle individual course reset
                      _resetIndividualCourse(course.courseId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColorsDarkMode.primaryColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: 16,
                        color: AppColorsDarkMode.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }  Widget _buildWhatIfCourseCard(WhatIfCourse course, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: course.isModified 
            ? [
                AppColorsDarkMode.primaryColor.withOpacity(0.1),
                AppColorsDarkMode.primaryColor.withOpacity(0.05),
              ]
            : [
                AppColorsDarkMode.mainColor,
                AppColorsDarkMode.accentColorDarker,
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: course.isModified 
          ? Border.all(
              color: AppColorsDarkMode.primaryColor.withOpacity(0.5),
              width: 1,
            )
          : null,
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
          Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: _getGradeColor(course.grade).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getGradeColor(course.grade),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                course.grade.toStringAsFixed(0),
                style: TextStyle(
                  color: _getGradeColor(course.grade),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          color: AppColorsDarkMode.secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: course.isModified 
                          ? AppColorsDarkMode.primaryColor.withOpacity(0.2)
                          : AppColorsDarkMode.secondaryColorDim,
                        borderRadius: BorderRadius.circular(8),
                        border: course.isModified 
                          ? Border.all(
                              color: AppColorsDarkMode.primaryColor.withOpacity(0.5),
                              width: 1,
                            )
                          : null,
                      ),
                      child: Text(
                        course.isModified ? 'MODIFIED' : 'WHAT-IF',
                        style: TextStyle(
                          color: course.isModified 
                            ? AppColorsDarkMode.primaryColor
                            : AppColorsDarkMode.secondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.credits.toStringAsFixed(1)} credits',
                  style: const TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (course.isModified && course.originalCourseId != null)
                GestureDetector(
                  onTap: () => _resetIndividualCourse(course.originalCourseId!),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColorsDarkMode.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: AppColorsDarkMode.primaryColor,
                    ),
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
                icon: const Icon(
                  Icons.close,
                  color: AppColorsDarkMode.errorColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCourseForm() {    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add What-If Course',
            style: TextStyle(
              color: AppColorsDarkMode.secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _courseNameController,            style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
            decoration: InputDecoration(
              labelText: 'Course Name',
              labelStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
              hintText: 'e.g., Introduction to Computer Science',
              hintStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColorsDarkMode.primaryColor),
              ),
              filled: true,
              fillColor: AppColorsDarkMode.surfaceColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _creditsController,
                  keyboardType: TextInputType.number,                  style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
                  decoration: InputDecoration(
                    labelText: 'Credit Hours',
                    labelStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                    hintText: '3.0',
                    hintStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.primaryColor),
                    ),
                    filled: true,
                    fillColor: AppColorsDarkMode.surfaceColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,                  style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
                  decoration: InputDecoration(
                    labelText: 'Grade (0-100)',
                    labelStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                    hintText: '85',
                    hintStyle: const TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColorsDarkMode.primaryColor),
                    ),
                    filled: true,
                    fillColor: AppColorsDarkMode.surfaceColor,
                  ),
                ),
              ),
            ],
          ),          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addWhatIfCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsDarkMode.secondaryColor,
                foregroundColor: AppColorsDarkMode.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Add What-If Course',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes for GPA calculation
class GpaCalculationItem {
  final String name;
  final String courseId;
  final double grade;
  final double credits;
  final bool isWhatIf;
  final String semesterKey;
  final bool isExcluded;
  final bool isModified;

  GpaCalculationItem({
    required this.name,
    required this.courseId,
    required this.grade,
    required this.credits,
    this.isWhatIf = false,
    required this.semesterKey,
    this.isExcluded = false,
    this.isModified = false,
  });
}

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

class GpaCalculationResult {
  final double gpa;
  final double totalCredits;

  GpaCalculationResult({
    required this.gpa,
    required this.totalCredits,
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
