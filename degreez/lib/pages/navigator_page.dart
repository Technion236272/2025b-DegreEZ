import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/pages/calendar_page.dart';
import 'package:degreez/pages/course_recommendation_page.dart';
import 'package:degreez/pages/credits_page.dart';
import 'package:degreez/pages/gpa_calculator_page.dart';
import 'package:degreez/pages/profile_page.dart';
import 'package:degreez/pages/chat_bot.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_course_dialog.dart';
import '../mixins/ai_import_mixin.dart';
import '../services/global_config_service.dart';
import 'package:degreez/pages/course_map_page.dart';
import 'customized_diagram_page.dart';
import 'prerequisite_chain_page.dart';


class NavigatorPage extends StatefulWidget {
  const NavigatorPage({super.key});

  @override
  State<NavigatorPage> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> with AiImportMixin {
  String _currentPage = 'Calendar';
  bool _hasInitializedData = false;
  String? _selectedCalendarSemester;

  // Semester selection state (moved from CalendarPage)
  List<String> _allSemesters = [];
  String? _selectedSemester;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitializedData) {
        _hasInitializedData = true;
        _loadStudentDataIfNeeded();
        _initializeSemesters(); // Add semester initialization
      }
    });
  }

  /// Initialize semester selection (moved from CalendarPage)
  Future<void> _initializeSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSemester = prefs.getString('lastSelectedSemester');

    final semesters = await GlobalConfigService.getAvailableSemesters();
    semesters.sort((a, b) {
      int getSortYear(String semesterName) {
        final parts = semesterName.split(' ');
        final yearPart = parts.length > 1 ? parts[1] : '';

        if (yearPart.contains('-')) {
          final years = yearPart.split('-');
          return int.tryParse(years.last) ?? 0; // Use later year
        }
        return int.tryParse(yearPart) ?? 0;
      }

      int getSeasonOrder(String semesterName) {
        final season = semesterName.split(' ').first;
        const order = {'Winter': 0, 'Spring': 1, 'Summer': 2};
        return order[season] ?? 99;
      }

      final yearA = getSortYear(a);
      final yearB = getSortYear(b);
      if (yearA != yearB) return yearA.compareTo(yearB);

      final seasonA = getSeasonOrder(a);
      final seasonB = getSeasonOrder(b);
      return seasonA.compareTo(seasonB);
    });

    final current = await GlobalConfigService.getCurrentSemester();

    final initialSemester =
        savedSemester != null && semesters.contains(savedSemester)
            ? savedSemester
            : current ?? (semesters.isNotEmpty ? semesters.last : null);

    if (initialSemester == null) return;

    setState(() {
      _allSemesters = semesters;
      _selectedSemester = initialSemester;
      _selectedCalendarSemester = initialSemester; // Keep both in sync
    });
  }

  /// Override from AiImportMixin to handle post-import actions
  @override
  void onImportCompleted() {
    // Refresh the providers after import
    final loginNotifier = context.read<LogInNotifier>();
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    // Refresh data by reloading from Firebase
    if (loginNotifier.user != null && studentProvider.hasStudent) {
      studentProvider.fetchStudentData(loginNotifier.user!.uid);
      courseProvider.loadStudentCourses(studentProvider.student!.id);
    }

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grade sheet imported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _loadStudentDataIfNeeded() {
    final loginNotifier = context.read<LogInNotifier>();
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    // Only proceed if user is logged in
    if (loginNotifier.user == null) return;

    // Load student data if not already loaded or loading
    if (!studentProvider.hasStudent && !studentProvider.isLoading) {
      studentProvider.fetchStudentData(loginNotifier.user!.uid).then((success) {
        if (success && mounted) {
          // Only load courses if not already loaded or loading
          if (!courseProvider.hasLoadedData &&
              !courseProvider.loadingState.isLoadingCourses) {
            courseProvider.loadStudentCourses(studentProvider.student!.id);
          }
        }
      });
    }
    // Handle case where student is loaded but courses aren't
    else if (studentProvider.hasStudent &&
        !courseProvider.hasLoadedData &&
        !courseProvider.loadingState.isLoadingCourses) {
      courseProvider.loadStudentCourses(studentProvider.student!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LogInNotifier, StudentProvider, CourseProvider>(
      builder: (context, loginNotifier, studentProvider, courseProvider, _) {
        Widget body;
        switch (_currentPage) {
          case 'Calendar':
            body = CalendarPage(
              selectedSemester: _selectedSemester, // Pass the selected semester
              onSemesterChanged: (semester) {
                setState(() {
                  _selectedCalendarSemester = semester;
                });
              },
            );
            break;

          case 'Profile':
            body = const ProfilePage();
            break;
          case 'Customized Diagram':
            body = const CustomizedDiagramPage();
            break;
          case 'GPA Calculator':
            body = const GpaCalculatorPage();
            break;
          case 'AI Assistant':
            body = const AiPage();
            break;
          case 'Map':
            body = CourseMapPage(
              key: ValueKey(_selectedSemester),
              selectedSemester: _selectedSemester ?? '',
            );
            break;
          case 'Course Recommendations':
            body = const CourseRecommendationPage();
            break;
          case 'Prerequisite Chains':
            body = const PrerequisiteChainPage();
            break;

          default:
            body = Text(_currentPage);
        }
        return Scaffold(
          appBar: AppBar(
            title:
                (_currentPage == 'Calendar' || _currentPage == 'Map')
                    ? _buildSemesterDropdown()
                    : AutoSizeText(
                      _currentPage,
                      minFontSize: 14,
                      maxFontSize: 22,
                    ),
            centerTitle: true,
            actions: _buildAppBarActions(),
          ),
          drawer: _buildSideDrawer(context, loginNotifier, studentProvider),
          body:
              studentProvider.isLoading ||
                      courseProvider.loadingState.isLoadingCourses
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your data...'),
                      ],
                    ),
                  )
                  : body,
          // Updated FAB - now navigates to AddCoursePage
          floatingActionButton:
              _currentPage == 'Calendar'
                  ? FloatingActionButton(
                    onPressed: () {
                      if (_selectedCalendarSemester != null) {
                        AddCourseDialog.show(
                          context,
                          _selectedCalendarSemester!,
                          onCourseAdded: (courseId) {
                            // Optional: trigger calendar refresh if needed
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No semester selected')),
                        );
                      }
                    },
                    tooltip: 'Add Course',
                    child: const Icon(Icons.add),
                  )
                  : null,
        );
      },
    );
  }

  /// Builds context-sensitive AppBar actions based on the current page
  List<Widget> _buildAppBarActions() {
    switch (_currentPage) {
      case 'Customized Diagram':
        return [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: showAiImportDialog, // Use the mixin method
            tooltip: 'Import Grade Sheet with AI',
          ),
        ];

      case 'Calendar':
        // For Course Recommendations page, maybe no additional AI button needed
        return [
          IconButton(
            icon: const Icon(Icons.bolt_sharp),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Assistant coming soon!')),
              );
            },
            tooltip: 'AI Assistant',
          ),
        ];

      default:
        // For other pages, show a generic AI assistant button
        return [];
    }
  }

  Widget _buildSideDrawer(
    BuildContext context,
    LogInNotifier loginNotifier,
    StudentProvider studentProvider,
  ) {
    final user = loginNotifier.user;
    final student = studentProvider.student;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Drawer(
      elevation: 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLightMode
                ? [
                    const Color(0xFFFAFAFA),
                    const Color(0xFFF5F5F5),
                    const Color(0xFFEFEFEF),
                  ]
                : [
                    const Color(0xFF17191B),
                    const Color(0xFF1F2123),
                    const Color(0xFF242628),
                  ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced User Header with beautiful gradient and shadows
            Container(
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 220,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLightMode
                      ? [
                          const Color(0xFF4CAF50),
                          const Color(0xFF66BB6A),
                          const Color(0xFF81C784),
                        ]
                      : [
                          const Color(0xFF1F3D56),
                          const Color(0xFF306780),
                          const Color(0xFF4A7A9A),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(
                                  user?.displayName?.substring(0, 1) ?? 'U',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isLightMode
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF1F3D56),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Profile Picture with enhanced styling
                      const SizedBox(height: 12),
                      // User Name - with proper text overflow handling
                      
                      AutoSizeText(
                          student?.name ?? user?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          minFontSize: 10,
                          maxFontSize: 25,
                        ),
                      const SizedBox(height: 4),
                      // Email - with proper text overflow handling
                      AutoSizeText(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          minFontSize: 10,
                          maxFontSize: 25,
                        ),
                      
                      // const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Items with enhanced styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  _buildDrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Calendar',
                    isSelected: _currentPage == 'Calendar',
                    onTap: () => _changePage('Calendar'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Customized Diagram',
                    isSelected: _currentPage == 'Customized Diagram',
                    onTap: () => _changePage('Customized Diagram'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.calculate,
                    title: 'GPA Calculator',
                    isSelected: _currentPage == 'GPA Calculator',
                    onTap: () => _changePage('GPA Calculator'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.smart_toy,
                    title: 'AI Assistant',
                    isSelected: _currentPage == 'AI Assistant',
                    onTap: () => _changePage('AI Assistant'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.map,
                    title: 'Map',
                    isSelected: _currentPage == 'Map',
                    onTap: () => _changePage('Map'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.auto_awesome,
                    title: 'Course Recommendations',
                    isSelected: _currentPage == 'Course Recommendations',
                    onTap: () => _changePage('Course Recommendations'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_tree_outlined,
                    title: 'Prerequisite Chains',
                    isSelected: _currentPage == 'Prerequisite Chains',
                    onTap: () => _changePage('Prerequisite Chains'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    isSelected: _currentPage == 'Profile',
                    onTap: () => _changePage('Profile'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Elegant Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.withAlpha(76)
                          : Colors.white.withAlpha(26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bottom Section with subtle background
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: isLightMode
                    ? Colors.grey.withAlpha(13)
                    : Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDrawerItem(
                    isSelected: _currentPage == 'Credits',
                    icon: Icons.info_outline_rounded,
                    title: 'Credits',
                    onTap: () {
                      showCreditsPage(context);
                    },
                  ),
                  _buildDrawerItem(
                    isSelected: _currentPage == 'Log Out',
                    icon: Icons.logout,
                    title: 'Log Out',
                    isLogout: true,
                    onTap: () async {
                      studentProvider.clear();
                      context.read<CourseProvider>().clear();
                      context.read<SignUpProvider>().resetSelected();
                      await loginNotifier.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 100),

            // // Add Course - New menu item for easier access
            // ListTile(
            //   leading: const Icon(Icons.add_circle_outline),
            //   title: const Text('Add Course'),
            //   onTap: () {
            //     Navigator.pop(context); // Close drawer
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const AddCoursePage(),
            //       ),
            //     );
            //   },
            // ),

            // const Divider(),

            // Sign out
            // ListTile(
            //   leading: const Icon(Icons.logout, color: Colors.red),
            //   title: const Text('Sign Out'),
            //   onTap: () {
            //     // Clear providers before signing out
            //     context.read<StudentProvider>().clear();
            //     context.read<CourseProvider>().clear();
            //     loginNotifier.signOut();
            //     Navigator.pop(context);
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isLightMode
                    ? [
                        const Color(0xFF4CAF50).withAlpha(26),
                        const Color(0xFF66BB6A).withAlpha(20),
                      ]
                    : [
                        const Color(0xFF1F3D56).withAlpha(76),
                        const Color(0xFF306780).withAlpha(51),
                      ],
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: isLightMode
                      ? const Color(0xFF4CAF50).withAlpha(51)
                      : const Color(0xFF1F3D56).withAlpha(76),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: isLightMode
              ? const Color(0xFF4CAF50).withAlpha(26)
              : const Color(0xFF1F3D56).withAlpha(51),
          highlightColor: isLightMode
              ? const Color(0xFF4CAF50).withAlpha(13)
              : const Color(0xFF1F3D56).withAlpha(26),
          onTap: () {
            Navigator.pop(context); // Close drawer
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isLightMode
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF1F3D56))
                        : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isLogout
                        ? const Color(0xFFE53E3E)
                        : (isSelected
                            ? Colors.white
                            : (isLightMode
                                ? const Color(0xFF4A5568)
                                : const Color(0xFFB8C7D6))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isLogout
                          ? const Color(0xFFE53E3E)
                          : (isSelected
                              ? (isLightMode
                                  ? const Color(0xFF2D3748)
                                  : const Color(0xFFB8C7D6))
                              : (isLightMode
                                  ? const Color(0xFF4A5568)
                                  : const Color(0xFF9CA3AF))),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isLightMode
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF1F3D56),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changePage(String page) {
    setState(() {
      _currentPage = page;
    });
  }

  /// Builds the semester dropdown for the AppBar when on Calendar page
  Widget _buildSemesterDropdown() {
    if (_allSemesters.isEmpty) {
      return const AutoSizeText('Calendar', minFontSize: 14, maxFontSize: 22);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final textColor =
            themeProvider.isLightMode
                ? AppColorsLightMode.textPrimary
                : AppColorsDarkMode.secondaryColor;
        
        final dropdownBgColor = themeProvider.isLightMode
            ? Colors.white
            : const Color(0xFF2C2C2C);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeProvider.isLightMode 
                ? Colors.grey.withAlpha(25) 
                : Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeProvider.isLightMode 
                  ? Colors.grey.withAlpha(50) 
                  : Colors.white.withAlpha(50),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSemester,
              hint: Text(
                "Select Semester",
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textColor,
                size: 20,
              ),
              dropdownColor: dropdownBgColor,
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              onChanged: (String? value) async {
                if (value != null && value != _selectedSemester) {
                  setState(() {
                    _selectedSemester = value;
                    _selectedCalendarSemester = value;
                  });

                  // Save preference
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('lastSelectedSemester', value);

                  // The CalendarPage will handle the course loading when it receives the new semester
                }
              },
              items:
                  _allSemesters.map((sem) {
                    return DropdownMenuItem<String>(
                      value: sem,
                      child: Text(
                        sem,
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}
