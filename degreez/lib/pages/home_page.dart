// Updated home_page.dart 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_notifier.dart';
import '../providers/student_notifier.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LogInNotifier>(context, listen: false);
    final studentNotifier = Provider.of<StudentNotifier>(context);

    final student = studentNotifier.student;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DegreEZ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await loginNotifier.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: student == null
            ? const Text('Welcome!')
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome, ${student.name}!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Info',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Major: ${student.major}'),
                            Text('Faculty: ${student.faculty}'),
                            Text('Current Semester: ${student.semester}'),
                            Text('Catalog: ${student.catalog}'),
                            if (student.preferences.isNotEmpty)
                              Text('Preferences: ${student.preferences}'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/courses'),
                          icon: const Icon(Icons.school),
                          label: const Text('My Courses'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to schedule view
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Schedule view coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Course statistics
                    Consumer<StudentNotifier>(
                      builder: (context, notifier, _) {
                        final totalSemesters = notifier.coursesBySemester.length;
                        final totalCourses = notifier.coursesBySemester.values
                            .expand((courses) => courses)
                            .length;
                        
                        if (totalCourses == 0) {
                          return Card(
                            color: Colors.orange.shade50,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No courses enrolled yet. Tap "My Courses" to add your first course!',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '$totalSemesters',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text('Semesters'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '$totalCourses',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text('Courses'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      // Calculate total credits across all semesters
                                      notifier.coursesBySemester.keys
                                          .map((semester) => notifier.getTotalCreditsForSemester(semester))
                                          .fold<double>(0.0, (sum, credits) => sum + credits)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text('Credits'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}