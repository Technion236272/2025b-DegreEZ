// lib/widgets/course_events_widget.dart
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import '../services/course_service.dart';
import '../mixins/course_event_mixin.dart';

class CourseEventData {
  final String courseId;
  final String courseName;
  final ScheduleEntry scheduleEntry;
  final CourseEventType type;
  final int? groupNumber;
  final String eventId;
  CourseEventState state;

  CourseEventData({
    required this.courseId,
    required this.courseName,
    required this.scheduleEntry,
    required this.type,
    this.groupNumber,
    required this.eventId,
    this.state = CourseEventState.available,
  });
}

class CourseEventsWidget extends StatefulWidget {
  final EnhancedCourseDetails courseDetails;
  final EventController eventController;
  final Function(String courseId, CourseEventData? selectedLecture, CourseEventData? selectedTutorial, CourseEventData? selectedLab, CourseEventData? selectedWorkshop)? onSelectionChanged;
  final DateTime? weekStartDate; // For generating events for specific week

  const CourseEventsWidget({
    super.key,
    required this.courseDetails,
    required this.eventController,
    this.onSelectionChanged,
    this.weekStartDate,
  });

  @override
  State<CourseEventsWidget> createState() => _CourseEventsWidgetState();
}

class _CourseEventsWidgetState extends State<CourseEventsWidget> with CourseEventMixin {
  final Map<String, CourseEventData> _allEvents = {};
  CourseEventData? _selectedLecture;
  CourseEventData? _selectedTutorial;
  CourseEventData? _selectedLab;
  CourseEventData? _selectedWorkshop;
  @override
  void initState() {
    super.initState();
    _generateCourseEvents();
  }

  @override
  void didUpdateWidget(CourseEventsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseDetails.courseNumber != widget.courseDetails.courseNumber ||
        oldWidget.weekStartDate != widget.weekStartDate) {
      _clearEvents();
      _generateCourseEvents();
    }
  }

  void _clearEvents() {
    // Remove existing events for this course
    final eventsToRemove = widget.eventController.allEvents
        .where((event) => event.event?.toString().startsWith(widget.courseDetails.courseNumber) ?? false)
        .toList();
    
    for (final event in eventsToRemove) {
      widget.eventController.remove(event);
    }
    
    _allEvents.clear();
    _selectedLecture = null;
    _selectedTutorial = null;
    _selectedLab = null;
    _selectedWorkshop = null;
  }

  void _generateCourseEvents() {
    final baseDate = widget.weekStartDate ?? DateTime.now();
    final weekStart = _getWeekStart(baseDate);

    for (final scheduleEntry in widget.courseDetails.schedule) {
      final eventType = parseCourseEventType(scheduleEntry.type);
      final dayOfWeek = parseHebrewDay(scheduleEntry.day);
      final eventDate = _getDateForWeekday(weekStart, dayOfWeek);
      
      final timeRange = parseTimeRange(scheduleEntry.time, eventDate);
      if (timeRange == null) continue;

      // Extract group number from schedule entry if available
      final groupNumber = _extractGroupNumber(scheduleEntry.type);

      final eventId = '${widget.courseDetails.courseNumber}_${scheduleEntry.day}_${scheduleEntry.time}_${scheduleEntry.type}';
      
      final courseEventData = CourseEventData(
        courseId: widget.courseDetails.courseNumber,
        courseName: widget.courseDetails.name,
        scheduleEntry: scheduleEntry,
        type: eventType,
        groupNumber: groupNumber,
        eventId: eventId,
      );

      _allEvents[eventId] = courseEventData;      final calendarEvent = CalendarEventData(
        date: eventDate,
        title: formatEventTitle(
          widget.courseDetails.name, 
          eventType, 
          groupNumber,
          instructorName: scheduleEntry.staff.isNotEmpty ? scheduleEntry.staff : null,
        ),
        description: _buildEventDescription(scheduleEntry),
        startTime: timeRange['start']!,
        endTime: timeRange['end']!,
        color: getEventColor(eventType, courseEventData.state),
        event: courseEventData, // Store our custom data
      );

      widget.eventController.add(calendarEvent);
    }
  }

  int? _extractGroupNumber(String typeString) {
    final regex = RegExp(r'קבוצה (\d+)');
    final match = regex.firstMatch(typeString);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  String _buildEventDescription(ScheduleEntry scheduleEntry) {
    final parts = <String>[];
    
    if (scheduleEntry.hasStaff) {
      parts.add('מרצה: ${scheduleEntry.staff}');
    }
    if (scheduleEntry.fullLocation.isNotEmpty) {
      parts.add('מקום: ${scheduleEntry.fullLocation}');
    }
    if (scheduleEntry.type.isNotEmpty) {
      parts.add('סוג: ${scheduleEntry.type}');
    }
    
    return parts.join('\n');
  }
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday % 7));
  }

  DateTime _getDateForWeekday(DateTime weekStart, int targetWeekday) {
    final daysToAdd = targetWeekday == DateTime.sunday ? 0 : targetWeekday;
    return weekStart.add(Duration(days: daysToAdd));
  }

/* ISN'T REFERENCED IN THE CODE AT ALL
  void _handleLectureSelection(CourseEventData eventData) {
    if (_selectedLecture?.eventId == eventData.eventId) {
      // Deselect if same lecture is tapped again
      _selectedLecture = null;
    } else {
      // Clear previous lecture selection
      if (_selectedLecture != null) {
        _selectedLecture!.state = CourseEventState.available;
      }
      // Select new lecture
      _selectedLecture = eventData;
      eventData.state = CourseEventState.selected;
    }
  }

  void _handleTutorialSelection(CourseEventData eventData) {
    if (_selectedTutorial?.eventId == eventData.eventId) {
      // Deselect if same tutorial is tapped again
      _selectedTutorial = null;
    } else {
      // Clear previous tutorial selection
      if (_selectedTutorial != null) {
        _selectedTutorial!.state = CourseEventState.available;
      }
      // Select new tutorial
      _selectedTutorial = eventData;
      eventData.state = CourseEventState.selected;
    }
  }
  void _handleLabSelection(CourseEventData eventData) {
    if (_selectedLab?.eventId == eventData.eventId) {
      // Deselect if same lab is tapped again
      _selectedLab = null;
    } else {
      // Clear previous lab selection
      if (_selectedLab != null) {
        _selectedLab!.state = CourseEventState.available;
      }
      // Select new lab
      _selectedLab = eventData;
      eventData.state = CourseEventState.selected;
    }
  }
  void _handleWorkshopSelection(CourseEventData eventData) {
    if (_selectedWorkshop?.eventId == eventData.eventId) {
      // Deselect if same workshop is tapped again
      _selectedWorkshop = null;
    } else {
      // Clear previous workshop selection
      if (_selectedWorkshop != null) {
        _selectedWorkshop!.state = CourseEventState.available;
      }
      // Select new workshop
      _selectedWorkshop = eventData;
      eventData.state = CourseEventState.selected;
    }
  }
*/
  void _updateEventStates() {
    for (final eventData in _allEvents.values) {
      // Reset to available if not selected
      if (eventData != _selectedLecture && eventData != _selectedTutorial && eventData != _selectedLab && eventData != _selectedWorkshop) {
        eventData.state = CourseEventState.available;
      }

      // Check for conflicts
      _checkForConflicts(eventData);
    }
  }

  void _checkForConflicts(CourseEventData eventData) {
    // !!!!
    // This is where you'd implement conflict detection with other courses
    // For now, just check if times overlap with selected events
    final selectedEvents = [_selectedLecture, _selectedTutorial, _selectedLab, _selectedWorkshop]
        .whereType<CourseEventData>()
        .where((e) => e != eventData)
        .cast<CourseEventData>();

    for (final selectedEvent in selectedEvents) {
      if (_hasTimeConflict(eventData.scheduleEntry, selectedEvent.scheduleEntry)) {
        eventData.state = CourseEventState.conflicted;
        break;
      }
    }
  }

  bool _hasTimeConflict(ScheduleEntry entry1, ScheduleEntry entry2) {
    if (entry1.day != entry2.day) return false;
    
    // Parse times and check for overlap
    final baseDate = DateTime.now();
    final time1 = parseTimeRange(entry1.time, baseDate);
    final time2 = parseTimeRange(entry2.time, baseDate);
    
    if (time1 == null || time2 == null) return false;
    
    return time1['start']!.isBefore(time2['end']!) && 
           time2['start']!.isBefore(time1['end']!);
  }

  void _updateCalendarEvents() {
    // Update colors of calendar events based on new states
    final eventsToUpdate = widget.eventController.allEvents
        .where((event) => event.event is CourseEventData)
        .toList();

    for (final calendarEvent in eventsToUpdate) {
      final courseEventData = calendarEvent.event as CourseEventData;
      if (_allEvents.containsKey(courseEventData.eventId)) {
        final updatedEvent = CalendarEventData(
          date: calendarEvent.date,
          title: calendarEvent.title,
          description: calendarEvent.description,
          startTime: calendarEvent.startTime!,
          endTime: calendarEvent.endTime!,
          color: getEventColor(courseEventData.type, courseEventData.state),
          event: courseEventData,
        );

        widget.eventController.remove(calendarEvent);
        widget.eventController.add(updatedEvent);
      }
    }
  }

  // Public methods for external access
  bool get hasCompleteSelection => _selectedLecture != null && _selectedTutorial != null;
  
  CourseEventData? get selectedLecture => _selectedLecture;
  CourseEventData? get selectedTutorial => _selectedTutorial;
  CourseEventData? get selectedLab => _selectedLab;
  CourseEventData? get selectedWorkshop => _selectedWorkshop;
  Map<String, CourseEventData> get allEvents => Map.unmodifiable(_allEvents);

  void clearSelections() {
    setState(() {
      _selectedLecture = null;
      _selectedTutorial = null;
      _selectedLab = null;
      _selectedWorkshop = null;
      _updateEventStates();
      _updateCalendarEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course: ${widget.courseDetails.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Course ID: ${widget.courseDetails.courseNumber}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Selection status
          _buildSelectionStatus(),
          
          const SizedBox(height: 16),
          
          // Event legend
          _buildEventLegend(),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: clearSelections,
                child: const Text('Clear Selections'),
              ),
              const SizedBox(width: 8),
              if (hasCompleteSelection)
                ElevatedButton(
                  onPressed: () {
                    // Handle confirming the selection
                    _confirmSelection();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Confirm Selection'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selection Status:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.school,
              color: _selectedLecture != null ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Lecture: ${_selectedLecture != null ? "Selected" : "Not selected"}',
              style: TextStyle(
                color: _selectedLecture != null ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.groups,
              color: _selectedTutorial != null ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Tutorial: ${_selectedTutorial != null ? "Selected" : "Not selected"}',
              style: TextStyle(
                color: _selectedTutorial != null ? Colors.green : Colors.grey,
              ),
            ),
          ],
          
          
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.science,
              color: _selectedLab != null ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Lab: ${_selectedLab != null ? "Selected" : "Not selected"}',
              style: TextStyle(
                color: _selectedLab != null ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.work,
              color: _selectedWorkshop != null ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Workshop: ${_selectedWorkshop != null ? "Selected" : "Not selected"}',
              style: TextStyle(
                color: _selectedWorkshop != null ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legend:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildLegendItem(Colors.blue.withValues(alpha: 0.7), 'Available Lecture'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.green.withValues(alpha: 0.7), 'Available Tutorial'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange.withValues(alpha: 0.7), 'Available Lab'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.purple.withValues(alpha: 0.7), 'Available Workshop'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildLegendItem(Colors.blue, 'Selected'),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.red.withValues(alpha: 0.8), 'Conflict'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _confirmSelection() {
    if (hasCompleteSelection) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Course Selection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course: ${widget.courseDetails.name}'),
              const SizedBox(height: 8),
              Text('Lecture: ${_selectedLecture!.scheduleEntry.day} ${_selectedLecture!.scheduleEntry.time}'),
              Text('Tutorial: ${_selectedTutorial!.scheduleEntry.day} ${_selectedTutorial!.scheduleEntry.time}'),
              if (_selectedLab != null)
                Text('Lab: ${_selectedLab!.scheduleEntry.day} ${_selectedLab!.scheduleEntry.time}'),
              if (_selectedWorkshop != null)
                Text('Workshop: ${_selectedWorkshop!.scheduleEntry.day} ${_selectedWorkshop!.scheduleEntry.time}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle final confirmation
                _finalizeSelection();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _finalizeSelection() {
    // This is where you'd save the selection to the student's profile
    // and remove the unselected events from the calendar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Course selection confirmed for ${widget.courseDetails.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}