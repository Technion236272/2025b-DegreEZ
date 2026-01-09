import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';

class TutorialPopup extends StatefulWidget {
  const TutorialPopup({super.key});

  @override
  State<TutorialPopup> createState() => _TutorialPopupState();
}

class _TutorialPopupState extends State<TutorialPopup> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Tutorial content defining the slides
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to DegreEZ! 🎓',
      'description': 'Your smart academic companion is here to simplify your degree planning.\n\nSwipe to see what you can do! 👉',
      'icon': Icons.school_rounded,
    },
    {
      'title': 'Smart Calendar 🗓️',
      'description': 'Visualize your WEEKLY or DAILY schedule, check exams easily, and manage your time effectively.',
      'icon': Icons.calendar_month_rounded,
    },
    {
      'title': 'Interactive Diagram 🕸️',
      'description': 'View ALL the courses in your degree, track prerequisites, and plan future semesters visually.\n FIRST THING TO DO: USE THE AI AGENT TO HELP YOU FILL IT OUT!',
      'icon': Icons.account_tree_rounded,
    },
    {
      'title': 'AI Assistant chatbot 🤖',
      'description': 'Get personalized answers based on your data, and ask questions about your degree!',
      'icon': Icons.psychology_rounded,
    },
    {
      'title': 'GPA Calculator 📊',
      'description': 'Track your grades and simulate future scenarios to reach your academic goals.',
      'icon': Icons.calculate_rounded,
    },
    // map of campus with all your lectures locations:
    {
      'title': 'Campus Map 🗺️',
      'description': 'Find your way around campus, locate buildings, and plan your route to classes.',
      'icon': Icons.map_rounded,
    },
    // The best course recommendation agent in the world:
    {
      'title': 'Course Recommendations 🎓',
      'description': 'Get personalized course recommendations based on your academic history and goals.',
      'icon': Icons.recommend,
    },
    // and finally check your profile and settings
    {
      'title': 'Profile & Settings ⚙️',
      'description': 'Customize your experience, manage your profile, and adjust app settings to suit your needs.',
      'icon': Icons.person_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    // Save that the user has seen the tutorial
    final prefs = await SharedPreferences.getInstance();
    
    if (mounted) {
      final user = context.read<LogInNotifier>().user;
      final studentProvider = context.read<StudentProvider>();

      if (user != null) {
        // Save locally for quick access
        await prefs.setBool('has_seen_tutorial_${user.uid}', true);
        
        // Save to Firestore via StudentProvider
        await studentProvider.updateHasSeenTutorial(user.uid, true);
      }
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Dialog(
      backgroundColor: themeProvider.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 450),
        child: Column(
          children: [
            // Page Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          page['icon'],
                          size: 64,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        page['title'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? themeProvider.primaryColor
                        : themeProvider.textSecondary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      'Back',
                      style: TextStyle(color: themeProvider.textSecondary),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _completeTutorial,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: themeProvider.textSecondary),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _completeTutorial();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
