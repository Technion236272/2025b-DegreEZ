import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_notifier.dart';
import '../models/student_model.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({super.key});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  // Controllers for the form fields
  // These controllers will be used to get the text input from the user
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _facultyController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _semesterController = TextEditingController();
  final _catalogController = TextEditingController();

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

  // Build method to create the widget
  // This method is called whenever the widget needs to be rebuilt
  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LogInNotifier>(context);
    final studentNotifier = Provider.of<StudentNotifier>(context);
    final user = loginNotifier.user;

    if (user == null) {
      return const SizedBox.shrink();
    }
    // Fetch student data using StudentNotifier
    // This is a placeholder. In a real app, you would fetch the student data
    // final student = studentNotifier.fetchStudentData(user.uid);
    final student = studentNotifier.student;
    // If student data is loading, show loader
    if (studentNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If student data exists, navigate to home page
    if (student != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {

        Navigator.pushNamedAndRemoveUntil(context, '/calendar_home', (route) => false);
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If student data does not exist, show form to create it

    return Scaffold(
      body: Consumer<LogInNotifier>(
        builder: (context, loginNotifier, _) {
          
          // If student data exists, and student is veteran
          if (loginNotifier.newUser == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
            studentNotifier.fetchStudentData(loginNotifier.user!.uid);
            studentNotifier.error == '' ? 
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home_page',
                (route) => false,
              ): null;
            });
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Complete your profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _majorController,
                    decoration: const InputDecoration(labelText: 'Major'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _facultyController,
                    decoration: const InputDecoration(labelText: 'Faculty'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _preferencesController,
                    decoration: const InputDecoration(labelText: 'Preferences'),
                  ),
                  TextFormField(
                    controller: _semesterController,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Enter a valid semester';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _catalogController,
                    decoration: const InputDecoration(labelText: 'Catalog'),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;

                      final student = StudentModel(
                        id: user.uid,
                        name: _nameController.text.trim(),
                        major: _majorController.text.trim(),
                        faculty: _facultyController.text.trim(),
                        preferences: _preferencesController.text.trim(),
                        semester: int.parse(_semesterController.text.trim()),
                        catalog: _catalogController.text.trim(),
                      );

                      // Create student using StudentNotifier
                      final success = await studentNotifier.createStudent(
                        student,
                      );

                      if (success && context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home_page',
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Save & Continue'),
                  ),
                  if (studentNotifier.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        studentNotifier.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
