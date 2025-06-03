
import 'package:degreez/providers/course_provider.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:degreez/widgets/profile/profile_info_row.dart';
import 'package:degreez/widgets/profile/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
    // Placeholder method for edit profile
    void _showEditProfileDialog(BuildContext context, StudentProvider notifier) {
    final student = notifier.student!;
    final nameController = TextEditingController(text: student.name);
    final majorController = TextEditingController(text: student.major);
    final preferencesController = TextEditingController(
      text: student.preferences,
    );
    final catalogController = TextEditingController(text: student.catalog);
    final facultyController = TextEditingController(text: student.faculty);
    final semesterController = TextEditingController(
      text: student.semester.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: majorController,
                decoration: const InputDecoration(labelText: 'Major'),
              ),
              TextField(
                controller: facultyController,
                decoration: const InputDecoration(labelText: 'Faculty'),
              ),
              TextField(
                controller: semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: catalogController,
                decoration: const InputDecoration(labelText: 'Catalog'),
              ),
              TextField(
                controller: preferencesController,
                decoration: const InputDecoration(labelText: 'Preferences'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {


                notifier.updateStudentProfile(
                  name: nameController.text,
                  major: majorController.text,
                  preferences: preferencesController.text,
                  faculty: facultyController.text,
                  catalog: catalogController.text,
                  semester: student.semester,
                );
                Navigator.of(context).pop();
              },

              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final studentNotifier = context.read<StudentProvider>();
    final courseNotifier = context.read<CourseProvider>();

    final student = studentNotifier.student;
    if (student == null) {
      return const Center(child: Text('No student profile found'));
    }

    final totalCredits = courseNotifier.coursesBySemester.keys
        .map((semester) => courseNotifier.getTotalCreditsForSemester(semester))
        .fold<double>(0.0, (sum, credits) => sum + credits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed:
                            () => _showEditProfileDialog(
                              context,
                              studentNotifier,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ProfileInfoRow(label: 'Name', value: student.name),
                  ProfileInfoRow(label: 'Major', value: student.major),
                  ProfileInfoRow(label: 'Faculty', value: student.faculty),
                  ProfileInfoRow(
                    label: 'Current Semester',
                    value: student.semester.toString(),
                  ),
                  ProfileInfoRow(label: 'Catalog', value: student.catalog),
                  if (student.preferences.isNotEmpty)
                    ProfileInfoRow(
                      label: 'Preferences',
                      value: student.preferences,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Course Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatCard(
                icon: Icons.calendar_today,
                label: 'Semesters',
                value: courseNotifier.coursesBySemester.length.toString(),
              ),
              StatCard(
                icon: Icons.school,
                label: 'Courses',
                value:
                    courseNotifier.coursesBySemester.values
                        .expand((courses) => courses)
                        .length
                        .toString(),
              ),
              StatCard(
                icon: Icons.star,
                label: 'Credits',
                value: totalCredits.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}