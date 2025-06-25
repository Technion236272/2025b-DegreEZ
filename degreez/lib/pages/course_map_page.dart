import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/course_provider.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';
import '../services/geocode_cache_service.dart';
import '../services/building_geocode_map.dart';
import 'dart:math' as Math;
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseMarkerData {
  final LatLng point;
  final String label;
  final Color color;

  CourseMarkerData({
    required this.point,
    required this.label,
    required this.color,
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
  late final StreamSubscription<LocationData> _locationSubscription;
  final Location location = Location(); // reuse this across the widget

  int colorIndex = 0;
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
  ];

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

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose an app for navigation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Image.asset(
                    'assets/google_maps_logo.png',
                    width: 30,
                    height: 30,
                  ),
                  title: const Text('Google Maps'),
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
                ),
                ListTile(
                  leading: Image.asset(
                    'assets/waze_logo.png',
                    width: 30,
                    height: 30,
                  ),
                  title: const Text('Waze'),
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
      print('Geocoding error: $e');
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _geoService.loadCache().then((_) => _initializeMapData());
  }

  Future<void> _initializeMapData() async {
    await _getUserLocation();
    await _loadCourseMarkers();
    setState(() => isLoading = false);
  }

  Future<void> _getUserLocation() async {
    if (!await location.serviceEnabled()) await location.requestService();
    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted)
        return;
    }

    // Get initial location
    final loc = await location.getLocation();
    if (loc.latitude != null && loc.longitude != null) {
      setState(() {
        userLocation = LatLng(loc.latitude!, loc.longitude!);
      });
    }

    // Start listening for updates
    _locationSubscription = location.onLocationChanged.listen((newLoc) {
      if (!mounted) return;
      setState(() {
        userLocation = LatLng(newLoc.latitude!, newLoc.longitude!);
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
      debugPrint('➡️ Course: ${course.courseId} - ${course.name}');
      final details = await CourseService.getCourseDetails(
        year,
        semester,
        course.courseId,
      );
      if (details == null) {
        debugPrint('❌ No details found for course ${course.courseId}');
        continue;
      }

      if (!courseColors.containsKey(course.name)) {
        courseColors[course.name] =
            availableColors[colorIndex % availableColors.length];
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
          const double radius = 0.00005; // ~5 meters
          final angle = (count * 45) * (Math.pi / 180); // 45°, 90°, etc
          final offsetLat = baseLoc.latitude + radius * Math.sin(angle);
          final offsetLon = baseLoc.longitude + radius * Math.cos(angle);
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
            CourseMarkerData(point: loc, label: label, color: courseColor),
          );
          debugPrint('📌 Added marker: $label at $loc (color: $courseColor)');
        }
      }
    }

    courseMarkers = markers;
    debugPrint('📌 Total Markers: ${courseMarkers.length}');
    debugPrint('👤 User Location: $userLocation');
  }

  Widget _buildLegendContent() {
    final grouped = <String, List<MapEntry<String, bool>>>{};

    for (final entry in visibleEvents.entries) {
      final match = RegExp(r'^(.*) \(([^)]+)\)$').firstMatch(entry.key);
      if (match == null) continue;

      final course = match.group(1)!.trim();
      final session = match.group(2)!.trim();
      grouped.putIfAbsent(course, () => []).add(MapEntry(session, entry.value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          grouped.entries.map((group) {
            final courseName = group.key;
            final sessions = group.value;
            final color = courseColors[courseName] ?? Colors.grey;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: color),
                      const SizedBox(width: 6),
                      Text(
                        courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        sessions.map((sessionEntry) {
                          final label = sessionEntry.key;
                          final isVisible = sessionEntry.value;
                          final eventKey = '$courseName ($label)';

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isVisible,
                                onChanged: (val) {
                                  setState(() {
                                    visibleEvents[eventKey] = val ?? true;
                                  });
                                },
                              ),
                              GestureDetector(
                                onTap: () => _focusOnCourse(eventKey),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allPoints = [...courseMarkers.map((m) => m.point), userLocation!];

    return Scaffold(
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.degreez',
              ),
              MarkerLayer(
                markers:
                    courseMarkers
                        .where((cm) => visibleEvents[cm.label] ?? true)
                        .map((cm) {
                          final courseName = cm.label.split('(').first.trim();
                          final isHighlighted =
                              courseName == _highlightedCourse;

                          return Marker(
                            point: cm.point,
                            width: isHighlighted ? 50 : 40,
                            height: isHighlighted ? 50 : 40,
                            child: Tooltip(
                              message: cm.label,
                              child: GestureDetector(
                                onTap: () => _launchNavigation(cm.point),
                                child: Icon(
                                  Icons.location_on,
                                  color: cm.color,
                                  size: isHighlighted ? 40 : 30,
                                  shadows:
                                      isHighlighted
                                          ? [
                                            const Shadow(
                                              color: Colors.black,
                                              blurRadius: 10,
                                            ),
                                          ]
                                          : [],
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed:
                      () => setState(() => legendVisible = !legendVisible),
                  child: Text(legendVisible ? 'Hide Legend' : 'Show Legend'),
                ),
                if (legendVisible)
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.95),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: _buildLegendContent(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }
}
