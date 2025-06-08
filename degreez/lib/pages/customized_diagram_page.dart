// lib/pages/degree_progress_page.dart
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/services/course_service.dart';
import 'package:degreez/widgets/semester_timeline.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/course_card.dart';

class CustomizedDiagramPage extends StatefulWidget {
  const CustomizedDiagramPage({super.key});

  @override
  State<CustomizedDiagramPage> createState() => _CustomizedDiagramPageState();
}

class _CustomizedDiagramPageState extends State<CustomizedDiagramPage> {
  late ScrollController _scrollController;
  final List<GlobalKey> _semesterKeys = [];
  int _currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get responsive grid count
  int _getCrossAxisCount(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 6;
    if (screenWidth > 800) return 5;
    if (screenWidth > 600) return 4;
    return 3;
  }

  // Helper method to scroll to specific semester
  void _scrollToSemester(int index) {
    if (index < _semesterKeys.length && _semesterKeys[index].currentContext != null) {
      final context = _semesterKeys[index].currentContext!;
      final renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      
      _scrollController.animateTo(
        _scrollController.offset + position.dy - 150, // Account for timeline height
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      setState(() {
        _currentSemesterIndex = index;
      });
    }
  }

  // Helper method to build timeline data
  List<SemesterTimelineData> _buildTimelineData(Map<String, List<StudentCourse>> semesters) {
    return semesters.entries.map((entry) {
      final courses = entry.value;
      final completedCourses = courses.where((c) => c.finalGrade.isNotEmpty).length;
      
      SemesterStatus status;
      if (courses.isEmpty) {
        status = SemesterStatus.empty;
      } else if (completedCourses == courses.length) {
        status = SemesterStatus.completed;
      } else if (completedCourses > 0) {
        status = SemesterStatus.current;
      } else {
        status = SemesterStatus.planned;
      }

      return SemesterTimelineData(
        name: entry.key,
        status: status,
        completedCourses: completedCourses,
        totalCourses: courses.length,
        totalCredits: 0.0, // TODO: Calculate based on course details
      );
    }).toList();
  }

  // Enhanced: Callback to refresh UI when course is updated
  void _onCourseUpdated() {
    setState(() {
      // This will trigger a rebuild and refresh the course data
    });
  }
  
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
 create: (ctx) => CustomizedDiagramNotifier(),
 child: 
Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Consumer2<StudentProvider, CourseProvider>(
  builder: (context, studentNotifier, courseNotifier, _){
          final courseNotifier = context.read<CourseProvider>();
          if (studentNotifier.isLoading && studentNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentNotifier.error != '' && studentNotifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${studentNotifier.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final semesters = courseNotifier.sortedCoursesBySemester;

          if (semesters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: AppColorsDarkMode.secondaryColorDim),
                  SizedBox(height: 16),
                  Text(
                    'No courses to display',
                    style: TextStyle(fontSize: 18, color: AppColorsDarkMode.secondaryColorDim),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add courses to see your degree progress',
                    style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                  ),
                ],
              ),
            );
          }

          // Ensure we have enough keys for the semesters
          while (_semesterKeys.length < semesters.length) {
            _semesterKeys.add(GlobalKey());
          }

          // Detect device orientation
          final orientation = MediaQuery.of(context).orientation;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add the semester timeline
                SemesterTimeline(
                  semesters: _buildTimelineData(semesters),
                  currentSemesterIndex: _currentSemesterIndex,
                  onSemesterTap: _scrollToSemester,
                ),

                // Enhanced: Updated instruction text
                Padding(
                  padding: EdgeInsets.only(left: 25, top: 10, bottom: 5),
                  child: Text(
                    "Tap a course for quick actions • Long press to add notes",
                    style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                  ),
                ),

                // Semester list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final semesterKey = semesters.keys.elementAt(index);
                      final semester = {
                        'semester': index + 1,
                        'name': semesterKey,
                        'courses': semesters[semesterKey]!,
                      };

                      return Container(
                        key: _semesterKeys[index],
                        child: orientation == Orientation.portrait
                            ? _buildVerticalSemesterSection(
                              context,
                              semester,
                              studentNotifier,
                            )
                            : _buildVerticalSemesterSection(
                              context,
                              semester,
                              studentNotifier,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSemesterDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    ),);
  }

  void _showAddSemesterDialog(BuildContext context) {
    // Auto-select season based on the current month
    final month = DateTime.now().month;
    String selectedSeason;
    if (month <= 2) {
      selectedSeason = 'Winter';
    } else if (month <= 6) {
      selectedSeason = 'Spring';
    } else {
      selectedSeason = 'Summer';
    }

    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Semester'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Season dropdown
                  DropdownButtonFormField<String>(
                    value: selectedSeason,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items:
                        ['Winter', 'Spring', 'Summer'].map((season) {
                          return DropdownMenuItem<String>(
                            value: season,
                            child: Text(season),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSeason = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Year dropdown: from 5 years ago to 5 years ahead
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: List.generate(11, (index) {
                      int year = DateTime.now().year - 5 + index;
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final semesterName = '$selectedSeason $selectedYear';
                    context.read<CourseProvider>().addSemester(context.read<StudentProvider>().student!.id, semesterName);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Vertical layout for portrait mode - enhanced with responsive grid and update callback
  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentProvider studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = context.read<CourseProvider>().getTotalCreditsForSemester(
      semesterName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColorsDarkMode.accentColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    semesterName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.secondaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${totalCredits.toStringAsFixed(1)} credits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColorsDarkMode.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    tooltip: 'Add Course',
                    onPressed: () {
                      _showAddCourseDialog(context, semesterName);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                    tooltip: 'Delete Semester',
                    onPressed: () {
                      _confirmDeleteSemester(context, semesterName,studentNotifier.student!.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Display message if no courses
        courses.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No courses in this semester',
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColorDim,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
            : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context), // Enhanced: responsive grid
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final courseWithDetails = context.read<CourseProvider>().getCourseWithDetails(
                  semesterName,
                  course.courseId,
                );
                return CourseCard(
                  direction: DirectionValues.vertical,
                  course: course,
                  courseDetails: courseWithDetails?.courseDetails,
                  semester: semesterName,
                  onCourseUpdated: _onCourseUpdated, // Enhanced: Add update callback
                );
              },
            ),
      ],
    );
  }

  void _showAddCourseDialog(BuildContext context, String semesterName) {
    final searchController = TextEditingController();
    List<CourseSearchResult> results = [];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> search(String query) async {
              if (query.trim().isEmpty) return;
              setState(() => isLoading = true);

              final isId = RegExp(r'^\d+$').hasMatch(query);
              final courseId = isId ? query : null;
              final courseName = isId ? null : query;
              print('SEARCH: id=$courseId, name=$courseName');

              final fetched = await context.read<CourseProvider>().searchCourses(
                courseId: courseId,
                courseName: courseName,
                pastSemestersToInclude: 4,
              );

              if (!context.mounted) return; // <--- CRITICAL LINE

              if (fetched.isEmpty) {
                setState(() {
                  results = [];
                  isLoading = false;
                });
                return;
              }

              setState(() {
                results = fetched;
                isLoading = false;
              });
            }

            return AlertDialog(
              title: Text('Add Course to $semesterName'),
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4, // or 0.6
                width: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Course ID or Name',
                        hintText: 'e.g. 02340114 or פיסיקה 2',
                      ),
                      onChanged: (value) {
                        if (value.length > 3) search(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (results.isEmpty &&
                        searchController.text.isNotEmpty)
                      const Text('No courses found.'),
                    if (results.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final courseResult = results[index];
                            final c = courseResult.course;

                            if (c == null ||
                                c.courseNumber == null ||
                                c.name == null) {
                              return const ListTile(
                                title: Text('Invalid course data'),
                                subtitle: Text('Missing course information'),
                              );
                            }
                            return ListTile(
                              title: Text('${c.courseNumber} - ${c.name}'),
                              subtitle: Text(
                                '${c.points} points • ${c.faculty}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final course = StudentCourse(
                                    courseId: c.courseNumber,
                                    name: c.name,
                                    finalGrade: '',
                                    lectureTime: '',
                                    tutorialTime: '',
                                    labTime: '',
                                    workshopTime: '',
                                  );
                                  final success =
                                      await Provider.of<CourseProvider>(
                                        context,
                                        listen: false,
                                      ).addCourseToSemester(
                                        context.read<StudentProvider>().student!.id,
                                        semesterName,
                                        course,
                                      );

                                  if (!context.mounted) return;

                                  if (success) {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Course added to $semesterName',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    // Enhanced: Trigger UI refresh
                                    _onCourseUpdated();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to add course'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSemester(BuildContext context, String semesterName,String studentId) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
      side: BorderSide(color:  AppColorsDarkMode.secondaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
            backgroundColor: AppColorsDarkMode.accentColor,
            title: const Text('Delete Semester',style: TextStyle(color: AppColorsDarkMode.secondaryColor),),
            content: Text(
              'Are you sure you want to delete "$semesterName"? This will remove all courses in it.',style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel',
                  style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),),
              ),
              TextButton(
                onPressed: () async {
                  await Provider.of<CourseProvider>(
                    context,
                    listen: false,
                  ).deleteSemester(studentId,semesterName);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  // Enhanced: Trigger UI refresh
                  _onCourseUpdated();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColorsDarkMode.secondaryColor,fontWeight:FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }
}
