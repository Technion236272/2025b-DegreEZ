import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_notifier.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/user_info_widget.dart';

/// Main sign-in page that shows either sign-in button or user info based on auth state
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Demo'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
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

          // Show different UI based on authentication state
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: loginNotifier.isSignedIn
                        // User is signed in, show user info and sign out button
                        ? const UserInfoWidget()
                        // User is not signed in, show sign-in button
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Please sign in with your Google account to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 32),
                              GoogleSignInButton(
                                onSignInComplete: () {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully signed in!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                              if (loginNotifier.isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16.0),
                                  child: Text(
                                    'Signing in...',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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