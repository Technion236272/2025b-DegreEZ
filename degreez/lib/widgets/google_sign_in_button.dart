import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';

/// A reusable Google Sign-In button widget
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSignInComplete;
  
  const GoogleSignInButton({
    super.key,
    this.onSignInComplete,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LogInNotifier>(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: loginNotifier.isLoading
          ? const CircularProgressIndicator()
          : OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              onPressed: () async {
                try {
                  // Attempt to sign in with Google
                  final user = await loginNotifier.signInWithGoogle();
                  
                  if (user != null && mounted && widget.onSignInComplete != null) {
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
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}