// lib/pages/degree_progress_page.dart
import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';
import '../services/course_service.dart';
import '../widgets/course_card.dart';

class DegreeProgressPage extends StatefulWidget {
  const DegreeProgressPage({super.key});

  @override
  State<DegreeProgressPage> createState() => _DegreeProgressPageState();
}

class _DegreeProgressPageState extends State<DegreeProgressPage> {
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
 create: (ctx) => CustomizedDiagramNotifier(),
 child: 
Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Consumer<StudentNotifier>(
        builder: (context, studentNotifier, _) {
          if (studentNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (studentNotifier.error.isNotEmpty) {
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

          final semesters = studentNotifier.sortedCoursesBySemester;

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

          // Detect device orientation
          final orientation = MediaQuery.of(context).orientation;

          return SafeArea(
            child: Column(
              
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with degree progress summary only in portrait mode.
                if (orientation == Orientation.portrait)
                  _buildProgressHeader(context, studentNotifier),

                Padding(padding: EdgeInsets.only(left: 25),child: Text("Press and hold down on a course to add notes to it",style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),),),
                // Semester list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      final semesterKey = semesters.keys.elementAt(index);
                      final semester = {
                        'semester': index + 1,
                        'name': semesterKey,
                        'courses': semesters[semesterKey]!,
                      };

                      return orientation == Orientation.portrait
                          ? _buildVerticalSemesterSection(
                            context,
                            semester,
                            studentNotifier,
                          )
                          : _buildHorizontalSemesterSection(
                            context,
                            semester,
                            studentNotifier,
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
        backgroundColor: AppColorsDarkMode.accentColor,
        foregroundColor: AppColorsDarkMode.secondaryColor,
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
                    Provider.of<StudentNotifier>(
                      context,
                      listen: false,
                    ).addSemester(semesterName, context);
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

  Widget _buildProgressHeader(
    BuildContext context,
    StudentNotifier studentNotifier,
  ) {
    final totalCourses =
        studentNotifier.coursesBySemester.values
            .expand((courses) => courses)
            .length;

    final totalCredits = studentNotifier.coursesBySemester.keys
        .map((semester) => studentNotifier.getTotalCreditsForSemester(semester))
        .fold<double>(0.0, (sum, credits) => sum + credits);

    final completedCourses =
        studentNotifier.coursesBySemester.values
            .expand((courses) => courses)
            .where((course) => course.finalGrade.isNotEmpty)
            .length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Degree Progress',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(onPressed: context.read<CustomizedDiagramNotifier>().switchPalette, icon: Icon(Icons.palette,color: AppColorsDarkMode.secondaryColor,)),

          if (studentNotifier.student != null) ...[
            const SizedBox(height: 8),
            Text(
              '${studentNotifier.student!.major} - ${studentNotifier.student!.faculty}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Progress summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Courses',
                  totalCourses.toString(),
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Credits',
                  totalCredits.toStringAsFixed(1),
                  Icons.star,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Completed',
                  completedCourses.toString(),
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
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

  // Vertical layout for portrait mode
  Widget _buildVerticalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentNotifier studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = studentNotifier.getTotalCreditsForSemester(
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
                      _confirmDeleteSemester(context, semesterName);
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final courseWithDetails = studentNotifier.getCourseWithDetails(
                  semesterName,
                  course.courseId,
                );
                return CourseCard(
                  direction: DirectionValues.vertical,
                  course: course,
                  courseDetails: courseWithDetails?.courseDetails,
                  semester: semesterName,
                );
              },
            ),
      ],
    );
  }

  // Horizontal layout for landscape mode
  Widget _buildHorizontalSemesterSection(
    BuildContext context,
    Map<String, dynamic> semester,
    StudentNotifier studentNotifier,
  ) {
    final courses = semester['courses'] as List<StudentCourse>;
    final semesterName = semester['name'] as String;
    final totalCredits = studentNotifier.getTotalCreditsForSemester(
      semesterName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      semesterName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${totalCredits.toStringAsFixed(1)} credits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    tooltip: 'Add Course',
                    onPressed: () {
                      _showAddCourseDialog(context, semesterName);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Semester',
                    onPressed: () {
                      _confirmDeleteSemester(context, semesterName);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal row of courses
        courses.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No courses in this semester',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
            : SizedBox(
              height: 120,
              child: Row(
                children: List.generate(courses.length, (index) {
                  final course = courses[index];
                  final courseWithDetails = studentNotifier
                      .getCourseWithDetails(semesterName, course.courseId);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child:  CourseCard(
                  direction: DirectionValues.horizontal,
                  course: course,
                  courseDetails: courseWithDetails?.courseDetails,
                  semester: semesterName,
                )
                    ),
                  );
                }),
              ),
            ),
        const SizedBox(height: 10),
        const Divider(),
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

              final fetched = await Provider.of<StudentNotifier>(
                context,
                listen: false,
              ).searchCourses(
                courseId: courseId,
                courseName: courseName,
                pastSemestersToInclude: 4,
              );

              if (!context.mounted) return; // <--- CRITICAL LINE

              if (fetched.isEmpty) {
                // ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text('No course found matching "$query"')),
                //     );
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
                                  );
                                  final success =
                                      await Provider.of<StudentNotifier>(
                                        context,
                                        listen: false,
                                      ).addCourseToSemester(
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

  void _confirmDeleteSemester(BuildContext context, String semesterName) {
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
                  await Provider.of<StudentNotifier>(
                    context,
                    listen: false,
                  ).deleteSemester(semesterName, context);
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
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
