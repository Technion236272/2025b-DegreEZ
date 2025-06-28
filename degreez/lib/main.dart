// lib/main.dart - Updated to include CalendarControllerProvider
import 'package:degreez/pages/navigator_page.dart';
import 'package:degreez/providers/course_recommendation_provider.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart';

import 'services/firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Updated providers - using only the new ones
import 'providers/login_notifier.dart';
import 'providers/student_provider.dart';
import 'providers/course_provider.dart';
import 'providers/course_data_provider.dart';
import 'providers/customized_diagram_notifier.dart';
import 'providers/theme_provider.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Initialize Firebase
  try {
    Firebase.app();
  } catch (e) {
    debugPrint("Firebase app is not initialized");
    await Firebase.initializeApp(
      name: "DegreEZ",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // final model =
  //     FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(      providers: [
        // Authentication
        ChangeNotifierProvider(create: (_) => LogInNotifier()),

        // New improved providers
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),

        // Course Recommendation Provider - now simple instantiation
        ChangeNotifierProvider(create: (_) => CourseRecommendationProvider()),

        ChangeNotifierProvider(
          create: (_) {
            final provider = CourseDataProvider();
            provider.initialize();
            return provider;
          },
        ),

        // UI providers
        ChangeNotifierProvider(create: (_) => CustomizedDiagramNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Unified theme provider

        // Sign Up Values provider
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
      ],      child: CalendarControllerProvider(
        controller: EventController(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            // Update system brightness if needed
            final brightness = MediaQuery.of(context).platformBrightness;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeProvider.updateSystemBrightness(brightness);
            });

            return MaterialApp(
              title: 'DegreEZ',
              theme: themeProvider.themeData,
              initialRoute: '/',
              routes: {
                '/': (context) => LoginPage(),
                '/home_page': (context) => NavigatorPage(),
                '/sign_up_page': (context) => const SignUpPage(),
              },            );
          },
        ),
      ),
    );
  }
}