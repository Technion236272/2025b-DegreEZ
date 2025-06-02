import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../models/student_model.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({super.key});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  // Controllers for the form fields
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _facultyController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _semesterController = TextEditingController();
  final _catalogController = TextEditingController();
  
  // Add these flags to prevent repeated navigation
  bool _hasNavigatedToHome = false;
  bool _hasTriedToFetchExistingUser = false;

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
  Widget build(BuildContext context) {
    return Consumer3<LogInNotifier, StudentProvider, CourseProvider>(
      builder: (context, loginNotifier, studentProvider, courseProvider, _) {
        final user = loginNotifier.user;

        if (user == null) {
          return const SizedBox.shrink();
        }

        // If student data is loading, show loader
        if (studentProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading student data...'),
                ],
              ),
            ),
          );
        }

        // If student data exists, navigate to home page (only once)
        if (studentProvider.hasStudent && !_hasNavigatedToHome) {
          _hasNavigatedToHome = true; // Set flag to prevent repeated navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Add mounted check
              // Load student courses after navigating
              courseProvider.loadStudentCourses(studentProvider.student!.id);
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/calendar_home', 
                (route) => false,
              );
            }
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your workspace...'),
                ],
              ),
            ),
          );
        }

        // Check if this is a returning user (only try once)
        if (!loginNotifier.newUser && !_hasTriedToFetchExistingUser) {
          _hasTriedToFetchExistingUser = true; // Set flag to prevent repeated attempts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Add mounted check
              // Fetch existing student data
              studentProvider.fetchStudent(user.uid).then((success) {
                if (success && mounted) {
                  // Load courses for existing user
                  courseProvider.loadStudentCourses(user.uid);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/calendar_home', // Changed to match other navigation
                    (route) => false,
                  );
                }
              });
            }
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Welcome back! Loading your data...'),
                ],
              ),
            ),
          );
        }

        // New user - show profile creation form
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // User info header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? Text(user.displayName?.substring(0, 1) ?? 'U')
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'User',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  user.email ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Tell us about yourself',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),

                  // Form fields
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _facultyController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      hintText: 'e.g., Engineering, Science, Medicine',
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Faculty is required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _majorController,
                    decoration: const InputDecoration(
                      labelText: 'Major',
                      hintText: 'e.g., Computer Science, Biology',
                      prefixIcon: Icon(Icons.science),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Major is required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _semesterController,
                    decoration: const InputDecoration(
                      labelText: 'Current Semester',
                      hintText: 'Enter semester number (e.g., 1, 2, 3)',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Semester is required';
                      final n = int.tryParse(v);
                      return n == null || n < 1 ? 'Enter a valid semester number' : null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _catalogController,
                    decoration: const InputDecoration(
                      labelText: 'Catalog Year',
                      hintText: 'e.g., 2024',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Catalog year is required' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _preferencesController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Interests (Optional)',
                      hintText: 'e.g., AI, Mobile Development, Research',
                      prefixIcon: Icon(Icons.interests),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 32),

                  // Error display
                  if (studentProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              studentProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Submit button
                  ElevatedButton(
                    onPressed: studentProvider.isLoading ? null : () => _submitForm(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: studentProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Profile'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign out option
                  TextButton(
                    onPressed: () {
                      loginNotifier.signOut();
                    },
                    child: const Text('Sign out and use different account'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final loginNotifier = context.read<LogInNotifier>();
    final studentProvider = context.read<StudentProvider>();
    // final courseProvider = context.read<CourseProvider>();
    
    final user = loginNotifier.user!;

    // Create student model
    final student = StudentModel(
      id: user.uid,
      name: _nameController.text.trim(),
      major: _majorController.text.trim(),
      faculty: _facultyController.text.trim(),
      preferences: _preferencesController.text.trim(),
      semester: int.parse(_semesterController.text.trim()),
      catalog: _catalogController.text.trim(),
    );

    // Create student profile
    final success = await studentProvider.createStudent(student);
    
    if (success && context.mounted) {
      // Initialize empty course data for new user
      // (No need to load courses since new user has none)
      
      // Navigate to home page
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/calendar_home',
        (route) => false,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully! Welcome to DegreEZ!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
