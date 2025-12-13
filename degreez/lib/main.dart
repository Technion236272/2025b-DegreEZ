// lib/main.dart - Updated to include CalendarControllerProvider
import 'package:degreez/pages/navigator_page.dart';
import 'package:degreez/providers/course_recommendation_provider.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

import 'pages/auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to load .env file, but continue if it doesn't exist
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env file not found, continuing without it: $e');
  }
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);  // Initialize Firebase. If Firebase options for the current platform (web)
  // are not configured, log and continue so the app UI can run (features
  // requiring Firebase will still be disabled).
    try {
      // Try to use an existing app (e.g. during hot-restart)
      Firebase.app();
    } catch (_) {
      try {
        // Initialize the default Firebase app so FirebaseAuth and other
        // packages can access the [DEFAULT] app instance.
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        // Enable Firestore offline persistence for web
        // This caches data in IndexedDB for faster subsequent loads
        if (kIsWeb) {
          try {
            await FirebaseFirestore.instance.enablePersistence(
              const PersistenceSettings(synchronizeTabs: true),
            );
            debugPrint('✅ Firestore persistence enabled for web');
          } catch (e) {
            // Persistence can fail if:
            // - Multiple tabs are open
            // - Browser is in incognito mode
            // - IndexedDB is disabled
            debugPrint('⚠️ Could not enable Firestore persistence: $e');
          }
        }
      } catch (e) {
        // Fail gracefully when Firebase is not configured for the current
        // platform (common for web until FlutterFire is configured).
        debugPrint('Firebase initialization skipped: $e');
      }
    }
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
            });            return MaterialApp(
              title: 'DegreEZ',
              theme: themeProvider.themeData,
              initialRoute: '/',
              routes: {
                '/': (context) => AuthWrapper(),
                '/login': (context) => LoginPage(),
                '/home_page': (context) => NavigatorPage(),
                '/sign_up_page': (context) => SignUpPage(),
              },            );
          },
        ),
      ),
    );
  }
}