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
  List<WhatIfCourse> _whatIfCourses = [];
  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _gradeController = TextEditingController();
  bool _isLoadingCourseDetails = false;

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
    print('DEBUG: _calculateAverage called with ${courses.length} courses');
    
    if (courses.isEmpty) {
      print('DEBUG: No courses provided to _calculateAverage');
      return GpaCalculationResult(gpa: 0.0, totalCredits: 0.0);
    }
    
    double totalPoints = 0.0;
    double totalCredits = 0.0;
    
    for (final course in courses) {
      print('DEBUG: Processing ${course.name}: ${course.credits} credits, ${course.grade} grade');
      final gradePoint = (course.grade / 100) * 4.0; // Convert percentage to 4.0 scale
      final weightedPoints = gradePoint * course.credits;
      totalPoints += weightedPoints;
      totalCredits += course.credits;
      
      print('DEBUG: ${course.name} - gradePoint: $gradePoint, weightedPoints: $weightedPoints');
      print('DEBUG: Running totals - totalPoints: $totalPoints, totalCredits: $totalCredits');
    }
    
    final gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
    
    print('DEBUG: Final calculation - totalPoints: $totalPoints, totalCredits: $totalCredits, gpa: $gpa');
    
    return GpaCalculationResult(gpa: gpa, totalCredits: totalCredits);
  }
  List<GpaCalculationItem> _getCompletedCourses(
    Map<String, List<StudentCourse>> coursesBySemester,
    CourseProvider courseProvider,
  ) {
    final List<GpaCalculationItem> completedCourses = [];
    
    print('DEBUG: Starting _getCompletedCourses');
    print('DEBUG: coursesBySemester.length = ${coursesBySemester.length}');
    
    for (final entry in coursesBySemester.entries) {
      final semesterKey = entry.key;
      final semesterCourses = entry.value;
      
      print('DEBUG: Processing semester $semesterKey with ${semesterCourses.length} courses');
      
      for (final course in semesterCourses) {
        print('DEBUG: Course ${course.name} - finalGrade: "${course.finalGrade}", creditPoints: ${course.creditPoints}');
        
        // Check if the course has a numerical grade
        if (course.finalGrade.isNotEmpty) {
          final grade = double.tryParse(course.finalGrade);
          print('DEBUG: Parsed grade for ${course.name}: $grade');
          
          if (grade != null && grade >= 0 && grade <= 100) {
            // Use stored credit points directly from the course model
            final credits = course.creditPoints; // No more API calls needed!
            
            print('DEBUG: Adding course ${course.name} with grade $grade and credits $credits');
            
            completedCourses.add(GpaCalculationItem(
              name: course.name,
              courseId: course.courseId,
              grade: grade,
              credits: credits,
              isWhatIf: false,
              semesterKey: semesterKey,
            ));
          } else {
            print('DEBUG: Grade $grade not valid for ${course.name}');
          }
        } else {
          print('DEBUG: No finalGrade for ${course.name}');
        }
      }
    }
    
    print('DEBUG: Total completed courses found: ${completedCourses.length}');
    for (final course in completedCourses) {
      print('DEBUG: Course ${course.name}: ${course.credits} credits, ${course.grade} grade');
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
    }

    setState(() {
      _whatIfCourses.add(WhatIfCourse(
        name: _courseNameController.text.trim(),
        grade: grade,
        credits: credits,
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
    if (grade >= 90) return AppColorsDarkMode.successColor;
    if (grade >= 80) return AppColorsDarkMode.primaryColor;
    if (grade >= 70) return AppColorsDarkMode.secondaryColor;
    if (grade >= 60) return AppColorsDarkMode.warningColor;
    return AppColorsDarkMode.errorColor;
  }

  String _getGradeLabel(double grade) {
    if (grade >= 90) return 'Excellent';
    if (grade >= 80) return 'Very Good';
    if (grade >= 70) return 'Good';
    if (grade >= 60) return 'Pass';
    return 'Fail';
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
            decoration: AppColorsDarkMode.cardDecoration(elevated: true),
            child: Column(
              children: [
                const Text(
                  'Current Average',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
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
                  style: const TextStyle(
                    color: AppColorsDarkMode.textTertiary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${totalCompletedCredits.toStringAsFixed(1)} credits',
                  style: const TextStyle(
                    color: AppColorsDarkMode.textTertiary,
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
            decoration: AppColorsDarkMode.cardDecoration(
              elevated: true,
              backgroundColor: _whatIfCourses.isNotEmpty 
                ? AppColorsDarkMode.surfaceColor 
                : AppColorsDarkMode.cardColor,
            ),
            child: Column(
              children: [
                const Text(
                  'Projected Average',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
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
                  style: const TextStyle(
                    color: AppColorsDarkMode.textTertiary,
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
      padding: const EdgeInsets.all(16),
      decoration: AppColorsDarkMode.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grade Distribution',
            style: TextStyle(
              color: AppColorsDarkMode.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (completedCourses.isEmpty)
            const Text(
              'No completed courses with grades',
              style: TextStyle(
                color: AppColorsDarkMode.textSecondary,
                fontSize: 14,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gradeRanges.entries.where((entry) => entry.value > 0).map((entry) {
                Color rangeColor;
                if (entry.key == '90-100') rangeColor = AppColorsDarkMode.successColor;
                else if (entry.key == '80-89') rangeColor = AppColorsDarkMode.primaryColor;
                else if (entry.key == '70-79') rangeColor = AppColorsDarkMode.secondaryColor;
                else if (entry.key == '60-69') rangeColor = AppColorsDarkMode.warningColor;
                else rangeColor = AppColorsDarkMode.errorColor;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rangeColor.withOpacity(0.3),
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
  }

  Widget _buildCurrentCoursesSection(List<GpaCalculationItem> completedCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Completed Courses',
              style: TextStyle(
                color: AppColorsDarkMode.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            
          ],
        ),
        const SizedBox(height: 12),
        if (completedCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppColorsDarkMode.cardDecoration(),
            child: const Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: AppColorsDarkMode.textTertiary,
                ),
                SizedBox(height: 12),
                Text(
                  'No completed courses found',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add courses with numerical grades (0-100) to see your average',
                  style: TextStyle(
                    color: AppColorsDarkMode.textTertiary,
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
  }
  Widget _buildSemesterSection(String semesterKey, List<GpaCalculationItem> courses) {
    final semesterResult = _calculateAverage(courses);
    final semesterAverage = semesterResult.gpa;
    final totalCredits = courses.fold<double>(0.0, (sum, course) => sum + course.credits);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppColorsDarkMode.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterKey,
                    style: const TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(semesterAverage).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getGradeColor(semesterAverage).withOpacity(0.3),
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
                Text(
                  '${totalCredits.toStringAsFixed(1)} credits',
                  style: const TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                  ),
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
          children: [
            const Text(
              'What-If Scenarios',
              style: TextStyle(
                color: AppColorsDarkMode.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsDarkMode.secondaryColor.withOpacity(0.3),
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
        const SizedBox(height: 8),
        const Text(
          'Add potential courses to see how they would affect your average',
          style: TextStyle(
            color: AppColorsDarkMode.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (_whatIfCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppColorsDarkMode.cardDecoration(),
            child: const Column(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: AppColorsDarkMode.textTertiary,
                ),
                SizedBox(height: 12),
                Text(
                  'No what-if courses added',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use the form below to explore scenarios',
                  style: TextStyle(
                    color: AppColorsDarkMode.textTertiary,
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
  }

  Widget _buildCourseCard(GpaCalculationItem course) {
    return Container(
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
              color: _getGradeColor(course.grade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getGradeColor(course.grade).withOpacity(0.3),
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
                Text(
                  course.name,
                  style: const TextStyle(
                    color: AppColorsDarkMode.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${course.credits.toStringAsFixed(1)} credits',
                      style: const TextStyle(
                        color: AppColorsDarkMode.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (course.courseId.isNotEmpty) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColorsDarkMode.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        course.courseId,
                        style: const TextStyle(
                          color: AppColorsDarkMode.textTertiary,
                          fontSize: 10,
                          fontFamily: 'monospace',
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
    );
  }

  Widget _buildWhatIfCourseCard(WhatIfCourse course, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsDarkMode.cardDecoration(
        backgroundColor: AppColorsDarkMode.surfaceColor,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 40,
            decoration: BoxDecoration(
              color: _getGradeColor(course.grade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getGradeColor(course.grade).withOpacity(0.3),
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
                          color: AppColorsDarkMode.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'WHAT-IF',
                        style: TextStyle(
                          color: AppColorsDarkMode.secondaryColor,
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
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeWhatIfCourse(index),
            icon: const Icon(
              Icons.close,
              color: AppColorsDarkMode.errorColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCourseForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColorsDarkMode.cardDecoration(elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add What-If Course',
            style: TextStyle(
              color: AppColorsDarkMode.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _courseNameController,
            style: const TextStyle(color: AppColorsDarkMode.textPrimary),
            decoration: InputDecoration(
              labelText: 'Course Name',
              labelStyle: const TextStyle(color: AppColorsDarkMode.textSecondary),
              hintText: 'e.g., Introduction to Computer Science',
              hintStyle: const TextStyle(color: AppColorsDarkMode.textTertiary),
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
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColorsDarkMode.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Credit Hours',
                    labelStyle: const TextStyle(color: AppColorsDarkMode.textSecondary),
                    hintText: '3.0',
                    hintStyle: const TextStyle(color: AppColorsDarkMode.textTertiary),
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
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColorsDarkMode.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Grade (0-100)',
                    labelStyle: const TextStyle(color: AppColorsDarkMode.textSecondary),
                    hintText: '85',
                    hintStyle: const TextStyle(color: AppColorsDarkMode.textTertiary),
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
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addWhatIfCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsDarkMode.primaryColor,
                foregroundColor: AppColorsDarkMode.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
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

  GpaCalculationItem({
    required this.name,
    required this.courseId,
    required this.grade,
    required this.credits,
    this.isWhatIf = false,
    required this.semesterKey,
  });
}

class WhatIfCourse {
  final String name;
  final double grade;
  final double credits;

  WhatIfCourse({
    required this.name,
    required this.grade,
    required this.credits,
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
