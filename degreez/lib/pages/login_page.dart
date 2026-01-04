import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../services/theme_sync_service.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _hasHandledPostLogin = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.mainColor,
          body: Stack(
            children: [
              // Background decoration
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeProvider.isDarkMode
                          ? [
                              const Color(0xFF17191B),
                              const Color(0xFF1F3D56),
                              const Color(0xFF17191B),
                            ]
                          : [
                              const Color(0xFFFAFAFA),
                              const Color(0xFFE8F5E9),
                              const Color(0xFFFAFAFA),
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Decorative circles
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider.primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider.accentColor.withOpacity(0.1),
                  ),
                ),
              ),
              
              Consumer3<LogInNotifier, StudentProvider, CourseProvider>(
                builder: (context, loginNotifier, studentProvider, courseProvider, _) {
                  // Display error message if any
                  if (loginNotifier.errorMessage != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loginNotifier.errorMessage!),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Dismiss',
                            textColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    });
                  }

                  // Handle post-login flow
                  if (loginNotifier.isSignedIn && !_hasHandledPostLogin) {
                    _hasHandledPostLogin = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;

                      final user = loginNotifier.user!;
                      
                      // Try to fetch existing student data
                      final studentExists = await studentProvider.fetchStudentData(user.uid);
                      
                      if (studentExists && studentProvider.hasStudent) {
                        // Existing user - load courses and sync theme preference
                        await courseProvider.loadStudentCourses(user.uid);
                        if (!context.mounted) return;
                        // Sync the user's theme preference
                        await ThemeSyncService.syncStudentThemePreference(context);
                        if (!context.mounted) return;
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home_page',
                            (route) => false,
                          );
                        }
                      } else {
                        if (!context.mounted) return;
                        // New user - go to signup page
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/sign_up_page',
                          (route) => false,
                        );
                      }
                    });

                    // Show loading state while handling post-login
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            loginNotifier.stayedSignedIn 
                                ? 'Welcome back!'
                                : 'Setting up your account...',
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Loading your academic data...',
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show login form if not signed in
                  return SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo and App name
                              Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeProvider.primaryColor.withOpacity(0.2),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    themeProvider.isDarkMode 
                                      ? 'assets/Logo_DarkMode3.png'
                                      : 'assets/Logo3.png',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              Text(
                                'DegreEZ',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.textPrimary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your academic journey made easy',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: themeProvider.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(height: 48),

                              // Login Card
                              Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(32.0),
                                decoration: BoxDecoration(
                                  color: themeProvider.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: themeProvider.isDarkMode 
                                        ? Colors.white.withOpacity(0.05) 
                                        : Colors.black.withOpacity(0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Welcome',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign in to continue to your dashboard',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: themeProvider.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // Gmail Sign-In button
                                    const GoogleSignInButton(),

                                    const SizedBox(height: 24),

                                    // Help text
                                    Text(
                                      'By signing in, you agree to our Terms of Service and Privacy Policy.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: themeProvider.textTertiary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Text(
                                'v2.2.1',
                                style: TextStyle(
                                  color: themeProvider.textTertiary.withOpacity(0.5),
                                  fontSize: 12,
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
            ],
          ),
        );
      },
    );
  }
}
