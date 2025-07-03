// lib/widgets/schedule_selection_dialog.dart - Fixed grouping of duplicate times

import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/student_model.dart';
import '../mixins/course_event_mixin.dart';

class ScheduleSelectionDialog extends StatefulWidget {
  final StudentCourse course;
  final EnhancedCourseDetails courseDetails;
  final Function(String? lectureTime, String? tutorialTime, String? labTime, String? workshopTime) onSelectionChanged;

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
  String? selectedLabTime; // Placeholder for future lab selection
  String? selectedWorkshopTime; // Placeholder for future workshop selection
  
  // Group schedule entries by type and unique time slots
  List<ScheduleGroup> lectures = [];
  List<ScheduleGroup> tutorials = [];
  List<ScheduleGroup> labs = [];
  List<ScheduleGroup> workshops = []; // Placeholder for future use

  @override
  void initState() {
    super.initState();
    selectedLectureTime = widget.course.lectureTime.isNotEmpty ? widget.course.lectureTime : null;
    selectedTutorialTime = widget.course.tutorialTime.isNotEmpty ? widget.course.tutorialTime : null;
    selectedLabTime = widget.course.labTime.isNotEmpty ? widget.course.labTime : null;
    selectedWorkshopTime = widget.course.workshopTime.isNotEmpty ? widget.course.workshopTime : null;
    // Group schedule entries by type and time slot
    _groupScheduleEntries();
  }

  void _groupScheduleEntries() {
    // Group by type first
    final lectureEntries = <ScheduleEntry>[];
    final tutorialEntries = <ScheduleEntry>[];
    final labEntries = <ScheduleEntry>[];
    final workshopEntries = <ScheduleEntry>[]; // Placeholder for future use
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
        case CourseEventType.workshop:
          workshopEntries.add(schedule);
          break;
      }
    }

    // Group by unique time slots
    lectures = _groupByTimeSlot(lectureEntries);
    tutorials = _groupByTimeSlot(tutorialEntries);
    labs = _groupByTimeSlot(labEntries);
    workshops = _groupByTimeSlot(workshopEntries); // Placeholder for future use

  }  List<ScheduleGroup> _groupByTimeSlot(List<ScheduleEntry> entries) {
    // First, deduplicate entries that have the same day, time, and instructor
    final Map<String, ScheduleEntry> uniqueEntries = {};
    
    for (final entry in entries) {
      // Create a unique key based on day, time, and instructor
      final uniqueKey = '${entry.day}_${entry.time}_${entry.staff}';
      
      // Only add if we haven't seen this combination before
      if (!uniqueEntries.containsKey(uniqueKey)) {
        uniqueEntries[uniqueKey] = entry;
      }
    }
    
    // Now group the deduplicated entries by type and group number
    final Map<String, List<ScheduleEntry>> groupsByTypeAndGroup = {};
    
    for (final entry in uniqueEntries.values) {
      // Group by type and group number instead of just time
      final groupKey = '${entry.type}_${entry.group}';
      groupsByTypeAndGroup.putIfAbsent(groupKey, () => []).add(entry);
    }
    
    return groupsByTypeAndGroup.entries.map((entry) {
      final groupKey = entry.key;
      final scheduleEntries = entry.value;
      
      // Sort by day and time to show chronologically
      scheduleEntries.sort((a, b) {
        // First sort by day (convert Hebrew days to weekday numbers)
        final dayA = _getWeekdayNumber(a.day);
        final dayB = _getWeekdayNumber(b.day);
        if (dayA != dayB) return dayA.compareTo(dayB);
        
        // Then sort by time
        return a.time.compareTo(b.time);
      });
      
      return ScheduleGroup(
        timeKey: groupKey,
        day: scheduleEntries.first.day, // First chronologically
        time: scheduleEntries.first.time, // First chronologically
        entries: scheduleEntries,
      );
    }).toList();
  }
  
  int _getWeekdayNumber(String hebrewDay) {
    switch (hebrewDay) {
      case 'ראשון': return 1; // Sunday
      case 'שני': return 2; // Monday
      case 'שלישי': return 3; // Tuesday
      case 'רביעי': return 4; // Wednesday
      case 'חמישי': return 5; // Thursday
      case 'שישי': return 6; // Friday
      case 'שבת': return 7; // Saturday
      default: return 0;
    }
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
                        _isLectureSelected(lectureGroup),                        (selected) {
                          setState(() {
                            selectedLectureTime = selected 
                                ? _createGroupIdentifier(lectureGroup)
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
                        _isTutorialSelected(tutorialGroup),                        (selected) {
                          setState(() {
                            selectedTutorialTime = selected 
                                ? _createGroupIdentifier(tutorialGroup)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    // Labs Section
                    if (labs.isNotEmpty) ...[
                      _buildSectionHeader('Labs', Icons.science, labs.length),
                      ...labs.map((labGroup) => _buildScheduleGroupOption(
                        labGroup,
                        CourseEventType.lab,
                        _isLabSelected(labGroup),                        (selected) {
                          setState(() {
                            selectedLabTime = selected 
                                ? _createGroupIdentifier(labGroup)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                    // Workshops Section
                    if (workshops.isNotEmpty) ...[
                      _buildSectionHeader('Workshops', Icons.garage, workshops.length),
                      ...workshops.map((workshopGroup) => _buildScheduleGroupOption(
                        workshopGroup,
                        CourseEventType.workshop,
                        _isWorkshopSelected(workshopGroup),                        (selected) {
                          setState(() {
                            selectedWorkshopTime = selected 
                                ? _createGroupIdentifier(workshopGroup)
                                : null;
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ],

                    // No schedule message
                    if (lectures.isEmpty && tutorials.isEmpty && labs.isEmpty && workshops.isEmpty)
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
                      selectedLabTime = null; // Reset lab selection
                      selectedWorkshopTime = null; // Reset workshop selection
                    });
                  },
                  child: const Text('Clear All'),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
      }
        return context.read<ThemeProvider>().isLightMode ? context.read<ThemeProvider>().accentColor : context.read<ThemeProvider>().secondaryColor ;
    }),
                  ),
                  onPressed: () {
                    widget.onSelectionChanged(selectedLectureTime, selectedTutorialTime, selectedLabTime, selectedWorkshopTime);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Selection'),
                ),
              ],            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to create a group identifier that can be used to find all sessions in a group
  String _createGroupIdentifier(ScheduleGroup scheduleGroup) {
    // Use the first entry's type and group to create an identifier
    final firstEntry = scheduleGroup.entries.first;
    return 'GROUP_${firstEntry.type}_${firstEntry.group}';
  }
  
  bool _isLectureSelected(ScheduleGroup lectureGroup) {
    if (selectedLectureTime == null) return false;
    // Check if it's a group identifier or old format
    if (selectedLectureTime!.startsWith('GROUP_')) {
      return selectedLectureTime == _createGroupIdentifier(lectureGroup);
    } else {
      // Backward compatibility: check against old format
      final scheduleString = StudentCourse.formatScheduleString(lectureGroup.day, lectureGroup.time);
      return selectedLectureTime == scheduleString;
    }
  }

  bool _isTutorialSelected(ScheduleGroup tutorialGroup) {
    if (selectedTutorialTime == null) return false;
    // Check if it's a group identifier or old format
    if (selectedTutorialTime!.startsWith('GROUP_')) {
      return selectedTutorialTime == _createGroupIdentifier(tutorialGroup);
    } else {
      // Backward compatibility: check against old format
      final scheduleString = StudentCourse.formatScheduleString(tutorialGroup.day, tutorialGroup.time);
      return selectedTutorialTime == scheduleString;
    }
  }

  bool _isLabSelected(ScheduleGroup labGroup) {
    if (selectedLabTime == null) return false;
    // Check if it's a group identifier or old format
    if (selectedLabTime!.startsWith('GROUP_')) {
      return selectedLabTime == _createGroupIdentifier(labGroup);
    } else {
      // Backward compatibility: check against old format
      final scheduleString = StudentCourse.formatScheduleString(labGroup.day, labGroup.time);
      return selectedLabTime == scheduleString;
    }
  }
  
  bool _isWorkshopSelected(ScheduleGroup workshopGroup) {
    if (selectedWorkshopTime == null) return false;
    // Check if it's a group identifier or old format
    if (selectedWorkshopTime!.startsWith('GROUP_')) {
      return selectedWorkshopTime == _createGroupIdentifier(workshopGroup);
    } else {
      // Backward compatibility: check against old format
      final scheduleString = StudentCourse.formatScheduleString(workshopGroup.day, workshopGroup.time);
      return selectedWorkshopTime == scheduleString;
    }
  }
  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.read<ThemeProvider>().primaryColor),
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
    );    // Build title showing all time slots without group numbers for cleaner display
    String title;
    if (scheduleGroup.entries.length > 1) {
      // Show all time slots without group number
      final timeSlots = scheduleGroup.entries
          .map((e) => '${e.day} ${e.time}')
          .join(' + ');
      title = timeSlots;
    } else {
      // Single time slot without group number
      final entry = scheduleGroup.entries.first;
      title = '${entry.day} ${entry.time}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4,horizontal: 3),
      elevation: isSelected ? 4 : 2,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show instructor from first entry (they're usually the same)
            if (scheduleGroup.entries.first.hasStaff)
              Text('Instructor: ${scheduleGroup.entries.first.staff}'),
            
            // Show location from first entry (or multiple if different)
            if (scheduleGroup.entries.first.fullLocation.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final locations = scheduleGroup.entries
                      .map((e) => e.fullLocation)
                      .where((loc) => loc.isNotEmpty)
                      .toSet()
                      .join(', ');
                  return Text('Location: $locations');
                },
              ),
            ],
            
            // Show additional info for paired events
            if (scheduleGroup.entries.length > 1)
              Text('${scheduleGroup.entries.length} paired sessions', 
                   style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
