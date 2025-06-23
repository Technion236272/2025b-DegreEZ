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

class CourseMapPage extends StatefulWidget {
  final String selectedSemester;

  const CourseMapPage({super.key, required this.selectedSemester});

  @override
  State<CourseMapPage> createState() => _CourseMapPageState();
}

class _CourseMapPageState extends State<CourseMapPage> {
  LatLng? userLocation;
  List<Marker> courseMarkers = [];
  bool isLoading = true;
  final _geoService = GeocodeCacheService();
  final Map<String, Color> courseColors = {};
  bool legendVisible = true;
  final Map<String, int> _buildingPinCounts = {};
  final double _offsetStep = 0.00005; // About 5 meters
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
    final location = Location();
    if (!await location.serviceEnabled()) await location.requestService();
    if (await location.hasPermission() == PermissionStatus.denied) {
      if (await location.requestPermission() != PermissionStatus.granted)
        return;
    }

    final loc = await location.getLocation();
    if (loc.latitude != null && loc.longitude != null) {
      userLocation = LatLng(loc.latitude!, loc.longitude!);
    }
  }

  Future<void> _loadCourseMarkers() async {
    final courseProvider = context.read<CourseProvider>();
    final selectedCourses = courseProvider.getCoursesForSemester(
      widget.selectedSemester,
    );

    debugPrint('🗓️ Selected Semester: ${widget.selectedSemester}');
    debugPrint('📚 Courses in Semester: ${selectedCourses.length}');

    final markers = <Marker>[];

    final semCode = _parseSemesterCode(widget.selectedSemester);
    if (semCode == null) {
      debugPrint('❌ Could not parse semester code');
      return;
    }
    final (year, semester) = semCode;

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

      // Assign a color if not already assigned
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
      for (final type in ['lecture', 'tutorial', 'lab', 'workshop']) {
        for (final entry in entries[type] ?? []) {
          final scheduleString = StudentCourse.formatScheduleString(
            entry.day,
            entry.time,
          );
          debugPrint(
            '🔍 Checking entry: ${entry.type}, ${entry.day} ${entry.time} → $scheduleString',
          );

          if (entry.building.trim().isEmpty) continue;

          LatLng? baseLoc = await fetchCoordinates(entry.building);
          if (baseLoc == null) continue;

          // Track how many pins already placed at this building
          final key = '${baseLoc.latitude},${baseLoc.longitude}';
          final count = _buildingPinCounts.putIfAbsent(key, () => 0);

          // Offset slightly based on count
          final offsetLat = baseLoc.latitude + (count * _offsetStep);
          final offsetLon = baseLoc.longitude + (count * _offsetStep);
          final loc = LatLng(offsetLat, offsetLon);

          // Increment count for next pin at this building
          _buildingPinCounts[key] = count + 1;

          debugPrint('🌍 Geocoded: ${entry.building} → $loc');

          if (loc != null) {
            markers.add(
              Marker(
                point: loc,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${course.name} (${entry.type})',
                  child: Icon(Icons.location_on, color: courseColor),
                ),
              ),
            );
          }
        }
      }
    }

    courseMarkers = markers;
    debugPrint('📌 Total Markers: ${courseMarkers.length}');
    debugPrint('👤 User Location: $userLocation');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userLocation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allPoints = [...courseMarkers.map((m) => m.point), userLocation!];

    return Scaffold(
      appBar: AppBar(title: const Text('Course Map')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit:
                  allPoints.length >= 2
                      ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(allPoints),
                        padding: const EdgeInsets.all(40),
                      )
                      : CameraFit.bounds(
                        bounds: LatLngBounds(
                          LatLng(32.775, 35.021),
                          LatLng(32.778, 35.025),
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
                markers: [
                  ...courseMarkers,
                  Marker(
                    point: userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                    ),
                  ),
                ],
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      legendVisible = !legendVisible;
                    });
                  },
                  child: Text(legendVisible ? 'Hide Legend' : 'Show Legend'),
                ),
                const SizedBox(height: 8),
                if (legendVisible)
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 200,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            courseColors.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      color: entry.value,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
}
