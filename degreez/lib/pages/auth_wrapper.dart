import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../services/theme_sync_service.dart';
import 'login_page.dart';

/// AuthWrapper checks authentication state and shows the appropriate screen
/// This prevents the flash of the login page for already authenticated users
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final loginNotifier = context.read<LogInNotifier>();
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    // Wait a brief moment for Firebase to initialize
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final user = loginNotifier.user;

    if (user != null) {
      // User is signed in, check if they have completed signup
      final studentExists = await studentProvider.fetchStudentData(user.uid);

      if (!mounted) return;

      if (studentExists && studentProvider.hasStudent) {
        // Existing user - load courses and sync theme
        await courseProvider.loadStudentCourses(user.uid);
        if (!mounted) return;
        await ThemeSyncService.syncStudentThemePreference(context);
        if (!mounted) return;

        // Navigate to home page
        setState(() {
          _isInitializing = false;
          _hasNavigated = true;
        });

        // Use a brief delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/home_page');
      } else {
        // User authenticated but hasn't completed signup
        setState(() {
          _isInitializing = false;
          _hasNavigated = true;
        });

        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/sign_up_page');
      }
    } else {
      // No user signed in, show login page
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Show splash screen while checking auth state
    if (_isInitializing || _hasNavigated) {
      return Scaffold(
        backgroundColor: themeProvider.mainColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  themeProvider.isDarkMode 
                    ? 'assets/Logo_DarkMode3.png'
                    : 'assets/Logo3.png',
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                color: themeProvider.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show login page if not signed in
    return const LoginPage();
  }
}
