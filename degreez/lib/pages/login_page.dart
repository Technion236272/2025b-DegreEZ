import 'package:degreez/color/color_palette2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../color/color_palette.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool _hasHandledPostLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<LogInNotifier, StudentProvider, CourseProvider>(
        builder: (context, loginNotifier, studentProvider, courseProvider, _) {
          // Display error message if any
          if (loginNotifier.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loginNotifier.errorMessage!),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            });
          }
          //NEW CODE AREA START

          // Handle post-login flow
          if (loginNotifier.isSignedIn && !_hasHandledPostLogin) {
            _hasHandledPostLogin = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;

              final user = loginNotifier.user!;
              
              // Try to fetch existing student data
              final studentExists = await studentProvider.fetchStudentData(user.uid);
              
              if (!mounted) return;

              if (studentExists && studentProvider.hasStudent) {
                // Existing user - load courses and go to home
                await courseProvider.loadStudentCourses(user.uid);
                
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home_page',
                    (route) => false,
                  );
                }
              } else {
                // New user - go to signup page
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/sign_up_page',
                  (route) => false,
                );
              }
            });

            // Show loading state while handling post-login
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      loginNotifier.stayedSignedIn 
                          ? 'Welcome back! Loading your data...'
                          : 'Setting up your account...',
                        style: TextStyle(
                          fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          //NEW CODE AREA END
          // Show login form if not signed in
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and App name
                      Column(
                        children: [
                          // App Logo
                          SizedBox(
                            width: 350,
                            height: 350,
                            child: Image.asset('assets/Logo.png'),
                          ),
                          const SizedBox(height: 16),
                          // App Name
                          Text(
                            'DegreEZ',
                                                        style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your academic journey made easy',
                                                        style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Login Card
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),

                              Text(
                                'Sign in with your Google account to continue',
                              ),

                              const SizedBox(height: 24),

                              // Gmail Sign-In button
                              GoogleSignInButton(),

                              const SizedBox(height: 16),

                              // Help text
                              Text(
                                'We only use your Gmail account for authentication purposes.',
                                textAlign: TextAlign.center,
                                                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimaryDim,
                                ),
                              ),
                              const SizedBox(height: 24),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
