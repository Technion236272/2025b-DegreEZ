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
        title: const Text('Home'),
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
            ? const Text('Loading Profile ...')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome, ${student.name}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Major: ${student.major}'),
                  Text('Faculty: ${student.faculty}'),
                  Text('Semester: ${student.semester}'),
                  Text('Catalog: ${student.catalog}'),
                  if (student.preferences.isNotEmpty)
                    Text('Preferences: ${student.preferences}'),
                ],
              ),
      ),
    );
  }
}