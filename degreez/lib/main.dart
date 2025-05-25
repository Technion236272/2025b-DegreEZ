import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/login_notifier.dart';
import 'providers/student_notifier.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

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
        // home: const SignInPage(),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/home_page': (context) => HomePage(),
        }
    )
    );
    
  }
}
