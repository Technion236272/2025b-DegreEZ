import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';

/// A reusable Google Sign-In button widget
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSignInComplete;

  const GoogleSignInButton({super.key, this.onSignInComplete});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  @override
  Widget build(BuildContext context) {
    final loginNotifier = context.watch<LogInNotifier>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child:
          loginNotifier.isLoading || context.watch<StudentProvider>().isLoading
              ? LinearProgressIndicator(
                color: context.read<ThemeProvider>().secondaryColor,
                backgroundColor: context.read<ThemeProvider>().accentColor,
              )
              : TextButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().primaryColor : context.read<ThemeProvider>().secondaryColor,
                ),
                onPressed: () async {
                  try {
                    // Attempt to sign in with Google
                    final user = await loginNotifier.signInWithGoogle();

                    if (user != null &&
                        mounted &&
                        widget.onSignInComplete != null) {
                      // Call the onSignInComplete callback if provided
                      widget.onSignInComplete!();
                    }
                      
                  } catch (e) {
                    // Show error dialog on failure
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing in: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Google logo image (using placeholder for simplicity)
                      Container(
                        height: 24.0,
                        width: 24.0,
                        decoration: BoxDecoration(
                          color: context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().mainColor : context.read<ThemeProvider>().primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 300,
                            height: 300,
                            child: Image.asset('assets/google_g_icon.png'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().mainColor : context.read<ThemeProvider>().primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
