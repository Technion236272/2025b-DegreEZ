// lib/mixins/calendar_theme_mixin.dart
// Copy the entire CalendarDarkThemeMixin from calendar_try1
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

mixin CalendarDarkThemeMixin {
  /// Get the background color for the entire calendar
  Color getCalendarBackgroundColor(BuildContext context) => 
      Theme.of(context).colorScheme.background;
      
  /// Get the color for calendar cell borders
  Color getBorderColor(BuildContext context) => 
      Theme.of(context).colorScheme.onSurface.withAlpha(40);
      
  /// Get the color for the current time indicator
  Color getLiveTimeIndicatorColor(BuildContext context) => 
      Theme.of(context).colorScheme.secondary;
      
  /// Get the color for the header background
  Color getHeaderBackgroundColor(BuildContext context) => 
      Theme.of(context).colorScheme.surface;
      
  /// Get the text style for the header text
  TextStyle getHeaderTextStyle(BuildContext context) => 
      TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      );
      
  /// Get settings for the hour indicator lines
  HourIndicatorSettings getHourIndicatorSettings(BuildContext context) => 
      HourIndicatorSettings(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
        height: 0.5,
        offset: 5,
      );
      
  /// Get settings for the live time indicator
  LiveTimeIndicatorSettings getLiveTimeIndicatorSettings(BuildContext context) => 
      LiveTimeIndicatorSettings(
        color: getLiveTimeIndicatorColor(context),
        // thickness: 2,
      );
      
  /// Get the header style with proper dark theme colors
  HeaderStyle getHeaderStyle(BuildContext context) => 
      HeaderStyle(
        decoration: BoxDecoration(
          color: getHeaderBackgroundColor(context),
        ),
        headerTextStyle: getHeaderTextStyle(context),
      );
      
  /// Build the timeline for hours with dark theme styling
  Widget buildTimeLine(BuildContext context, DateTime date) {
    return Container(
      color: getHeaderBackgroundColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '${date.hour}:00',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Build a weekday header with dark theme styling
  Widget buildWeekDay(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: getHeaderBackgroundColor(context),
      child: Text(
        date.day.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
  
  /// Build a day header with dark theme styling
  Widget buildDayHeader(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: getHeaderBackgroundColor(context),
      child: Text(
        'Day: ${date.day}/${date.month}/${date.year}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
    /// Build an event tile with dark theme styling
  Widget buildEventTile(
    BuildContext context,
    DateTime date, 
    List<CalendarEventData> events,
    Rect boundary, 
    DateTime startDuration, 
    DateTime endDuration,
    {bool filtered = false, String searchQuery = ''}
  ) {
    if (events.isEmpty) return const SizedBox();
    
    final filteredEvents = filtered && searchQuery.isNotEmpty
        ? events.where((event) => 
            event.title.toLowerCase().contains(searchQuery.toLowerCase())).toList()
        : events;
    
    if (filteredEvents.isEmpty) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(2),      decoration: BoxDecoration(
        color: filteredEvents.first.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        filteredEvents.first.title,
        style: const TextStyle(color: Colors.white, fontSize: 8),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}