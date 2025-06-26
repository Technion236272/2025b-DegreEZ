import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/pages/calendar_page.dart';
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
import '../services/GlobalConfigService.dart';
import 'package:degreez/pages/course_map_page.dart';
import 'customized_diagram_page.dart';

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

      case 'AI Assistant':
        // For AI Assistant page, maybe no additional AI button needed
        return [];

      default:
        // For other pages, show a generic AI assistant button
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
    }
  }

  Widget _buildSideDrawer(
    BuildContext context,
    LogInNotifier loginNotifier,
    StudentProvider studentProvider,
  ) {
    final user = loginNotifier.user;
    final student = studentProvider.student;

    return Drawer(
      child: Container(
        color: Theme.of(context).brightness == Brightness.light 
            ? AppColorsLightMode.drawerColor 
            : Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced User Header
            UserAccountsDrawerHeader(
              accountName: Text(
                student?.name ?? user?.displayName ?? 'User',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light 
                      ? AppColorsLightMode.textPrimary 
                      : AppColorsDarkMode.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light 
                      ? AppColorsLightMode.textSecondary 
                      : AppColorsDarkMode.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light 
                        ? AppColorsLightMode.primaryColor 
                        : AppColorsDarkMode.accentColor, // Border color
                    width: 3.0, // Border width
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage:
                      user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                  child:
                      user?.photoURL == null
                          ? Text(user?.displayName?.substring(0, 1) ?? 'U')
                          : null,
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light 
                    ? AppColorsLightMode.drawerHeaderColor 
                    : AppColorsDarkMode.secondaryColor,
              ),
            ),

            // Navigation Items
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: 'Calendar',
              isSelected: _currentPage == 'Calendar',
              onTap: () => _changePage('Calendar'),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              isSelected: _currentPage == 'Profile',
              onTap: () => _changePage('Profile'),
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

            const Divider(),
            _buildDrawerItem(
              isSelected: _currentPage == 'Log Out',
              icon: Icons.logout,
              title: 'Log Out',
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
            _buildDrawerItem(
              isSelected: _currentPage == 'Credits',
              icon: Icons.info_outline_rounded,
              title: 'Credits',
              onTap: () {
                showCreditsPage(context);
              },
            ),

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
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? (Theme.of(context).brightness == Brightness.light 
                ? AppColorsLightMode.primaryColor 
                : null) 
            : (Theme.of(context).brightness == Brightness.light 
                ? AppColorsLightMode.textSecondary 
                : AppColorsDarkMode.secondaryColorDim),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? (Theme.of(context).brightness == Brightness.light 
                  ? AppColorsLightMode.primaryColor 
                  : null) 
              : (Theme.of(context).brightness == Brightness.light 
                  ? AppColorsLightMode.textSecondary 
                  : AppColorsDarkMode.secondaryColorDim),
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withAlpha(25),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
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
        final textColor = themeProvider.isLightMode 
            ? AppColorsLightMode.textPrimary 
            : AppColorsDarkMode.secondaryColor;
        
        return DropdownButton<String>(
          value: _selectedSemester,
          hint: Text(
            "Select Semester", 
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          underline: Container(), // Remove the default underline
          dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
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
          items: _allSemesters.map((sem) {
            return DropdownMenuItem<String>(
              value: sem,
              child: Text(
                sem,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
