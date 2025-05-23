import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/firebase_options.dart';
import 'pages/sign_in_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/login_notifier.dart';
import 'providers/student_notifier.dart';
import 'pages/home_page.dart';
import 'pages/student_courses_page.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env
  

  // Initialize Firebase
  // Check if Firebase is already initialized
  try {
    Firebase.app();
  } catch (e) {
    debugPrint("Firebase app is not  initialized");
    // Initialize Firebase only if no app exists
    await Firebase.initializeApp(
       name: "DegreEZ",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LogInNotifier()),
        ChangeNotifierProvider(create: (_) => StudentNotifier()),
      ],
      child: MaterialApp(
        title: 'DegreEZ',
        theme: ThemeData.light(),
        // home: const SignInPage(),
        initialRoute: '/',
        routes: {
          '/': (context) => SignInPage(),
          '/home_page': (context) => HomePage(),
          '/courses': (context) => const StudentCoursesPage(),
        }
    )
    );
    
  }
}
