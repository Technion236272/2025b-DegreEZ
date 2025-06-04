// pages/add_course_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final TextEditingController _searchController = TextEditingController();
  List<CourseSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Course'),
        centerTitle: true,
      ),
      body: Consumer<CourseDataProvider>(
        builder: (context, courseDataProvider, _) {
          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses by name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                              });
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.length >= 2) {
                      _performSearch(courseDataProvider, value);
                    } else {
                      setState(() {
                        _searchResults.clear();
                      });
                    }
                  },
                ),
              ),

              // Current semester info
              if (courseDataProvider.currentSemester != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Searching in: ${courseDataProvider.currentSemester!.semesterName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 8),

              // Search results
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for courses',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Enter at least 2 characters to start searching',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              result.course.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Course ID: ${result.course.courseNumber}'),
                Text('Faculty: ${result.course.faculty}'),
                Text('Credit Points: ${result.course.creditPoints}'),
                if (result.course.prerequisites.isNotEmpty)
                  Text(
                    'Prerequisites: ${result.course.prerequisites}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _onCourseSelected(result.course),
              child: const Text('Add'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _performSearch(CourseDataProvider courseDataProvider, String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      if (courseDataProvider.currentSemester == null) {
        await courseDataProvider.fetchCurrentSemester();
      }

      if (courseDataProvider.currentSemester != null) {
        final results = await CourseService.searchCourses(
          year: courseDataProvider.currentSemester!.year,
          semester: courseDataProvider.currentSemester!.semester,
          courseName: query.contains(RegExp(r'[a-zA-Z]')) ? query : null,
          courseId: query.contains(RegExp(r'[0-9]')) ? query : null,
        );

        if (mounted) {
          setState(() {
            _searchResults = results;
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onCourseSelected(EnhancedCourseDetails courseDetails) {
    _showAddCourseDialog(context, courseDetails);
  }

  void _showAddCourseDialog(BuildContext context, EnhancedCourseDetails courseDetails) {
    final semesterController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${courseDetails.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Course ID: ${courseDetails.courseNumber}'),
                    Text('Credit Points: ${courseDetails.creditPoints}'),
                    Text('Faculty: ${courseDetails.faculty}'),
                    if (courseDetails.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Prerequisites: ${courseDetails.prerequisites}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Input fields
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  hintText: 'e.g., Winter 2024',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add a personal note...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (semesterController.text.isNotEmpty) {
                _addCourseFromSearch(
                  context, 
                  semesterController.text, 
                  courseDetails,
                  noteController.text,
                );
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to calendar
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a semester'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Add Course'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCourseFromSearch(
    BuildContext context,
    String semester,
    EnhancedCourseDetails courseDetails,
    String note,
  ) async {
    final studentProvider = context.read<StudentProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (!studentProvider.hasStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if course already exists
    final existingCourses = courseProvider.getCoursesForSemester(semester);
    final courseExists = existingCourses.any((course) => course.courseId == courseDetails.courseNumber);
    
    if (courseExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course already exists in this semester'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final course = StudentCourse(
      courseId: courseDetails.courseNumber,
      name: courseDetails.name,
      finalGrade: '',
      lectureTime: '',
      tutorialTime: '',
      labTime: '',
      workshopTime: '',
      note: note.isNotEmpty ? note : null,
    );

    final success = await courseProvider.addCourseToSemester(
      studentProvider.student!.id,
      semester,
      course,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${courseDetails.name} added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add course'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
