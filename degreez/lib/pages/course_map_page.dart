import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';
import '../services/geocode_cache_service.dart';
import '../services/building_geocode_map.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/next_class_button.dart';

class CourseMarkerData {
  final LatLng point;
  final String label;
  final Color color;
  final String buildingName;
  final String roomNumber;
  final DateTime? nextClassTime;

  CourseMarkerData({
    required this.point,
    required this.label,
    required this.color,
    required this.buildingName,
    required this.roomNumber,
    this.nextClassTime,
  });
}

class CourseMapPage extends StatefulWidget {
  final String selectedSemester;

  const CourseMapPage({super.key, required this.selectedSemester});

  @override
  State<CourseMapPage> createState() => _CourseMapPageState();
}

class _CourseMapPageState extends State<CourseMapPage> {
  LatLng? userLocation;
  List<CourseMarkerData> courseMarkers = [];
  bool isLoading = true;
  final _geoService = GeocodeCacheService();
  final Map<String, Color> courseColors = {};
  bool legendVisible = true;
  final Map<String, int> _buildingPinCounts = {};
  final Map<String, List<LatLng>> _courseLocations = {};
  late final MapController _mapController = MapController();
  final Set<String> visibleCourses = {}; // course names that are visible
  String? _highlightedCourse;
  final Map<String, bool> visibleEvents =
      {}; // key: 'CourseName (Lecture 1)', value: isVisible
  StreamSubscription<LocationData>? _locationSubscription;
  final Location location = Location(); // reuse this across the widget

  int colorIndex = 0;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  (int, int)? _parseSemesterCode(String semesterName) {
    final match = RegExp(
      r'^(Winter|Spring|Summer) (\d{4})(?:-(\d{4}))?$',
    ).firstMatch(semesterName);
    if (match == null) return null;

    final season = match.group(1)!;
    final firstYear = int.parse(match.group(2)!);

    int apiYear;
    int semesterCode;

    switch (season) {
      case 'Winter':
        apiYear = firstYear; // Use the first year for Winter
        semesterCode = 200;
        break;
      case 'Spring':
        apiYear = firstYear - 1;
        semesterCode = 201;
        break;
      case 'Summer':
        apiYear = firstYear - 1;
        semesterCode = 202;
        break;
      default:
        return null;
    }

    return (apiYear, semesterCode);
  }

  Future<void> _launchNavigation(LatLng destination) async {
    final lat = destination.latitude;
    final lon = destination.longitude;

    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=walking",
    );
    final wazeUrl = Uri.parse("https://waze.com/ul?ll=$lat,$lon&navigate=yes");

    debugPrint("🧭 Google Maps URL: $googleMapsUrl");
    debugPrint("🧭 Waze URL: $wazeUrl");

    final themeProvider = context.read<ThemeProvider>();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: themeProvider.cardColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: themeProvider.borderPrimary, width: 1),
            ),
            title: Text(
              'Choose an app for navigation',
              style: TextStyle(color: themeProvider.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(context);
                      if (await canLaunchUrl(googleMapsUrl)) {
                        await launchUrl(
                          googleMapsUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _showErrorSnack();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.borderPrimary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/google_maps_logo.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Google Maps',
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(context);
                      if (await canLaunchUrl(wazeUrl)) {
                        await launchUrl(
                          wazeUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _showErrorSnack();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.borderPrimary,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/waze_logo.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Waze',
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorSnack() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to launch navigation')),
    );
  }

  void _focusOnCourse(String courseName) {
    final locations = _courseLocations[courseName];
    if (locations == null || locations.isEmpty) return;

    // 🔒 Save user preferences before focus
    final previousVisibility = Map<String, bool>.from(visibleEvents);

    // 🟡 Show only the selected course
    setState(() {
      _highlightedCourse = courseName;
      visibleEvents.updateAll((key, _) => key == courseName);
      legendVisible = false; // 👈 close the legend
    });

    // 🔓 Restore user preferences after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        visibleEvents
          ..clear()
          ..addAll(previousVisibility); // ✅ Restore exact visibility
        _highlightedCourse = null;
      });
    });

    if (locations.length == 1) {
      _mapController.move(locations.first, 16.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(locations);
    final latDelta = (bounds.north - bounds.south).abs();
    final lonDelta = (bounds.east - bounds.west).abs();

    if (latDelta < 0.0002 && lonDelta < 0.0002) {
      _mapController.move(bounds.center, 18.0);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
    }
  }

  Future<LatLng?> fetchCoordinates(String buildingName) async {
    // 1. Check manual override
    if (manualBuildingCoordinates.containsKey(buildingName)) {
      debugPrint('📍 Manual override for: $buildingName');
      return manualBuildingCoordinates[buildingName];
    }

    final normalizedQuery = getHebrewBuildingQuery(buildingName);
    // 2. Check cached geocode
    if (_geoService.containsKey(normalizedQuery)) {
      debugPrint('✅ Cache hit for: $normalizedQuery');
      return _geoService.get(normalizedQuery);
    } else {
      debugPrint('❌ Cache miss for: $normalizedQuery');
    }

    // 3. Fallback to online geocoding
    final query = Uri.encodeComponent(normalizedQuery);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    final headers = {'User-Agent': 'DegreEZApp/1.0 (contact@degreez.app)'};

    try {
      final response = await http.get(url, headers: headers);
      if (!mounted) return null;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final latlng = LatLng(lat, lon);
          _geoService.put(normalizedQuery, latlng);

          return latlng;
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _geoService.loadCache().then((_) async {
      await _getUserLocation(); // ask once
      await _loadCourseMarkers(); // then load pins
      if (!mounted) return;
      setState(() => isLoading = false);
    });
  }

  Future<void> _getUserLocation() async {
    // 1. Make sure the service is on & we have permission
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) return;
    }
    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted) {
        return;
      }
    }

    // 2. Try to get the very next GPS update, but don’t wait forever.
    try {
      final loc = await location.onLocationChanged.first.timeout(
        const Duration(seconds: 5),
      );
      userLocation = LatLng(loc.latitude!, loc.longitude!);
      debugPrint("✅ Got a location fix from the stream: $userLocation");
    } on TimeoutException {
      debugPrint(
        "⚠️ Timeout waiting for onLocationChanged, trying getLocation()…",
      );
      // 3. Fallback: try getLocation(), but with a timeout
      try {
        final loc = await location.getLocation().timeout(
          const Duration(seconds: 3),
        );
        userLocation = LatLng(loc.latitude!, loc.longitude!);
        debugPrint("✅ Got a location from getLocation(): $userLocation");
      } on Exception catch (e) {
        debugPrint("❌ Gave up on getLocation(): $e");
      }
    }

    // 4. Now subscribe for all future updates
    _locationSubscription = location.onLocationChanged.listen((loc) {
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(loc.latitude!, loc.longitude!);
      });
    });
  }

  Future<void> _loadCourseMarkers() async {
    final courseProvider = context.read<CourseProvider>();
    final selectedCourses = courseProvider.getCoursesForSemester(
      widget.selectedSemester,
    );

    debugPrint('🗓️ Selected Semester: ${widget.selectedSemester}');
    debugPrint('📚 Courses in Semester: ${selectedCourses.length}');

    final markers = <CourseMarkerData>[];

    final semCode = _parseSemesterCode(widget.selectedSemester);
    if (semCode == null) {
      debugPrint('❌ Could not parse semester code');
      return;
    }
    final (year, semester) = semCode;
    final Map<String, Map<String, int>> courseSessionCounts = {};

    for (final course in selectedCourses) {
      if (!mounted) return;
      debugPrint('➡️ Course: \\${course.courseId} - \\${course.name}');
      final details = await CourseService.getCourseDetails(
        year,
        semester,
        course.courseId,
      );
      if (!mounted) return;
      if (details == null) {
        debugPrint('❌ No details found for course \\${course.courseId}');
        continue;
      }

      if (!courseColors.containsKey(course.name)) {
        final themeProvider = context.read<ThemeProvider>();
        courseColors[course.name] = themeProvider.getCourseColor(
          course.courseId,
        );
        colorIndex++;
      }
      final courseColor = courseColors[course.name]!;

      final entries = courseProvider.getSelectedScheduleEntries(
        course.courseId,
        details,
      );

      courseSessionCounts[course.name] = {};

      for (final type in ['lecture', 'tutorial', 'lab', 'workshop']) {
        final typeEntries = entries[type] ?? [];
        for (int i = 0; i < typeEntries.length; i++) {
          final entry = typeEntries[i];

          // Skip if building empty
          if (entry.building.trim().isEmpty) continue;

          // Label like L1, T2, etc
          final prefix =
              type == 'lecture'
                  ? 'הרצאה'
                  : type == 'tutorial'
                  ? 'תרגול'
                  : type == 'lab'
                  ? 'מעבדה'
                  : 'סדנה';

          final count1 = courseSessionCounts[course.name]!.putIfAbsent(
            prefix,
            () => 0,
          );
          courseSessionCounts[course.name]![prefix] = count1 + 1;

          final scheduleString = StudentCourse.formatScheduleString(
            entry.day,
            entry.time,
          );
          debugPrint(
            '🔍 Checking entry: ${entry.type}, ${entry.day} ${entry.time} → $scheduleString',
          );

          LatLng? baseLoc = await fetchCoordinates(entry.building);
          if (baseLoc == null) continue;

          final key = '${baseLoc.latitude},${baseLoc.longitude}';
          final count = _buildingPinCounts.putIfAbsent(key, () => 0);
          _buildingPinCounts[key] = count + 1;

          // Spread pins in a circle around the building
          const double radius = 0.00015; // ~15 meters - increased from 0.0001
          final angle =
              (count * 72) *
              (math.pi / 180); // 72° between pins for better spacing
          final offsetLat = baseLoc.latitude + radius * math.sin(angle);
          final offsetLon = baseLoc.longitude + radius * math.cos(angle);
          final loc = LatLng(offsetLat, offsetLon);

          debugPrint('🌍 Geocoded: ${entry.building} → $loc');

          visibleCourses.addAll(courseColors.keys);
          final labelCountKey = '${course.name} - ${entry.type}';
          final eventsCount = _buildingPinCounts.putIfAbsent(
            labelCountKey,
            () => 1,
          );
          final label = '${course.name} (${entry.type} $eventsCount)';
          _buildingPinCounts[labelCountKey] = eventsCount + 1;
          _courseLocations.putIfAbsent(label, () => []).add(loc);

          visibleEvents[label] = true;
          markers.add(
            CourseMarkerData(
              point: loc,
              label: label,
              color: courseColor,
              buildingName: entry.building,
              roomNumber: entry.room.toString(),
            ),
          );
          debugPrint('📌 Added marker: $label at $loc (color: $courseColor)');
        }
      }
    }

    courseMarkers = markers;
    debugPrint('📌 Total Markers: ${courseMarkers.length}');
    debugPrint('👤 User Location: $userLocation');
  }

  double? _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return '';
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
  }

  Widget _buildEnhancedMarker(
    CourseMarkerData markerData,
    bool isHighlighted,
    ThemeProvider themeProvider,
  ) {
    final distance =
        userLocation != null
            ? _calculateDistance(userLocation!, markerData.point)
            : null;

    return SizedBox(
      width: isHighlighted ? 60 : 50,
      height: isHighlighted ? 80 : 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main pin with gradient
          Container(
            width: isHighlighted ? 40 : 30,
            height: isHighlighted ? 40 : 30,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [markerData.color.withAlpha(204), markerData.color],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: themeProvider.surfaceColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withAlpha(128)
                          : Colors.black.withAlpha(76),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.school,
              color: themeProvider.surfaceColor,
              size: isHighlighted ? 20 : 16,
            ),
          ),
          // Distance badge
          if (distance != null)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor.withAlpha(230),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeProvider.borderPrimary,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _formatDistance(distance),
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Next class indicator
          if (markerData.nextClassTime != null)
            Positioned(
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _isClassSoon(markerData.nextClassTime!)
                          ? themeProvider.warningColor
                          : themeProvider.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeProvider.surfaceColor,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isClassSoon(DateTime classTime) {
    final now = DateTime.now();
    final difference = classTime.difference(now);
    return difference.inMinutes <= 30 && difference.inMinutes > 0;
  }

  Widget _buildLegendContent(ThemeProvider themeProvider) {
    final grouped = <String, List<MapEntry<String, bool>>>{};

    for (final entry in visibleEvents.entries) {
      final match = RegExp(r'^(.*) \(([^)]+)\)$').firstMatch(entry.key);
      if (match == null) continue;

      final course = match.group(1)!.trim();
      final session = match.group(2)!.trim();

      // Apply search filter to legend
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final courseMarker = courseMarkers.firstWhere(
          (marker) => marker.label == entry.key,
          orElse:
              () => CourseMarkerData(
                point: LatLng(0, 0),
                label: '',
                color: Colors.grey,
                buildingName: '',
                roomNumber: '',
              ),
        );

        if (courseMarker.label.isNotEmpty) {
          final matchesSearch =
              courseMarker.label.toLowerCase().contains(searchLower) ||
              courseMarker.buildingName.toLowerCase().contains(searchLower) ||
              courseMarker.roomNumber.toLowerCase().contains(searchLower);
          if (!matchesSearch) continue;
        }
      }

      grouped.putIfAbsent(course, () => []).add(MapEntry(session, entry.value));
    }

    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.info_outline,
              color: themeProvider.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No courses to display',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Select a semester with courses to see them on the map',
              style: TextStyle(
                color: themeProvider.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    // Optional: close legend when search is cleared from legend
                    // legendVisible = false;
                  });
                },
                child: Text(
                  'Clear Search',
                  style: TextStyle(color: themeProvider.primaryColor),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _searchQuery.isNotEmpty ? Icons.search : Icons.layers,
                color: themeProvider.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Search Results'
                      : 'Course Locations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeProvider.primaryColor.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '"$_searchQuery"',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Divider(color: themeProvider.borderPrimary, height: 1, thickness: 0.5),
        // Quick actions at the top
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final key in visibleEvents.keys) {
                        visibleEvents[key] = true;
                      }
                    });
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: 14,
                    color: themeProvider.primaryColor,
                  ),
                  label: Text(
                    'Show All',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final key in visibleEvents.keys) {
                        visibleEvents[key] = false;
                      }
                    });
                  },
                  icon: Icon(
                    Icons.visibility_off,
                    size: 14,
                    color: themeProvider.textSecondary,
                  ),
                  label: Text(
                    'Hide All',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: themeProvider.borderPrimary, height: 1, thickness: 0.5),
        const SizedBox(height: 8),
        // Course list
        ...grouped.entries.map((group) {
          final courseName = group.key;
          final sessions = group.value;
          final color = courseColors[courseName] ?? themeProvider.primaryColor;
          final visibleSessionCount = sessions.where((s) => s.value).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(51), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(76),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school,
                          color: themeProvider.surfaceColor,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: themeProvider.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$visibleSessionCount of ${sessions.length} sessions visible',
                              style: TextStyle(
                                fontSize: 11,
                                color: themeProvider.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Sessions
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    children:
                        sessions.map((sessionEntry) {
                          final label = sessionEntry.key;
                          final isVisible = sessionEntry.value;
                          final eventKey = '$courseName ($label)';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => _focusOnCourse(eventKey),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isVisible
                                            ? themeProvider.surfaceColor
                                                .withAlpha(13)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          isVisible
                                              ? color.withAlpha(76)
                                              : themeProvider.borderPrimary
                                                  .withAlpha(76),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Checkbox(
                                          value: isVisible,
                                          onChanged: (val) {
                                            setState(() {
                                              visibleEvents[eventKey] =
                                                  val ?? true;
                                            });
                                          },
                                          activeColor: color,
                                          checkColor:
                                              themeProvider.surfaceColor,
                                          side: BorderSide(
                                            color: color.withAlpha(153),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isVisible
                                                    ? themeProvider.textPrimary
                                                    : themeProvider
                                                        .textSecondary,
                                            fontWeight:
                                                isVisible
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isVisible)
                                        Icon(
                                          Icons.visibility,
                                          size: 14,
                                          color: color,
                                        )
                                      else
                                        Icon(
                                          Icons.visibility_off,
                                          size: 14,
                                          color: themeProvider.textSecondary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionsPanel(ThemeProvider themeProvider) {
    if (userLocation == null || courseMarkers.isEmpty) return const SizedBox();

    final nextClass = _getNextClass();
    final nearbyClasses = _getNearbyClasses();

    return Stack(
      children: [
        // Next class button - positioned at bottom left
        if (nextClass != null)
          Positioned(
            bottom: 20,
            left: 20,
            child: NextClassButton(
              courseName: nextClass.label,
              buildingName: nextClass.buildingName,
              roomNumber: nextClass.roomNumber,
              courseColor: nextClass.color,
              themeProvider: themeProvider,
              onTap: () => _showNextClassDialog(nextClass, themeProvider),
            ),
          ),

        // Nearby classes - positioned at bottom right
        if (nearbyClasses.isNotEmpty)
          Positioned(
            bottom: 100,
            right: 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    nearbyClasses
                        .map(
                          (marker) =>
                              _buildNearbyClassChip(marker, themeProvider),
                        )
                        .toList(),
              ),
            ),
          ),
      ],
    );
  }

  CourseMarkerData? _getNextClass() {
    // This would integrate with your calendar/schedule data
    // For now, return the closest visible marker
    if (userLocation == null) return null;

    final visibleMarkers =
        courseMarkers
            .where((marker) => visibleEvents[marker.label] ?? false)
            .toList();

    if (visibleMarkers.isEmpty) return null;

    visibleMarkers.sort((a, b) {
      final distA =
          _calculateDistance(userLocation!, a.point) ?? double.infinity;
      final distB =
          _calculateDistance(userLocation!, b.point) ?? double.infinity;
      return distA.compareTo(distB);
    });

    return visibleMarkers.first;
  }

  List<CourseMarkerData> _getNearbyClasses() {
    if (userLocation == null) return [];

    return courseMarkers
        .where((marker) {
          final distance = _calculateDistance(userLocation!, marker.point);
          return distance != null && distance <= 200; // Within 200m
        })
        .take(3)
        .toList();
  }

  void _showNextClassDialog(
    CourseMarkerData nextClass,
    ThemeProvider themeProvider,
  ) {
    final distance = _calculateDistance(userLocation!, nextClass.point);
    final walkingTime = distance != null ? (distance * 12).round() : 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: themeProvider.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.schedule, color: nextClass.color, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Next Class',
                  style: TextStyle(
                    color: themeProvider.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: nextClass.color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: nextClass.color.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextClass.label.split('(').first.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (nextClass.label.contains('(')) ...[
                        Text(
                          nextClass.label.split('(')[1].replaceAll(')', ''),
                          style: TextStyle(
                            color: themeProvider.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: nextClass.color,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDistance(distance)} • $walkingTime min walk',
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: themeProvider.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextClass.color,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchNavigation(nextClass.point);
                },
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Navigate'),
              ),
            ],
          ),
    );
  }

  Widget _buildNearbyClassChip(
    CourseMarkerData marker,
    ThemeProvider themeProvider,
  ) {
    final distance = _calculateDistance(userLocation!, marker.point);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _focusOnCourse(marker.label),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          color: marker.color.withAlpha(26),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: marker.color, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  marker.buildingName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: marker.color,
                  ),
                ),
                Text(
                  _formatDistance(distance),
                  style: TextStyle(
                    fontSize: 8,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeProvider themeProvider) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeProvider.borderPrimary, width: 1),
          boxShadow: [
            BoxShadow(
              color:
                  themeProvider.isDarkMode
                      ? Colors.black.withAlpha(76)
                      : Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: themeProvider.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search courses, buildings, or rooms...',
            hintStyle: TextStyle(color: themeProvider.textSecondary),
            prefixIcon: Icon(Icons.search, color: themeProvider.textSecondary),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: themeProvider.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          // Optional: close legend when search is cleared
                          // legendVisible = false;
                        });
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();

              // Auto-open legend when user starts searching
              if (_searchQuery.isNotEmpty && !legendVisible) {
                legendVisible = true;
              }
              // Auto-close legend when search is cleared
              else if (_searchQuery.isEmpty && legendVisible) {
                // Optional: you can remove this line if you want legend to stay open
                // legendVisible = false;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: context.read<ThemeProvider>().mainColor,
        body: Center(
          child: CircularProgressIndicator(
            color: context.read<ThemeProvider>().primaryColor,
          ),
        ),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.mainColor,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds(
                      LatLng(32.774, 35.020), // Southwest corner of Technion
                      LatLng(32.779, 35.025), // Northeast corner of Technion
                    ),
                    padding: const EdgeInsets.all(40),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.degreez',
                  ),
                  MarkerLayer(
                    markers: [
                      ...courseMarkers
                          .where((cm) {
                            // Check visibility
                            final isVisible = visibleEvents[cm.label] ?? true;
                            if (!isVisible) return false;

                            // Apply search filter
                            if (_searchQuery.isNotEmpty) {
                              final searchLower = _searchQuery.toLowerCase();
                              return cm.label.toLowerCase().contains(
                                    searchLower,
                                  ) ||
                                  cm.buildingName.toLowerCase().contains(
                                    searchLower,
                                  ) ||
                                  cm.roomNumber.toLowerCase().contains(
                                    searchLower,
                                  );
                            }

                            return true;
                          })
                          .map((cm) {
                            final courseName = cm.label.split('(').first.trim();
                            final isHighlighted =
                                courseName == _highlightedCourse;

                            return Marker(
                              point: cm.point,
                              width: isHighlighted ? 50 : 40,
                              height: isHighlighted ? 50 : 40,
                              child: Tooltip(
                                message:
                                    '${cm.label}\n${cm.buildingName} - Room ${cm.roomNumber}',
                                child: GestureDetector(
                                  onTap: () => _launchNavigation(cm.point),
                                  child: _buildEnhancedMarker(
                                    cm,
                                    isHighlighted,
                                    themeProvider,
                                  ),
                                ),
                              ),
                            );
                          }),
                      // 👤 Add user location marker here
                      if (userLocation != null)
                        Marker(
                          point: userLocation!,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeProvider.surfaceColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.primaryColor.withAlpha(
                                    75,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              color: themeProvider.surfaceColor,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              _buildSearchAndFilters(themeProvider),
              Positioned(
                top: 80,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 4,
                        backgroundColor: themeProvider.cardColor,
                        foregroundColor: themeProvider.textPrimary,
                        side: BorderSide(
                          color: themeProvider.borderPrimary,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed:
                          () => setState(() => legendVisible = !legendVisible),
                      child: Text(
                        legendVisible ? 'Hide Legend' : 'Show Legend',
                      ),
                    ),
                    if (legendVisible)
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: themeProvider.cardColor,
                        child: Container(
                          width: 280,
                          constraints: const BoxConstraints(maxHeight: 400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeProvider.borderPrimary,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              child: _buildLegendContent(themeProvider),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildQuickActionsPanel(themeProvider),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: themeProvider.primaryColor,
            foregroundColor:
                themeProvider.isLightMode
                    ? themeProvider.surfaceColor
                    : themeProvider.secondaryColor,
            tooltip: 'Center on me',
            elevation: 6,
            child: const Icon(Icons.my_location),
            onPressed: () {
              if (userLocation != null) {
                // move instantly to user, zoom level 16.0 (tweak as you like)
                _mapController.move(userLocation!, 16.0);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Location not available yet',
                      style: TextStyle(color: themeProvider.textPrimary),
                    ),
                    backgroundColor: themeProvider.cardColor,
                  ),
                );
              }
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant CourseMapPage old) {
    super.didUpdateWidget(old);
    if (widget.selectedSemester != old.selectedSemester) {
      debugPrint('🔄 Semester changed, reloading markers…');
      setState(() {
        isLoading = true;
        courseMarkers.clear();
        visibleEvents.clear();
        _buildingPinCounts.clear();
        _courseLocations.clear();
      });
      // Just reload your pins:
      _loadCourseMarkers().then((_) {
        if (!mounted) return;
        setState(() => isLoading = false);
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
