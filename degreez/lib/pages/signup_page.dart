import 'dart:async';

import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_notifier.dart';
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
    r'(Winter|Spring|Summer) (\d{4}-\d{2}|\d{4})',
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
  Widget build(BuildContext context) {
    debugPrint("entered SignUp Page");
    final loginNotifier = Provider.of<LogInNotifier>(context);
    final studentNotifier = Provider.of<StudentNotifier>(context);

    final user = loginNotifier.user;
    if (user == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      throw AsyncError("user is null and still in SignUp page", null);
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/calendar_home',
          (route) => false,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If student data does not exist, show form to create it

    return Scaffold(
      body: Consumer<LogInNotifier>(
        builder: (context, loginNotifier, _) {
          // If student data exists, and student is veteran
          if (loginNotifier.newUser == false && student != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              studentNotifier.fetchStudentData(loginNotifier.user!.uid);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home_page',
                (route) => false,
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          // if (loginNotifier.stayedSignedIn == true) {
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     studentNotifier.fetchStudentData(loginNotifier.user!.uid);
          //     Navigator.pushNamedAndRemoveUntil(
          //       context,
          //       '/',
          //       (route) => false,
          //     );
          //   });
          //   return const Center(child: CircularProgressIndicator());
          // }

          return Padding(
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
                  textFormFieldWithStyle(
                    label: 'Name',
                    controller: _nameController,
                    example: 'e.g. Steve Harvey',
                    validatorRegex: _nameValidator,
                    errorMessage: "Really? an empty name ...",
                  ),
                  textFormFieldWithStyle(
                    label: 'Major',
                    controller: _majorController,
                    example: 'e.g. Data Analysis',
                    validatorRegex: _majorValidator,
                    errorMessage:
                        "Invalid Input! remember to write the major in English",
                  ),
                  textFormFieldWithStyle(
                    label: 'Faculty',
                    controller: _facultyController,
                    example: 'e.g. Computer Science',
                    validatorRegex: _facultyValidator,
                    errorMessage:
                        "Invalid Input! remember to write the faculty in English",
                  ),
                  textFormFieldWithStyle(
                    label: 'Semester',
                    controller: _semesterController,
                    example: 'e.g. Winter 2024-25 or Summer 2021',
                    validatorRegex: _semesterValidator,
                    errorMessage: "should match this template 'Winter 2024-25'",
                  ),
                  textFormFieldWithStyle(
                    label: 'Preferences',
                    controller: _preferencesController,
                    example:
                        "e.g. I like mathematics and coding related topics and I hate history lessons since I thinks they're boring",
                    validatorRegex: _preferencesValidator,
                    lineNum: 3,
                  ),

                  // Should be changed to Catalog Picker

                  // TextFormField(
                  //   controller: _catalogController,
                  //   decoration: const InputDecoration(labelText: 'Catalog'),
                  //   validator:
                  //       (v) => v == null || v.isEmpty ? 'Required' : null,
                  // ),
                  const SizedBox(height: 24),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsDarkMode.accentColor,
                    ),
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
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(color: AppColorsDarkMode.secondaryColor),
                    ),
                  ),
                  // TextButton(
                  //   onPressed: () async {
                  //     studentNotifier.clear();
                  //     await loginNotifier.signOut();
                  //     if (context.mounted) {
                  //       Navigator.of(
                  //         context,
                  //       ).pushNamedAndRemoveUntil('/', (route) => false);
                  //     }
                  //   },
                  //   child: const Text(
                  //     'Sign out and return',
                  //     style: TextStyle(
                  //       color: AppColorsDarkMode.secondaryColorDim,
                  //     ),
                  //   ),
                  // ),
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

textFormFieldWithStyle({
  required String label,
  required TextEditingController controller,
  required String example,
  required RegExp validatorRegex,
  int? lineNum,
  String? errorMessage,
}) {
  return Padding(
    padding: EdgeInsets.only(top: 10, bottom: 10),
    child: TextFormField(
      textAlign: TextAlign.start,
      maxLines: lineNum ?? 1,
      controller: controller,
      cursorColor: AppColorsDarkMode.secondaryColor,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.secondaryColor,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.secondaryColorDimDD),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.errorColor,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.errorColorDim),
        ),
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColor),
        hoverColor: AppColorsDarkMode.secondaryColor,
        hintText: example,
        hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
      ),
      style: TextStyle(color: AppColorsDarkMode.secondaryColor, fontSize: 15),
      validator: (value) {
        if (value == null) {
          return 'This field is required.';
        }

        if (!validatorRegex.hasMatch(value)) {
          debugPrint("value = $value");
          if (value == '') {
            return 'This field is required.';
          }
          return errorMessage ?? 'Invalid Input';
        }

        return null; // Input is valid
      },
    ),
  );
}
