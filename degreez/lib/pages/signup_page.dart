import 'dart:async';

import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for the form fields
  // These controllers will be used to get the text input from the user
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _facultyController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _semesterController = TextEditingController();

  // Catalog Selection Not Implemented Yet
  final _catalogController = TextEditingController();

  final RegExp _nameValidator = RegExp(r'^(?!\s*$).+');
  final RegExp _majorValidator = RegExp(r'^(?!\s*$)[A-Za-z\s]+$');
  final RegExp _facultyValidator = RegExp(r'^(?!\s*$)[A-Za-z\s]+$');
  final RegExp _preferencesValidator = RegExp(r'^.?$');
  final RegExp _semesterValidator = RegExp(
    r'^(Winter|Spring|Summer) (\d{4}-\d{2}|\d{4})$',
    caseSensitive: false,
  );

  // Catalog Selection Not Implemented Yet
  final RegExp _catalogValidator = RegExp(r'');

  // Dispose the controllers when the widget is removed from the widget tree
  // This is important to free up resources and avoid memory leaks
  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _facultyController.dispose();
    _preferencesController.dispose();
    _semesterController.dispose();
    _catalogController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // context.read<StudentProvider>().fetchStudent(context.read<LogInNotifier>().user!.uid);
    // });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("entered SignUp Page");
    final loginNotifier = context.watch<LogInNotifier>();
    final studentProvider = context.watch<StudentProvider>();

    if (loginNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = loginNotifier.user;

    // Fetch student data using StudentProvider
    // This is a placeholder. In a real app, you would fetch the student data
    // final student = studentProvider.fetchStudent(user.uid);
    if (context.watch<StudentProvider>().isLoading == false &&
        studentProvider.student == null &&
        context.read<StudentProvider>().error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        context.read<StudentProvider>().isLoading == false
            ? await context.read<StudentProvider>().fetchStudent(
              context.read<LogInNotifier>().user!.uid,
            )
            : null;
      });
    }

    final student = studentProvider.student;

    // If student data is loading, show loader
    if (studentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If student data exists, navigate to home page
    if (context.watch<StudentProvider>().error == null && student != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/calendar_home',
          (route) => false,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If student data does not exist, show form to create it
    return (student == null && context.watch<StudentProvider>().error == null)
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
          body: Consumer<LogInNotifier>(
            builder: (context, loginNotifier, _) {
              // If student data exists, and student is veteran
              // if (loginNotifier.newUser == false ) {
              //   WidgetsBinding.instance.addPostFrameCallback((_) async {
              //     await studentProvider.fetchStudent(loginNotifier.user!.uid);

              //     if (!mounted) return;
              //    studentProvider.error == null ?
              //     Navigator.pushNamedAndRemoveUntil(
              //       context,
              //       '/home_page',
              //       (route) => false,
              //     ): null;
              //   });
              //   return const Center(child: CircularProgressIndicator());
              // }

              // if (loginNotifier.stayedSignedIn == true) {
              //   WidgetsBinding.instance.addPostFrameCallback((_) {
              //     studentProvider.fetchStudent(loginNotifier.user!.uid);
              //     Navigator.pushNamedAndRemoveUntil(
              //       context,
              //       '/',
              //       (route) => false,
              //     );
              //   });
              //   return const Center(child: CircularProgressIndicator());
              // }

              return loginNotifier.isLoading || user == null
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text(
                            'Complete your profile',
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hello ${user.displayName ?? user.email ?? 'Student'}!',
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColorDim,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Name field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(
                                Icons.person,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            validator: (value) {
                              if (value == null || 
                                  value.isEmpty || 
                                  !_nameValidator.hasMatch(value)) {
                                return 'Please enter a valid name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Major field
                          TextFormField(
                            controller: _majorController,
                            decoration: InputDecoration(
                              labelText: 'Major',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'e.g., Computer Science',
                              prefixIcon: Icon(
                                Icons.school,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            validator: (value) {
                              if (value == null || 
                                  value.isEmpty || 
                                  !_majorValidator.hasMatch(value)) {
                                return 'Please enter a valid major';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Faculty field
                          TextFormField(
                            controller: _facultyController,
                            decoration: InputDecoration(
                              labelText: 'Faculty',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'e.g., Engineering',
                              prefixIcon: Icon(
                                Icons.business,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            validator: (value) {
                              if (value == null || 
                                  value.isEmpty || 
                                  !_facultyValidator.hasMatch(value)) {
                                return 'Please enter a valid faculty';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Current Semester field - Changed to String format
                          TextFormField(
                            controller: _semesterController,
                            decoration: InputDecoration(
                              labelText: 'Current Semester',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'e.g., Winter 2024 or Spring 2024-25',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current semester';
                              }
                              // Validate semester format (e.g., "Winter 2024" or "Spring 2024-25")
                              if (!_semesterValidator.hasMatch(value)) {
                                return 'Format: Season Year (e.g., Winter 2024)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Catalog field
                          TextFormField(
                            controller: _catalogController,
                            decoration: InputDecoration(
                              labelText: 'Catalog Year',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'e.g., 2023-2024',
                              prefixIcon: Icon(
                                Icons.book,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your catalog year';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Preferences field (optional)
                          TextFormField(
                            controller: _preferencesController,
                            decoration: InputDecoration(
                              labelText: 'Preferences (Optional)',
                              labelStyle: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
                              hintText: 'Any special preferences or notes',
                              prefixIcon: Icon(
                                Icons.note,
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColorDim,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColorsDarkMode.secondaryColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: AppColorsDarkMode.secondaryColor,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          ElevatedButton(
                            onPressed: studentProvider.isLoading
                                ? null
                                : () => _submitForm(context, user, studentProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColorsDarkMode.secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: studentProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Complete Profile',
                                    style: TextStyle(
                                      color: AppColorsDarkMode.mainColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Error message
                          if (studentProvider.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      studentProvider.error!,
                                      style: TextStyle(color: Colors.red.shade700),
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

  Future<void> _submitForm(BuildContext context, user, StudentProvider studentProvider) async {
    if (_formKey.currentState!.validate()) {
      // Create a new student model
      final newStudent = StudentModel(
        id: user.uid, // Use Firebase Auth UID
        name: _nameController.text.trim(),
        major: _majorController.text.trim(),
        faculty: _facultyController.text.trim(),
        preferences: _preferencesController.text.trim(),
        semester: _semesterController.text.trim(), // Now stored as String
        catalog: _catalogController.text.trim(),
      );

      // Save the student to Firestore using StudentProvider
      final success = await studentProvider.createStudent(newStudent);

      if (success && mounted) {
        // Navigate to home page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/calendar_home',
          (route) => false,
        );
      }
      // Error handling is done automatically through the provider's error state
    }
  }
}
