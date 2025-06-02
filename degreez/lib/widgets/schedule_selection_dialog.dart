// lib/widgets/schedule_selection_dialog.dart - Fixed grouping of duplicate times

import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';
import '../mixins/course_event_mixin.dart';

class ScheduleSelectionDialog extends StatefulWidget {
  final StudentCourse course;
  final EnhancedCourseDetails courseDetails;
  final Function(String? lectureTime, String? tutorialTime) onSelectionChanged;

  const ScheduleSelectionDialog({
    super.key,
    required this.course,
    required this.courseDetails,
    required this.onSelectionChanged,
  });

  @override
  State<ScheduleSelectionDialog> createState() => _ScheduleSelectionDialogState();
}

class _ScheduleSelectionDialogState extends State<ScheduleSelectionDialog> 
    with CourseEventMixin {
  String? selectedLectureTime;
  String? selectedTutorialTime;
  
  // Group schedule entries by type and unique time slots
  List<ScheduleGroup> lectures = [];
  List<ScheduleGroup> tutorials = [];
  List<ScheduleGroup> labs = [];

  @override
  void initState() {
    super.initState();
    selectedLectureTime = widget.course.lectureTime.isNotEmpty ? widget.course.lectureTime : null;
    selectedTutorialTime = widget.course.tutorialTime.isNotEmpty ? widget.course.tutorialTime : null;
    
    // Group schedule entries by type and time slot
    _groupScheduleEntries();
  }

  void _groupScheduleEntries() {
    // Group by type first
    final lectureEntries = <ScheduleEntry>[];
    final tutorialEntries = <ScheduleEntry>[];
    final labEntries = <ScheduleEntry>[];

    for (final schedule in widget.courseDetails.schedule) {
      final type = parseCourseEventType(schedule.type);
      switch (type) {
        case CourseEventType.lecture:
          lectureEntries.add(schedule);
          break;
        case CourseEventType.tutorial:
          tutorialEntries.add(schedule);
          break;
        case CourseEventType.lab:
          labEntries.add(schedule);
          break;
      }
    }

    // Group by unique time slots
    lectures = _groupByTimeSlot(lectureEntries);
    tutorials = _groupByTimeSlot(tutorialEntries);
    labs = _groupByTimeSlot(labEntries);
  }

  List<ScheduleGroup> _groupByTimeSlot(List<ScheduleEntry> entries) {
    final Map<String, List<ScheduleEntry>> timeGroups = {};
    
    for (final entry in entries) {
      final timeKey = '${entry.day} ${entry.time}';
      timeGroups.putIfAbsent(timeKey, () => []).add(entry);
    }
    
    return timeGroups.entries.map((entry) {
      final timeKey = entry.key;
      final scheduleEntries = entry.value;
      
      // Sort by group number
      scheduleEntries.sort((a, b) => a.group.compareTo(b.group));
      
      return ScheduleGroup(
        timeKey: timeKey,
        day: scheduleEntries.first.day,
        time: scheduleEntries.first.time,
        entries: scheduleEntries,
      );
    }).toList();
  }
  @override
  Widget build(BuildContext context) {    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // Reduced from 0.9 to fix overflow
        height: MediaQuery.of(context).size.height * 0.75, // Reduced from 0.8 to 0.75
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
                      ...lectures.map((lectureGroup) => _buildScheduleGroupOption(
                        lectureGroup,
                        CourseEventType.lecture,
                        _isLectureSelected(lectureGroup),
                        (selected) {
                          setState(() {
                            selectedLectureTime = selected 
                                ? StudentCourse.formatScheduleString(lectureGroup.day, lectureGroup.time)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    
                    // Tutorials Section
                    if (tutorials.isNotEmpty) ...[
                      _buildSectionHeader('Tutorials', Icons.groups, tutorials.length),
                      ...tutorials.map((tutorialGroup) => _buildScheduleGroupOption(
                        tutorialGroup,
                        CourseEventType.tutorial,
                        _isTutorialSelected(tutorialGroup),
                        (selected) {
                          setState(() {
                            selectedTutorialTime = selected 
                                ? StudentCourse.formatScheduleString(tutorialGroup.day, tutorialGroup.time)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    
                    // Labs Section (for future use)
                    if (labs.isNotEmpty) ...[
                      _buildSectionHeader('Labs', Icons.science, labs.length),
                      ...labs.map((labGroup) => _buildScheduleGroupOption(
                        labGroup,
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
            // const Divider(),
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

  bool _isLectureSelected(ScheduleGroup lectureGroup) {
    if (selectedLectureTime == null) return false;
    final scheduleString = StudentCourse.formatScheduleString(lectureGroup.day, lectureGroup.time);
    return selectedLectureTime == scheduleString;
  }

  bool _isTutorialSelected(ScheduleGroup tutorialGroup) {
    if (selectedTutorialTime == null) return false;
    final scheduleString = StudentCourse.formatScheduleString(tutorialGroup.day, tutorialGroup.time);
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
            '$title ($count time slots)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleGroupOption(
    ScheduleGroup scheduleGroup,
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
          '${scheduleGroup.day} ${scheduleGroup.time}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show instructor from first entry (they're usually the same)
            if (scheduleGroup.entries.first.hasStaff)
              Text('Instructor: ${scheduleGroup.entries.first.staff}'),
            
            // Show location from first entry
            if (scheduleGroup.entries.first.fullLocation.isNotEmpty)
              Text('Location: ${scheduleGroup.entries.first.fullLocation}'),
            
            // Show available groups
            if (scheduleGroup.entries.length > 1)
              Text('Groups: ${scheduleGroup.entries.map((e) => e.group).join(', ')}')
            else if (scheduleGroup.entries.first.group > 0)
              Text('Group: ${scheduleGroup.entries.first.group}'),
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

// Helper class to group schedule entries by time slot
class ScheduleGroup {
  final String timeKey;
  final String day;
  final String time;
  final List<ScheduleEntry> entries;

  ScheduleGroup({
    required this.timeKey,
    required this.day,
    required this.time,
    required this.entries,
  });
}
