import 'package:flutter/material.dart';
import '../color/color_palette.dart';
import '../services/diagram_ai_agent.dart';

class GradeSheetImportWidget extends StatefulWidget {
  final VoidCallback? onCoursesExtracted;
  
  const GradeSheetImportWidget({
    super.key,
    this.onCoursesExtracted,
  });

  @override
  State<GradeSheetImportWidget> createState() => _GradeSheetImportWidgetState();
}

class _GradeSheetImportWidgetState extends State<GradeSheetImportWidget> {
  final DiagramAiAgent _aiAgent = DiagramAiAgent();
  bool _isProcessing = false;

  Future<void> _importGradeSheet() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Show initial loading message
      _showSnackBar('Starting grade sheet import...', isLoading: true);

      // Process the grade sheet using the AI agent
      final courseData = await _aiAgent.processGradeSheet();
      
      if (courseData != null) {
        // Show success message with course count
        final courses = _aiAgent.getCoursesForApp();
        _showSnackBar('Successfully extracted ${courses.length} courses!', isSuccess: true);
        
        // Show extracted data dialog
        _showExtractedDataDialog(courseData);
        
        // Notify parent widget that courses were extracted
        widget.onCoursesExtracted?.call();
      } else {
        _showSnackBar('Import cancelled by user.');
      }
    } catch (e) {
      _showSnackBar('Error importing grade sheet: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showExtractedDataDialog(Map<String, dynamic> courseData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColorsDarkMode.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Courses Extracted',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 600),
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
                    'Found ${_aiAgent.getCoursesForApp().length} courses:',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCoursesSummary(),
              ),
            ],
          ),
        ),        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => _showRawJsonDialog(),
            child: Text(
              'View Raw JSON',
              style: TextStyle(color: AppColorsDarkMode.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: _integrateWithApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsDarkMode.primaryColor,
              foregroundColor: AppColorsDarkMode.textPrimary,
            ),
            child: const Text('Integrate with App'),
          ),
        ],
      ),
    );
  }  Widget _buildCoursesSummary() {
    final coursesBySemester = _aiAgent.getCoursesBySemester();
    
    if (coursesBySemester.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorsDarkMode.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorsDarkMode.borderPrimary),
        ),
        child: Text(
          'No courses found in the extracted data.',
          style: TextStyle(
            color: AppColorsDarkMode.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Courses by Semester:',
            style: TextStyle(
              color: AppColorsDarkMode.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: coursesBySemester.entries.map((entry) => Container(
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
                          const SizedBox(width: 6),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: AppColorsDarkMode.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColorsDarkMode.primaryColor.withAlpha(51),
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
                      const SizedBox(height: 8),
                      ...entry.value.map((course) => Container(
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school,
                                        color: AppColorsDarkMode.textSecondary,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course['Credit_points'] ?? 0} credits',
                                        style: TextStyle(
                                          color: AppColorsDarkMode.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (course['Year'] != null && course['Year'].toString().isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.calendar_view_week,
                                          color: AppColorsDarkMode.textSecondary,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course['Year'].toString(),
                                          style: TextStyle(
                                            color: AppColorsDarkMode.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                      if (course['Final_grade'] != null && course['Final_grade'].toString().isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.grade,
                                          color: _getGradeColor(course['Final_grade'].toString()),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Grade: ${course['Final_grade']}',
                                          style: TextStyle(
                                            color: _getGradeColor(course['Final_grade'].toString()),
                                            fontSize: 10,
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
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.isEmpty || grade.toLowerCase() == 'n/a') {
      return AppColorsDarkMode.textSecondary;
    }
    
    // Handle numeric grades
    final numericGrade = double.tryParse(grade);
    if (numericGrade != null) {
      if (numericGrade >= 90) return Colors.green;
      if (numericGrade >= 80) return Colors.lightGreen;
      if (numericGrade >= 70) return Colors.orange;
      if (numericGrade >= 60) return Colors.red;
      return Colors.red.shade700;
    }
    
    // Handle letter grades
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A+':
        return Colors.green;
      case 'A-':
      case 'B+':
      case 'B':
        return Colors.lightGreen;
      case 'B-':
      case 'C+':
      case 'C':
        return Colors.orange;
      case 'C-':
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.red.shade700;
      default:
        return AppColorsDarkMode.textSecondary;
    }
  }
  void _integrateWithApp() {
    // Get summary statistics
    final coursesBySemester = _aiAgent.getCoursesBySemester();
    final totalCourses = _aiAgent.getCoursesForApp().length;
    final semesters = coursesBySemester.length;
    
    // Close the current dialog
    Navigator.pop(context);
    
    // Show integration status
    _showSnackBar(
      'Successfully parsed $totalCourses courses across $semesters semesters! Integration feature coming soon.',
      isInfo: true
    );
    
    // TODO: Implement integration with CourseProvider
    // final courses = _aiAgent.getCoursesForApp();
    // context.read<CourseProvider>().importCourses(courses);
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false, bool isLoading = false, bool isInfo = false}) {
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
    } else if (isInfo) {
      backgroundColor = Colors.blue.shade700;
      icon = Icons.info;
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

  void _showRawJsonDialog() {
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
              'Raw JSON Data',
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
                _aiAgent.exportAsJson(),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _importGradeSheet,
        backgroundColor: _isProcessing 
          ? AppColorsDarkMode.surfaceColor 
          : AppColorsDarkMode.primaryColor,
        foregroundColor: AppColorsDarkMode.textPrimary,
        label: _isProcessing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColorsDarkMode.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Processing...'),
              ],
            )
          : const Text('Import Grade Sheet'),
        icon: _isProcessing 
          ? null 
          : const Icon(Icons.smart_toy),
        tooltip: 'Import courses from grade sheet using AI',
      ),
    );
  }
}
