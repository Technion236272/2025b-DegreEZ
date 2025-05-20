import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/firebase_options.dart';
import 'providers/login_notifier.dart';
import 'screens/sign_in_page.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if Firebase app is already initialized
  try {
    Firebase.app();
  } catch (e) {
    // Initialize Firebase only if no app exists
    await Firebase.initializeApp(
       name: "dev project",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LogInNotifier(),
      child: MaterialApp(
        title: 'Google Sign-In Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SignInPage(),
      ),
    );
  }
}