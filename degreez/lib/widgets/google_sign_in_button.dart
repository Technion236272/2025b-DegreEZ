import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../color/color_palette.dart';

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
    final loginNotifier = Provider.of<LogInNotifier>(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child:
          loginNotifier.isLoading
              ? const LinearProgressIndicator(
                color: AppColorsDarkMode.secondaryColor,
                backgroundColor: AppColorsDarkMode.accentColor,
              )
              : TextButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColorsDarkMode.accentColor,
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
                    if (mounted) {
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
                        decoration: const BoxDecoration(
                          color: AppColorsDarkMode.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                        width: 300,
                        height: 300,
                        child:  Image.asset(
                            'assets/google_g_icon.png',
                          ),
                      ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColorsDarkMode.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
