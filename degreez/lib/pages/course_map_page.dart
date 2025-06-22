import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../models/student_model.dart';
import '../services/course_service.dart';

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

  String _normalizeBuildingName(String raw) {
    if (raw.contains('טאוב')) return 'Taub';
    if (raw.contains('אולמן')) return 'Ullman';
    if (raw.contains('מאייר')) return 'Meyer';
    if (raw.contains('עמדו')) return 'Amado';
    if (raw.contains('דדו')) return 'Dado';
    return raw; // fallback
  }

  final Map<String, LatLng> buildingCoordinates = {
    'Taub': LatLng(32.7777, 35.0219),
    'Ullman': LatLng(32.777143, 35.023714),
    'Meyer': LatLng(32.7751, 35.0222),
    'Amado': LatLng(32.7748, 35.0226),
    'Dado': LatLng(32.7762, 35.0241),
  };

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

  @override
  void initState() {
    super.initState();
    _initializeMapData();
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

      final entries = courseProvider.getSelectedScheduleEntries(
        course.courseId,
        details,
      );

      if (entries.values.every((list) => list.isEmpty)) {
        debugPrint('⚠️ No matched schedule entries for ${course.name}');
        debugPrint('🧾 lectureTime: ${course.lectureTime}');
        debugPrint('🧾 tutorialTime: ${course.tutorialTime}');
        debugPrint('🧾 labTime: ${course.labTime}');
        debugPrint('🧾 workshopTime: ${course.workshopTime}');
        debugPrint('📅 Course schedule from API:');
        for (final e in details.schedule) {
          debugPrint(
            '  - ${e.type} ${e.group} | ${e.day} ${e.time} @ ${e.building}',
          );
        }
      }

      for (final type in ['lecture', 'tutorial', 'lab', 'workshop']) {
        for (final entry in entries[type] ?? []) {
          final scheduleString = StudentCourse.formatScheduleString(
            entry.day,
            entry.time,
          );
          debugPrint(
            '🔍 Checking entry: ${entry.type}, ${entry.day} ${entry.time} → $scheduleString',
          );
          final normalized = _normalizeBuildingName(entry.building);
          final loc = buildingCoordinates[normalized];
          debugPrint('📍 Building: ${entry.building}, Found LatLng: $loc');

          if (loc != null) {
            markers.add(
              Marker(
                point: loc,
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${course.name} (${entry.type})',
                  child: const Icon(Icons.location_on, color: Colors.red),
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
      body: FlutterMap(
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
                child: const Icon(Icons.person_pin_circle, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
