// lib/mixins/calendar_theme_mixin.dart
// Copy the entire CalendarDarkThemeMixin from calendar_try1
import 'package:auto_size_text/auto_size_text.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

mixin CalendarDarkThemeMixin {
  /// Get the background color for the entire calendar
  Color getCalendarBackgroundColor(BuildContext context) => 
      Theme.of(context).colorScheme.surface;
      
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
  /// remove the hardcoded color and use the theme
  /// add a word "degreez" to the header text
  TextStyle getHeaderTextStyle(BuildContext context) => 
      TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      );
      
  /// Get settings for the hour indicator lines
  HourIndicatorSettings getHourIndicatorSettings(BuildContext context) => 
      HourIndicatorSettings(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
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
      // padding: const EdgeInsets.symmetric(horizontal: 8),
      
      child: Text(
        '${date.hour}:00',
        style: TextStyle(
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Get the day name from a DateTime
  String getDayName(DateTime date) {
    const dayNames = [ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ];
    if (date.weekday < 1 || date.weekday > 7) {
      throw ArgumentError('Invalid weekday: ${date.weekday}');
    }
    return dayNames[date.weekday - 1];
  }
  
  /// Build a weekday header with dark theme styling
  Widget buildWeekDay(BuildContext context, DateTime date) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: getHeaderBackgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha(25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getDayName(date).toUpperCase(),
            style: TextStyle(
              color: isToday ? theme.colorScheme.primary : textColor.withAlpha(153),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center, // Center the text within the container
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : null,
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isToday ? theme.colorScheme.onPrimary : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build a day header with dark theme styling
  /// add the day name and the date
  Widget buildDayHeader(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: getHeaderBackgroundColor(context),
      child: Text(
        'Day:  ${date.day}/${date.month}/${date.year} (${getDayName(date)})',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }  /// Build an event tile with dark theme styling
  Widget buildEventTile(
    BuildContext context,
    DateTime date, 
    List<CalendarEventData> events,
    Rect boundary, 
    DateTime startDuration, 
    DateTime endDuration,
    {bool filtered = false, String searchQuery = '', Function(CalendarEventData)? onLongPress, Function(CalendarEventData)? onTap}
  ) {
    if (events.isEmpty) return const SizedBox();
    
    final filteredEvents = filtered && searchQuery.isNotEmpty
        ? events.where((event) => 
            event.title.toLowerCase().contains(searchQuery.toLowerCase())).toList()
        : events;
    
    if (filteredEvents.isEmpty) return const SizedBox();
    
    final event = filteredEvents.first;
    final isSmallDuration = endDuration.difference(startDuration).inMinutes < 60;

    return GestureDetector(
      onTap: onTap != null ? () => onTap(event) : null,
      onLongPress: onLongPress != null ? () => onLongPress(event) : null,
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
        decoration: BoxDecoration(
          color: event.color.withAlpha(217), // ~0.85 opacity
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.color.withAlpha(128), // ~0.5 opacity
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: event.color.withAlpha(51), // ~0.2 opacity
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AutoSizeText(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                minFontSize: 8,
                maxLines: isSmallDuration ? 1 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isSmallDuration)
              Text(
                '${event.startTime?.hour.toString().padLeft(2, '0')}:${event.startTime?.minute.toString().padLeft(2, '0')} - ${event.endTime?.hour.toString().padLeft(2, '0')}:${event.endTime?.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}