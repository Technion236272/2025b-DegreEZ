// lib/widgets/course_events_manager.dart - Updated for new providers
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';
import '../providers/course_data_provider.dart';
import '../models/student_model.dart';
import 'course_events_widget.dart';

class CourseEventsManager extends StatefulWidget {
  final EventController eventController;
  final DateTime? currentWeek;

  const CourseEventsManager({
    super.key,
    required this.eventController,
    this.currentWeek,
  });

  @override
  State<CourseEventsManager> createState() => _CourseEventsManagerState();
}

class _CourseEventsManagerState extends State<CourseEventsManager> {
  final Map<String, Map<String, CourseEventData?>> _allSelections = {};
  
  @override
  Widget build(BuildContext context) {
    return Consumer3<StudentProvider, CourseProvider, CourseDataProvider>(
      builder: (context, studentProvider, courseProvider, courseDataProvider, _) {
        final coursesBySemester = courseProvider.coursesBySemester;
        
        if (coursesBySemester.isEmpty) {
          return const Center(
            child: Text('No courses available'),
          );
        }

        return Column(
          children: [
            // Course selection summary
            _buildSelectionSummary(),
            
            const SizedBox(height: 16),
            
            // Individual course widgets
            Expanded(
              child: ListView.builder(
                itemCount: _getTotalCourses(coursesBySemester),
                itemBuilder: (context, index) {
                  final courseInfo = _getCourseAtIndex(coursesBySemester, index);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: FutureBuilder<EnhancedCourseDetails?>(
                      future: courseDataProvider.getCourseDetails(courseInfo['courseId']!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text(courseInfo['courseName']!),
                            subtitle: const Text('Loading course details...'),
                            leading: const CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return ListTile(
                            title: Text(courseInfo['courseName']!),
                            subtitle: const Text('Failed to load course details'),
                            leading: const Icon(Icons.error, color: Colors.red),
                          );
                        }

                        final courseDetails = snapshot.data!;
                        
                        return ExpansionTile(
                          title: Text(courseDetails.name),
                          subtitle: Text('ID: ${courseDetails.courseNumber}'),
                          children: [
                            CourseEventsWidget(
                              courseDetails: courseDetails,
                              eventController: widget.eventController,
                              weekStartDate: widget.currentWeek,
                              onSelectionChanged: (courseId, lecture, tutorial, lab, workshop) {
                                _updateCourseSelection(courseId, lecture, tutorial, lab, workshop);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionSummary() {
    if (_allSelections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Select lecture and tutorial times for your courses',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Course Times',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._allSelections.entries.map((entry) {
            final courseId = entry.key;
            final selections = entry.value;
            final lecture = selections['lecture'];
            final tutorial = selections['tutorial'];
            final lab = selections['lab'];
            final workshop = selections['workshop'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (lecture != null)
                    Text('  Lecture: ${lecture.scheduleEntry.day} ${lecture.scheduleEntry.time}'),
                  if (tutorial != null)
                    Text('  Tutorial: ${tutorial.scheduleEntry.day} ${tutorial.scheduleEntry.time}'),
                  if (lecture == null && tutorial == null)
                    const Text('  No times selected', style: TextStyle(color: Colors.grey)),
                
                  if (lab != null )
                    Text('  Lab: ${lab.scheduleEntry.day} ${lab.scheduleEntry.time}'),
                  if (workshop != null)
                    Text('  Workshop: ${workshop.scheduleEntry.day} ${workshop.scheduleEntry.time}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  int _getTotalCourses(Map<String, List<StudentCourse>> coursesBySemester) {
    return coursesBySemester.values.fold(0, (sum, courses) => sum + courses.length);
  }

  Map<String, String> _getCourseAtIndex(
    Map<String, List<StudentCourse>> coursesBySemester, 
    int index,
  ) {
    int currentIndex = 0;
    
    for (final entry in coursesBySemester.entries) {
      final semester = entry.key;
      final courses = entry.value;
      
      for (final course in courses) {
        if (currentIndex == index) {
          return {
            'semester': semester,
            'courseId': course.courseId,
            'courseName': course.name,
          };
        }
        currentIndex++;
      }
    }
    
    // Fallback - should never reach here
    return {
      'semester': '',
      'courseId': '',
      'courseName': '',
    };
  }

  void _updateCourseSelection(
    String courseId, 
    CourseEventData? lecture, 
    CourseEventData? tutorial,
    CourseEventData? lab,
    CourseEventData? workshop,
  ) {
    setState(() {
      _allSelections[courseId] = {
        'lecture': lecture,
        'tutorial': tutorial,
        'lab': lab,
        'workshop': workshop,
      };
    });
  }
  /* ISN'T REFERENCED IN THE CODE AT ALL
  void _clearAllSelections() {
    setState(() {
      _allSelections.clear();
    });
    
    // Remove all events from calendar
    widget.eventController.removeWhere((event) => true);
  }
  */
  /* ISN'T REFERENCED IN THE CODE AT ALL 
  void _generateScheduleForWeek() {
    // This method could be used to generate a complete weekly schedule
    // based on all selected course times
    _clearAllSelections();
    
    // Implementation would go here to create calendar events
    // for the selected lecture and tutorial times
  }
  */
}
