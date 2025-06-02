// lib/widgets/course_calendar_panel.dart
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:provider/provider.dart';
import '../providers/student_notifier.dart';

class CourseCalendarPanel extends StatefulWidget {
  final EventController eventController;
  
  const CourseCalendarPanel({
    super.key, 
    required this.eventController,
  });

  @override
  State<CourseCalendarPanel> createState() => _CourseCalendarPanelState();
}

class _CourseCalendarPanelState extends State<CourseCalendarPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentNotifier>(
      builder: (context, studentNotifier, _) {
        final allCourses = studentNotifier.coursesBySemester.values
            .expand((courses) => courses)
            .toList();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Courses (${allCourses.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
              
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Column(
                  children: [
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allCourses.length,
                      itemBuilder: (context, index) {
                        final course = allCourses[index];
                        final courseDetails = studentNotifier.getCourseWithDetails(
                          studentNotifier.coursesBySemester.keys.first, 
                          course.courseId
                        )?.courseDetails;
                        
                        return ListTile(
                          leading: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getCourseColor(course.courseId),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(course.name),
                          subtitle: Text(course.courseId),
                          trailing: courseDetails != null 
                              ? Text('${courseDetails.points} credits')
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCourseColor(String courseId) {
    // Generate consistent color based on course ID
    final hash = courseId.hashCode;
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.red.shade700,
    ];
    return colors[hash.abs() % colors.length];
  }
}