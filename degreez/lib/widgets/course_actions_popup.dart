// New file: course_actions_popup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/Widgets/note_popup.dart';

class CourseActionsPopup extends StatefulWidget {
  final StudentCourse course;
  final String semester;
  final VoidCallback? onCourseUpdated;

  const CourseActionsPopup({
    super.key,
    required this.course,
    required this.semester,
    this.onCourseUpdated,
  });

  @override
  State<CourseActionsPopup> createState() => _CourseActionsPopupState();
}

class _CourseActionsPopupState extends State<CourseActionsPopup> {
  late TextEditingController _gradeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.course.finalGrade);
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.mainColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: themeProvider.secondaryColor, width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Info Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                        Text(
                          widget.course.courseId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.secondaryColor,
                          ),
                        ),
                        Text(
                          widget.course.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),              // Grade Input
              Text(
                'Grade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: themeProvider.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter grade (0-100)',
                  hintStyle: TextStyle(
                    color: themeProvider.textSecondary,
                  ),
                  filled: true,
                  fillColor: themeProvider.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: themeProvider.borderPrimary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: themeProvider.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: themeProvider.secondaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    // Save Grade Button
                    SizedBox(
                      width: double.infinity,                      
                      child: ElevatedButton.icon(
                        onPressed: _saveGrade,
                        icon: Icon(
                          Icons.save,
                          color: themeProvider.isDarkMode 
                            ? themeProvider.accentColor 
                            : themeProvider.surfaceColor,
                        ),
                        label: Text(
                          'Save Grade',
                          style: TextStyle(
                            color: themeProvider.isDarkMode 
                              ? themeProvider.accentColor 
                              : themeProvider.surfaceColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode 
                            ? themeProvider.secondaryColor 
                            : themeProvider.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Add Note Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await notePopup(
                            context,
                            widget.course,
                            widget.semester,
                            widget.course.note,
                            widget.onCourseUpdated,
                          );
                          if (result) {
                            widget.onCourseUpdated?.call(); // trigger refresh
                          }
                        },                        icon: Icon(
                          Icons.note,
                          color: themeProvider.secondaryColor,
                        ),
                        label: Text(
                          'Edit Note',
                          style: TextStyle(
                            color: themeProvider.secondaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: themeProvider.secondaryColor,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delete Course Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmDeleteCourse,                        icon: Icon(
                          Icons.delete,
                          color: themeProvider.isDarkMode 
                            ? AppColorsDarkMode.errorColor 
                            : AppColorsLightMode.errorColor,
                        ),
                        label: Text(
                          'Delete Course',
                          style: TextStyle(
                            color: themeProvider.isDarkMode 
                              ? AppColorsDarkMode.errorColor 
                              : AppColorsLightMode.errorColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: themeProvider.isDarkMode 
                              ? AppColorsDarkMode.errorColor 
                              : AppColorsLightMode.errorColor,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGrade() async {
    setState(() => _isLoading = true);

    try {
      final grade = _gradeController.text.trim();

      // Validate grade
      if (grade.isNotEmpty) {
        final gradeValue = double.tryParse(grade);
        if (gradeValue == null || gradeValue < 0 || gradeValue > 100) {
          _showErrorSnackBar('Please enter a valid grade (0-100)');
          setState(() => _isLoading = false);
          return;
        }
      }

      final studentId = context.read<StudentProvider>().student!.id;
      final success = await context.read<CourseProvider>().updateCourseGrade(
        studentId,
        widget.semester,
        widget.course.courseId,
        grade,
      );

      if (!context.mounted) return;

      if (success) {
        widget.onCourseUpdated?.call();
        Navigator.of(context).pop();
        _showSuccessSnackBar('Grade updated successfully');
      } else {
        _showErrorSnackBar('Failed to update grade');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Error updating grade: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  void _confirmDeleteCourse() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.mainColor,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   side: BorderSide(
        //     color: themeProvider.isDarkMode 
        //       ? AppColorsDarkMode.errorColor 
        //       : AppColorsLightMode.errorColor, 
        //     width: 2,
        //   ),
        // ),
        title: Text(
          'Delete Course',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.course.name}" from ${widget.semester}?',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.textSecondary),
            ),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close confirmation dialog
              await _deleteCourse();
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse() async {
    setState(() => _isLoading = true);

    try {
      final studentId = context.read<StudentProvider>().student!.id;
      final success = await context
          .read<CourseProvider>()
          .removeCourseFromSemester(
            studentId,
            widget.semester,
            widget.course.courseId,
          );

      if (!context.mounted) return;

      if (success) {
        widget.onCourseUpdated?.call();
        Navigator.of(context).pop(); // Close main dialog
        _showSuccessSnackBar('Course deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete course');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar('Error deleting course: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  void _showSuccessSnackBar(String message) {
    if (context.mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: themeProvider.isDarkMode 
            ? AppColorsDarkMode.successColor 
            : AppColorsLightMode.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: themeProvider.isDarkMode 
            ? AppColorsDarkMode.errorColor 
            : AppColorsLightMode.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Helper function to show the popup
void showCourseActionsPopup(
  BuildContext context,
  StudentCourse course,
  String semester, {
  VoidCallback? onCourseUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ Important for keyboard resizing
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CourseActionsPopup(
          course: course,
          semester: semester,
          onCourseUpdated: onCourseUpdated,
        ),
      );
    },
  );
}
