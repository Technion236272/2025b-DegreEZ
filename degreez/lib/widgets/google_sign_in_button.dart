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
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final loginNotifier = context.watch<LogInNotifier>();
    final themeProvider = context.read<ThemeProvider>();
    final isLoading = loginNotifier.isLoading || context.watch<StudentProvider>().isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovering && !isLoading ? 1.02 : 1.0),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.isDarkMode 
                      ? Colors.white 
                      : Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: _isHovering ? 4 : 1,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Google logo image
                    Image.asset(
                      'assets/google_g_icon.png',
                      height: 24.0,
                      width: 24.0,
                    ),
                    const SizedBox(width: 12.0),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87, // Always black text on white button for Google standard
                        fontFamily: 'Roboto', // Google standard font
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
