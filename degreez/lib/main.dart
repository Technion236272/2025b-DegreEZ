// lib/main.dart - Updated to include CalendarControllerProvider
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart'; // Add this import

import 'services/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/login_notifier.dart';
import 'providers/student_notifier.dart';
import 'pages/student_courses_page.dart';
import 'pages/home_page.dart'; // Your new calendar page

import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env

  // Initialize Firebase
  // Check if Firebase is already initialized
  try {
    Firebase.app();
  } catch (e) {
    debugPrint("Firebase app is not initialized");
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
        ChangeNotifierProvider(
          create: (_) {
            final studentNotifier = StudentNotifier();
            // Initialize the semester info when the provider is created
            studentNotifier.initialize();
            return studentNotifier;
          },
        ),
      ],
      child: CalendarControllerProvider(
        // 🎯 This is the key addition!
        controller: EventController(),
        child: MaterialApp(
          title: 'DegreEZ',
          //         theme: ThemeData.light().copyWith(
          //   scaffoldBackgroundColor: Colors.white,
          //   canvasColor: Colors.white,
          //   cardColor: Colors.white,
          //   colorScheme: const ColorScheme.dark(
          //     surface: Colors.white,
          //   ),
          // ),
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            canvasColor: Colors.black,
            cardColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              surface: Colors.black,
            ),
          ),
          // theme: ThemeData(
          //   colorScheme: ColorScheme.fromSeed(
          //     seedColor: Colors.black,
          //     primary: Colors.black,
          //     secondary: AppColorsDarkMode.secondaryColor,
          //     secondaryFixedDim: AppColorsDarkMode.secondaryColorDim,
          //     tertiary: AppColorsDarkMode.accentColor, // Used as accent
          //   ),
          // ),
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home_page':
                (context) =>
                    CalendarHomePage(), // Keep for backward compatibility
            '/calendar_home':
                (context) => CalendarHomePage(), // New calendar home
            '/courses': (context) => const StudentCoursesPage(),
          },
        ),
      ),
    );
  }
}
