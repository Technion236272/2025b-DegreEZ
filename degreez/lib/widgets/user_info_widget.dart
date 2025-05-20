import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';

/// A widget to display user information and sign out button
class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the login notifier from the provider
    final loginNotifier = Provider.of<LogInNotifier>(context);
    final user = loginNotifier.user;
    
    // If no user, return empty container (should not happen due to conditional rendering)
    if (user == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // User avatar (if available) or a placeholder
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null
              ? Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName![0].toUpperCase()
                      : user.email?[0].toUpperCase() ?? '?',
                  style: const TextStyle(fontSize: 30),
                )
              : null,
        ),
        const SizedBox(height: 16),
        
        // User display name (if available) or email
        Text(
          'Welcome, ${user.displayName ?? user.email ?? 'User'}!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Show email if display name is available
        if (user.displayName != null && user.email != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              user.email!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Sign out button
        loginNotifier.isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: () async {
                  await loginNotifier.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully signed out'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
      ],
    );
  }
}