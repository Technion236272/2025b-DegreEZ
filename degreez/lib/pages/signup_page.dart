import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/login_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:degreez/widgets/text_form_field_with_style.dart';
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
  final RegExp _preferencesValidator = RegExp(r'^(.?)+$');
  final RegExp _semesterValidator = RegExp(
    r'^(Winter|Spring|Summer) (\d{4}-\d{2}|\d{4})$',
    caseSensitive: false,
  );

  // Catalog Selection Not Implemented Yet
  // final RegExp _catalogValidator = RegExp(r'');

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
    // context.read<StudentProvider>().fetchStudentData(context.read<LogInNotifier>().user!.uid);
    // });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("entered SignUp Page");
    final loginNotifier = context.watch<LogInNotifier>();
    final studentNotifier = context.watch<StudentProvider>();

    if (loginNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = loginNotifier.user;

    // Fetch student data using StudentProvider
    // This is a placeholder. In a real app, you would fetch the student data
    // final student = studentNotifier.fetchStudentData(user.uid);
    if (context.watch<StudentProvider>().isLoading == false &&
        studentNotifier.student == null &&
        context.read<StudentProvider>().error == '') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        context.read<StudentProvider>().isLoading == false
            ? await context.read<StudentProvider>().fetchStudentData(
              context.read<LogInNotifier>().user!.uid,
            )
            : null;
      });
    }

    final student = studentNotifier.student;

    // If student data is loading, show loader
    if (studentNotifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If student data exists, navigate to home page
    if (context.watch<StudentProvider>().error == '' && student != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home_page',
          (route) => false,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    // If student data does not exist, show form to create it
    return (student == null && context.watch<StudentProvider>().error == '')
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
          body: Consumer<LogInNotifier>(
            builder: (context, loginNotifier, _) {
              // If student data exists, and student is veteran
              // if (loginNotifier.newUser == false ) {
              //   WidgetsBinding.instance.addPostFrameCallback((_) async {
              //     await studentNotifier.fetchStudentData(loginNotifier.user!.uid);

              //     if (!mounted) return;
              //    studentNotifier.error == '' ?
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
              //     studentNotifier.fetchStudentData(loginNotifier.user!.uid);
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
                        children: [                          Text(
                            'Complete your profile',
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(context).secondaryColor,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),                          textFormFieldWithStyle(
                            label: 'Name',
                            controller: _nameController,
                            example: 'e.g. Steve Harvey',
                            validatorRegex: _nameValidator,
                            errorMessage: "Really? an empty name ...",
                            context: context,
                          ),
                          textFormFieldWithStyle(
                            label: 'Major',
                            controller: _majorController,
                            example: 'e.g. Data Analysis',
                            validatorRegex: _majorValidator,
                            errorMessage:
                                "Invalid Input! remember to write the major in English",
                            context: context,
                          ),
                          textFormFieldWithStyle(
                            label: 'Faculty',
                            controller: _facultyController,
                            example: 'e.g. Computer Science',
                            validatorRegex: _facultyValidator,
                            errorMessage:
                                "Invalid Input! remember to write the faculty in English",
                            context: context,
                          ),
                          textFormFieldWithStyle(
                            label: 'Semester',
                            controller: _semesterController,
                            example: 'e.g. Winter 2024-25 or Summer 2021',
                            validatorRegex: _semesterValidator,
                            errorMessage:
                                "should match this template 'Winter 2024-25'",
                            context: context,
                          ),
                          textFormFieldWithStyle(
                            label: 'Preferences',
                            controller: _preferencesController,
                            example:
                                "e.g. I like mathematics and coding related topics and I hate history lessons since I thinks they're boring",
                            validatorRegex: _preferencesValidator,
                            lineNum: 3,
                            context: context,
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
                              if (_formKey.currentState?.validate() != true)
                                {return;}

                              final student = StudentModel(
                                id: user.uid,
                                name: _nameController.text.trim(),
                                major: _majorController.text.trim(),
                                faculty: _facultyController.text.trim(),
                                preferences: _preferencesController.text.trim(),
                                semester: _semesterController.text.trim(),
                                catalog: _catalogController.text.trim(),
                              );

                              // Create student using StudentProvider
                              final success = await studentNotifier
                                  .createStudent(student);

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
                              style: TextStyle(
                                color: AppColorsDarkMode.secondaryColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final rootNavigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );
                              studentNotifier.clear();
                              await loginNotifier.signOut();
                              rootNavigator.pushNamedAndRemoveUntil(
                                '/',
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Sign out and return',
                              style: TextStyle(
                                color: AppColorsDarkMode.secondaryColorDim,
                              ),
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


