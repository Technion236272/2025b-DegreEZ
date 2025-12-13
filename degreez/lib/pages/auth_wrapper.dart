import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    debugPrint('🔍 AuthWrapper: Waiting for Firebase Auth to initialize...');
    
    // Wait for Firebase Auth to properly restore the user session
    // This is important on web refresh where the auth state needs time to be restored
    User? user;
    try {
      // Use authStateChanges().first to wait for the initial auth state
      // This properly waits for Firebase to restore the session from persistence
      user = await FirebaseAuth.instance.authStateChanges().first;
    } catch (e) {
      debugPrint('⚠️ AuthWrapper: Error waiting for auth state: $e');
      user = loginNotifier.user;
    }

    if (!mounted) return;
    
    debugPrint('🔍 AuthWrapper: Checking auth state...');
    debugPrint('🔍 AuthWrapper: User is ${user != null ? "signed in (${user.uid})" : "not signed in"}');

    if (user != null) {
      debugPrint('🔍 AuthWrapper: Fetching student data for user ${user.uid}');
      
      // User is signed in, check if they have completed signup
      final studentExists = await studentProvider.fetchStudentData(user.uid);

      if (!mounted) return;
      
      debugPrint('🔍 AuthWrapper: Student exists: $studentExists, hasStudent: ${studentProvider.hasStudent}');
      debugPrint('🔍 AuthWrapper: Student data: ${studentProvider.student?.toString()}');

      if (studentExists && studentProvider.hasStudent) {
        debugPrint('✅ AuthWrapper: Existing user found, loading courses...');
        
        // Existing user - load courses and sync theme
        await courseProvider.loadStudentCourses(user.uid);
        if (!mounted) return;
        await ThemeSyncService.syncStudentThemePreference(context);
        if (!mounted) return;

        debugPrint('✅ AuthWrapper: Navigating to home page');
        
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
        debugPrint('⚠️ AuthWrapper: User authenticated but no student profile found, navigating to signup');
        
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
      debugPrint('ℹ️ AuthWrapper: No user signed in, showing login page');
      
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
