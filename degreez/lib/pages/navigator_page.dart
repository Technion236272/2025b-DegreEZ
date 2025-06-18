import 'package:auto_size_text/auto_size_text.dart';
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/pages/calendar_page.dart';
import 'package:degreez/pages/credits_page.dart';
import 'package:degreez/pages/gpa_calculator_page.dart';
import 'package:degreez/pages/profile_page.dart';
import 'package:degreez/pages/chat_bot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../widgets/add_course_dialog.dart';

import 'customized_diagram_page.dart';


class NavigatorPage extends StatefulWidget {
  const NavigatorPage({super.key});

  @override
  State<NavigatorPage> createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> {
   String _currentPage = 'Calendar';
  bool _hasInitializedData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitializedData) {
        _hasInitializedData = true;
        _loadStudentDataIfNeeded();
      }
    });
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
          if (!courseProvider.hasLoadedData && !courseProvider.loadingState.isLoadingCourses) {
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

        Widget body;        switch (_currentPage) {
          case 'Calendar':
            body = const CalendarPage();
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
          default:
            body = Text(_currentPage);
        }        return Scaffold(
          appBar: AppBar(
            title: AutoSizeText(_currentPage,minFontSize: 14,maxFontSize: 22,),
            centerTitle: true,
          ),
          drawer: _buildSideDrawer(context, loginNotifier, studentProvider),
          body: studentProvider.isLoading || courseProvider.loadingState.isLoadingCourses
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
          floatingActionButton: _currentPage == 'Calendar'
    ? Consumer<CourseDataProvider>(
        builder: (context, courseDataProvider, _) {
          return FloatingActionButton(
            onPressed: () {
              final currentSemester = courseDataProvider.currentSemester;
              if (currentSemester != null) {
                AddCourseDialog.show(
                  context, 
                  currentSemester.semesterName,
                  onCourseAdded: (courseId) {
                    // Optional: Notify calendar to refresh or mark as manually added
                  },
                );
              }
            },
            tooltip: 'Add Course',
            child: const Icon(Icons.add),
          );
        },
      )
    : null,
        );
      },
    );
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
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced User Header
            UserAccountsDrawerHeader(
              accountName: Text(student?.name ?? user?.displayName ?? 'User',style: TextStyle(color: AppColorsDarkMode.accentColor,fontWeight:FontWeight.w700),),
              accountEmail: Text(user?.email ?? '',style: TextStyle(color: AppColorsDarkMode.accentColor,fontWeight:FontWeight.w700),),
              currentAccountPicture: Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColorsDarkMode.accentColor, // Border color
      width: 3.0,         // Border width
    ),
  ),
  child: CircleAvatar(
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(user?.displayName?.substring(0, 1) ?? 'U')
                    : null,
              ),),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.secondaryColor,
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
            ),            _buildDrawerItem(
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
            
            const Divider(),
            _buildDrawerItem(
              isSelected: _currentPage == 'Log Out',
              icon: Icons.logout,
              title: 'Log Out',
              onTap: () async {
                studentProvider.clear();
                context.read<CourseProvider>().clear();
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
},            ),
            
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
        color: isSelected ? null : AppColorsDarkMode.secondaryColorDim,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? null : AppColorsDarkMode.secondaryColorDim,
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
}
