// lib/mixins/calendar_theme_mixin.dart
// Copy the entire CalendarDarkThemeMixin from calendar_try1
import 'package:auto_size_text/auto_size_text.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:degreez/color/color_palette.dart';
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
  /// add also the day number
  /// add also the day name , done manually 
  /// put next to the day number
  Widget buildWeekDay(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: getHeaderBackgroundColor(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getDayName(date),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 1), // Space between day name and number
          Text(
            date.day.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
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
  }    /// Build an event tile with dark theme styling
  Widget buildEventTile(
    BuildContext context,
    DateTime date, 
    List<CalendarEventData> events,
    Rect boundary, 
    DateTime startDuration, 
    DateTime endDuration,
    {bool filtered = false, String searchQuery = '', Function(CalendarEventData)? onLongPress}
  ) {
    if (events.isEmpty) return const SizedBox();
    
    final filteredEvents = filtered && searchQuery.isNotEmpty
        ? events.where((event) => 
            event.title.toLowerCase().contains(searchQuery.toLowerCase())).toList()
        : events;
    
    if (filteredEvents.isEmpty) return const SizedBox();
    
    return GestureDetector(
      onLongPress: onLongPress != null ? () => onLongPress(filteredEvents.first) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.only(left: 2,top: 2,bottom: 2,right: 5),
        decoration: BoxDecoration(
           boxShadow: [
      BoxShadow(
        color: AppColorsDarkMode.shadowColorStrong, // shadow color
        blurRadius: 4, // how blurry the shadow is
        offset: Offset(-2, 2), // horizontal and vertical displacement
        spreadRadius: 2, // how much the shadow expands
      ),
    ],
          color: filteredEvents.first.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AutoSizeText(
          filteredEvents.first.title,
          // if the color is light, use black text, otherwise use white
          textAlign:TextAlign.right,          
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 5,
          minFontSize: 5,
        ),
      ),
    );
  }
}