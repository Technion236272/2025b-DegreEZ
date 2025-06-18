// lib/main.dart - Updated to include CalendarControllerProvider
import 'package:degreez/pages/navigator_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart';


import 'services/firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'color/color_palette.dart';

// Updated providers - using only the new ones
import 'providers/login_notifier.dart';
import 'providers/student_provider.dart';
import 'providers/course_provider.dart';
import 'providers/course_data_provider.dart';
import 'providers/customized_diagram_notifier.dart';
import 'providers/color_theme_provider.dart';

import 'pages/login_page.dart';
import 'pages/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,DeviceOrientation.portraitDown
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
    return MultiProvider(
      providers: [
        // Authentication
        ChangeNotifierProvider(create: (_) => LogInNotifier()),
        
        // New improved providers
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = CourseDataProvider();
            provider.initialize();
            return provider;
          },
        ),
        
        // UI providers
        ChangeNotifierProvider(create: (_) => CustomizedDiagramNotifier()),
        ChangeNotifierProvider(create: (_) => ColorThemeProvider()),
      ],
      child: CalendarControllerProvider(
        controller: EventController(),
        child: MaterialApp(
          title: 'DegreEZ',          theme: ThemeData.dark().copyWith(
            dialogTheme:DialogTheme(backgroundColor: AppColorsDarkMode.accentColorDark,shape: RoundedRectangleBorder(
              side: BorderSide(
                color: AppColorsDarkMode.secondaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),),
            dividerTheme: DividerThemeData(color: AppColorsDarkMode.dividerColor),
            scaffoldBackgroundColor: AppColorsDarkMode.mainColor,
            canvasColor: AppColorsDarkMode.mainColor,
            cardColor: AppColorsDarkMode.mainColor,
            colorScheme: const ColorScheme.dark(
              surface: AppColorsDarkMode.mainColor,
              primary: AppColorsDarkMode.secondaryColor,
              secondary: AppColorsDarkMode.secondaryColor,
              onPrimary: AppColorsDarkMode.accentColor,
              onSecondary: AppColorsDarkMode.accentColor,
              onSurface: AppColorsDarkMode.secondaryColorDim,
            ),
            // FAB theme
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: AppColorsDarkMode.secondaryColor,
              foregroundColor: AppColorsDarkMode.accentColor,
              elevation:8,
            ),
            // Icon theme
            iconTheme: const IconThemeData(
              color: AppColorsDarkMode.secondaryColor,
            ),
            primaryIconTheme: const IconThemeData(
              color: AppColorsDarkMode.secondaryColor,
            ),
            // Text theme with light colors from palette
            textTheme: ThemeData.dark().textTheme.copyWith(
              bodyLarge: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              bodyMedium: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              bodySmall: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              headlineLarge: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              headlineMedium: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              headlineSmall: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              titleLarge: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              titleMedium: const TextStyle(color: AppColorsDarkMode.secondaryColor),
              titleSmall: const TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
            // App bar theme
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColorsDarkMode.mainColor,
              foregroundColor: AppColorsDarkMode.secondaryColor,
              iconTheme: IconThemeData(color: AppColorsDarkMode.secondaryColor),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home_page': (context) => NavigatorPage(),
            '/sign_up_page': (context) => const SignUpPage(),
          },
        ),
      ),
    );
  }
}
