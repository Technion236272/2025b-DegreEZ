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
  String _selectedGrade = 'A';

  // Grade to GPA mapping (typical 4.0 scale)
  static const Map<String, double> _gradeToGpa = {
    'A': 4.0,
    'A-': 3.7,
    'B+': 3.3,
    'B': 3.0,
    'B-': 2.7,
    'C+': 2.3,
    'C': 2.0,
    'C-': 1.7,
    'D+': 1.3,
    'D': 1.0,
    'F': 0.0,
  };

  static const List<String> _availableGrades = [
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F'
  ];

  @override
  void dispose() {
    _courseNameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  double _calculateGpa(List<GpaCalculationItem> courses) {
    if (courses.isEmpty) return 0.0;
    
    double totalPoints = 0.0;
    double totalCredits = 0.0;
    
    for (final course in courses) {
      final gpaValue = _gradeToGpa[course.grade] ?? 0.0;
      totalPoints += gpaValue * course.credits;
      totalCredits += course.credits;
    }
    
    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  List<GpaCalculationItem> _getCompletedCourses(Map<String, List<StudentCourse>> coursesBySemester) {
    final List<GpaCalculationItem> completedCourses = [];
    
    for (final semesterCourses in coursesBySemester.values) {
      for (final course in semesterCourses) {
        if (course.finalGrade.isNotEmpty && _gradeToGpa.containsKey(course.finalGrade)) {
          completedCourses.add(GpaCalculationItem(
            name: course.name,
            grade: course.finalGrade,
            credits: 3.0, // Default credit hours - could be enhanced to store actual credits
            isWhatIf: false,
          ));
        }
      }
    }
    
    return completedCourses;
  }

  void _addWhatIfCourse() {
    if (_courseNameController.text.trim().isEmpty || _creditsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final credits = double.tryParse(_creditsController.text.trim());
    if (credits == null || credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid credit hours')),
      );
      return;
    }

    setState(() {
      _whatIfCourses.add(WhatIfCourse(
        name: _courseNameController.text.trim(),
        grade: _selectedGrade,
        credits: credits,
      ));
      _courseNameController.clear();
      _creditsController.clear();
      _selectedGrade = 'A';
    });
  }

  void _removeWhatIfCourse(int index) {
    setState(() {
      _whatIfCourses.removeAt(index);
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
          }

          final coursesBySemester = courseProvider.coursesBySemester;
          final completedCourses = _getCompletedCourses(coursesBySemester);
          final currentGpa = _calculateGpa(completedCourses);
          
          // Calculate projected GPA including what-if courses
          final allCourses = [
            ...completedCourses,
            ..._whatIfCourses.map((course) => GpaCalculationItem(
              name: course.name,
              grade: course.grade,
              credits: course.credits,
              isWhatIf: true,
            )),
          ];
          final projectedGpa = _calculateGpa(allCourses);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPA Summary Cards
                  _buildGpaSummaryCards(currentGpa, projectedGpa, completedCourses.length),
                  
                  const SizedBox(height: 24),
                  
                  // Current Courses Section
                  _buildCurrentCoursesSection(completedCourses),
                  
                  const SizedBox(height: 24),
                  
                  // What-If Courses Section
                  _buildWhatIfSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Add What-If Course Form
                  _buildAddCourseForm(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGpaSummaryCards(double currentGpa, double projectedGpa, int completedCoursesCount) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppColorsDarkMode.cardDecoration(elevated: true),
            child: Column(
              children: [
                const Text(
                  'Current GPA',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentGpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColorsDarkMode.primaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
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
                  'Projected GPA',
                  style: TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  projectedGpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: _whatIfCourses.isNotEmpty 
                      ? AppColorsDarkMode.secondaryColor 
                      : AppColorsDarkMode.primaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentCoursesSection(List<GpaCalculationItem> completedCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Courses',
          style: TextStyle(
            color: AppColorsDarkMode.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                  'Add courses with grades to see your GPA',
                  style: TextStyle(
                    color: AppColorsDarkMode.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...completedCourses.map((course) => _buildCourseCard(course)),
      ],
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
          'Add potential courses to see how they would affect your GPA',
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppColorsDarkMode.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColorsDarkMode.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorsDarkMode.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                course.grade,
                style: const TextStyle(
                  color: AppColorsDarkMode.primaryColor,
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
                Text(
                  '${course.credits} credits • ${_gradeToGpa[course.grade]?.toStringAsFixed(1)} GPA',
                  style: const TextStyle(
                    color: AppColorsDarkMode.textSecondary,
                    fontSize: 12,
                  ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColorsDarkMode.secondaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                course.grade,
                style: const TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
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
                  '${course.credits} credits • ${_gradeToGpa[course.grade]?.toStringAsFixed(1)} GPA',
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
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  style: const TextStyle(color: AppColorsDarkMode.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Grade',
                    labelStyle: const TextStyle(color: AppColorsDarkMode.textSecondary),
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
                  dropdownColor: AppColorsDarkMode.surfaceColor,
                  items: _availableGrades.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(
                        '$grade (${_gradeToGpa[grade]?.toStringAsFixed(1)})',
                        style: const TextStyle(color: AppColorsDarkMode.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGrade = value;
                      });
                    }
                  },
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
  final String grade;
  final double credits;
  final bool isWhatIf;

  GpaCalculationItem({
    required this.name,
    required this.grade,
    required this.credits,
    this.isWhatIf = false,
  });
}

class WhatIfCourse {
  final String name;
  final String grade;
  final double credits;

  WhatIfCourse({
    required this.name,
    required this.grade,
    required this.credits,
  });
}
