import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_notifier.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/user_info_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LogInNotifier>(
        builder: (context, loginNotifier, _) {
          // Display error message if any
          if (loginNotifier.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loginNotifier.errorMessage!),
                  backgroundColor: Colors.red,
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

          return loginNotifier.isSignedIn
                        // const UserInfoWidget()  will be replaced with a rerouting to the home page
                        // when the user is signed in, we will use the Navigator to push the home page
                        // Navigator.pushNamed(context, '/home_page');
                        // which will add the data of the user to a student model
                        // and then we will use the provider to set the data of the user
                        ? const UserInfoWidget() 
                        // User is not signed in, show sign-in button
                        : SafeArea(
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
                            child: Image.asset('assets/Logo_DarkMode2.png'),
                          ),
                          const SizedBox(height: 16),
                          // App Name
                          Text(
                            'DegreEZ',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFCBAAD),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your academic journey made easy',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xAAFCBAAD),
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
                                style: TextStyle(color: Color(0xAAFCBAAD)),
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
                                  color: Color(0xAAFCBAAD),
                                ),
                              ),
                              const SizedBox(height: 24), // Add some spacing

                              const SizedBox(
                                height: 16,
                              ), // Existing help text spacing
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
