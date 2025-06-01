// lib/widgets/schedule_selection_dialog.dart

import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';
import '../mixins/course_event_mixin.dart';

class ScheduleSelectionDialog extends StatefulWidget {
  final StudentCourse course;
  final EnhancedCourseDetails courseDetails;
  final Function(String? lectureTime, String? tutorialTime) onSelectionChanged;

  const ScheduleSelectionDialog({
    Key? key,
    required this.course,
    required this.courseDetails,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<ScheduleSelectionDialog> createState() => _ScheduleSelectionDialogState();
}

class _ScheduleSelectionDialogState extends State<ScheduleSelectionDialog> 
    with CourseEventMixin {
  String? selectedLectureTime;
  String? selectedTutorialTime;
  
  // Group schedule entries by type
  List<ScheduleEntry> lectures = [];
  List<ScheduleEntry> tutorials = [];
  List<ScheduleEntry> labs = [];

  @override
  void initState() {
    super.initState();
    selectedLectureTime = widget.course.lectureTime.isNotEmpty ? widget.course.lectureTime : null;
    selectedTutorialTime = widget.course.tutorialTime.isNotEmpty ? widget.course.tutorialTime : null;
    
    // Group schedule entries by type
    for (final schedule in widget.courseDetails.schedule) {
      final type = parseCourseEventType(schedule.type);
      switch (type) {
        case CourseEventType.lecture:
          lectures.add(schedule);
          break;
        case CourseEventType.tutorial:
          tutorials.add(schedule);
          break;
        case CourseEventType.lab:
          labs.add(schedule);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Schedule',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${widget.course.name} (${widget.course.courseId})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lectures Section
                    if (lectures.isNotEmpty) ...[
                      _buildSectionHeader('Lectures', Icons.school, lectures.length),
                      ...lectures.map((lecture) => _buildScheduleOption(
                        lecture,
                        CourseEventType.lecture,
                        _isLectureSelected(lecture),
                        (selected) {
                          setState(() {
                            selectedLectureTime = selected 
                                ? StudentCourse.formatScheduleString(lecture.day, lecture.time)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    
                    // Tutorials Section
                    if (tutorials.isNotEmpty) ...[
                      _buildSectionHeader('Tutorials', Icons.groups, tutorials.length),
                      ...tutorials.map((tutorial) => _buildScheduleOption(
                        tutorial,
                        CourseEventType.tutorial,
                        _isTutorialSelected(tutorial),
                        (selected) {
                          setState(() {
                            selectedTutorialTime = selected 
                                ? StudentCourse.formatScheduleString(tutorial.day, tutorial.time)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    
                    // Labs Section (for future use)
                    if (labs.isNotEmpty) ...[
                      _buildSectionHeader('Labs', Icons.science, labs.length),
                      ...labs.map((lab) => _buildScheduleOption(
                        lab,
                        CourseEventType.lab,
                        false, // Labs not implemented yet
                        (selected) {
                          // TODO: Implement lab selection
                        },
                      )),
                    ],
                    
                    // No schedule message
                    if (lectures.isEmpty && tutorials.isEmpty && labs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No detailed schedule available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This course may not have scheduled classes or the schedule information is not available.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            const Divider(),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedLectureTime = null;
                      selectedTutorialTime = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelectionChanged(selectedLectureTime, selectedTutorialTime);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Selection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isLectureSelected(ScheduleEntry lecture) {
    if (selectedLectureTime == null) return false;
    final scheduleString = StudentCourse.formatScheduleString(lecture.day, lecture.time);
    return selectedLectureTime == scheduleString;
  }

  bool _isTutorialSelected(ScheduleEntry tutorial) {
    if (selectedTutorialTime == null) return false;
    final scheduleString = StudentCourse.formatScheduleString(tutorial.day, tutorial.time);
    return selectedTutorialTime == scheduleString;
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            '$title ($count available)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(
    ScheduleEntry schedule,
    CourseEventType type,
    bool isSelected,
    Function(bool) onChanged,
  ) {
    final color = getEventColor(
      type, 
      isSelected ? CourseEventState.selected : CourseEventState.available,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isSelected ? 4 : 1,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(
          '${schedule.day} ${schedule.time}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (schedule.hasStaff)
              Text('Instructor: ${schedule.staff}'),
            if (schedule.fullLocation.isNotEmpty)
              Text('Location: ${schedule.fullLocation}'),
            if (schedule.group > 0)
              Text('Group: ${schedule.group}'),
          ],
        ),
        secondary: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
