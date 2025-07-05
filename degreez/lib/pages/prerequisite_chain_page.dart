import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../services/course_service.dart';
import '../widgets/add_course_dialog.dart';
import '../widgets/prerequisite_graph.dart';
import '../services/global_config_service.dart';

class PrerequisiteChainPage extends StatefulWidget {
  const PrerequisiteChainPage({super.key});

  @override
  State<PrerequisiteChainPage> createState() => _PrerequisiteChainPageState();
}

class _PrerequisiteChainPageState extends State<PrerequisiteChainPage> {
  final TextEditingController _searchController = TextEditingController();

  List<CourseSearchResult> searchResults = [];
  EnhancedCourseDetails? selectedCourse;
  List<Map<String, List<String>>> enrichedPrereqs = [];
  List<String> missingIds = [];
  Map<String, String> courseIdToName = {};
  Map<String, String> courseFaculties = {};
  Map<String, List<Map<String, List<String>>>> coursePrereqs = {};

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Course Prerequisite Chain")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            if (isLoading)
              const CircularProgressIndicator()
            else if (searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Text("No matching courses found."),
            if (searchResults.isNotEmpty) _buildSearchResults(),
            const SizedBox(height: 16),
            if (selectedCourse != null && coursePrereqs.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: PrerequisiteGraph(
                    rootCourseId: selectedCourse!.courseNumber,
                    courseNames: courseIdToName,
                    courseFaculties: courseFaculties,
                    coursePrereqs: coursePrereqs,
                  ),
                ),
              ),

            if (selectedCourse != null && enrichedPrereqs.isEmpty)
              const Text("No prerequisites for this course."),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search by course ID or name',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        if (value.length >= 3) _search(value);
      },
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final result = searchResults[index];
          final course = result.course;

          return ListTile(
            title: Text('${course.courseNumber} - ${course.name}'),
            subtitle: Text('${course.points} credits • ${course.faculty}'),
            onTap: () async {
              await _handleCourseSelected(course);
            },
          );
        },
      ),
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      isLoading = true;
      searchResults = [];
    });

    final isId = RegExp(r'^\d+$').hasMatch(query);
    final courseId = isId ? query : null;
    final courseName = isId ? null : query;

    final results = await context
        .read<CourseProvider>()
        .searchInLatestAvailableSemesters(
          count: 4,
          courseId: courseId,
          courseName: courseName,
        );

    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  Future<void> _handleCourseSelected(EnhancedCourseDetails course) async {
    debugPrint('Selected course: ${course.courseNumber} - ${course.name}');
    debugPrint('Prerequisites: ${course.prerequisites}');
    final parsed = _parsePrerequisites(course.prerequisites);
    debugPrint('Parsed prerequisites: $parsed');
    final flattened = _flattenEnriched(parsed);
    debugPrint('Flattened prerequisites: $flattened');
    final courseProvider = context.read<CourseProvider>();

    final takenCourseIds =
        courseProvider.sortedCoursesBySemester.values
            .expand((s) => s)
            .map((c) => c.courseId)
            .toSet();

final allMentioned = flattened.expand((e) => e).toSet();

    debugPrint('All mentioned course IDs: $allMentioned');

    final nameMap = {
      for (var c in courseProvider.sortedCoursesBySemester.values.expand(
        (x) => x,
      ))
        c.courseId: c.name,
    };

    for (final id in allMentioned) {
      if (!nameMap.containsKey(id)) {
        final resolved = await CourseService.getCourseName(id);
        nameMap[id] = resolved ?? ' Unknown';
      }
    }
    debugPrint('Course ID to name map: $nameMap');

    final missing = <String>{
      for (final group in flattened)
        if (!group.every(takenCourseIds.contains))
          ...group.where((id) => !takenCourseIds.contains(id)),
    };

    setState(() {
      selectedCourse = course;
      enrichedPrereqs = parsed;
      courseIdToName = nameMap;
      missingIds = missing.toList();
      searchResults = []; // ✅ clear result list after selection
      _searchController.clear(); // ✅ clear input field
    });
    await _buildRecursiveData(course.courseNumber);
  }

  List<Map<String, List<String>>> _parsePrerequisites(dynamic raw) {
    if (raw is List) {
      try {
        return raw
            .cast<Map>()
            .map(
              (e) => Map<String, List<String>>.from(
                e.map((k, v) => MapEntry(k as String, List<String>.from(v))),
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('⚠️ Failed to parse enriched prerequisites: $e');
        return [];
      }
    } else if (raw is String) {
      return context
          .read<CourseProvider>()
          .parseRawPrerequisites(raw)
          .map((g) => {'and': g})
          .toList();
    }
    return [];
  }

List<List<String>> _flattenEnriched(List<Map<String, List<String>>> enriched) {
  return enriched.map((group) {
    final flat = <String>[];
    for (final entry in group.entries) {
      // ✅ Only add key if it looks like a course ID (i.e., 8 digits)
      if (_isCourseId(entry.key)) flat.add(entry.key.trim());
      for (final v in entry.value) {
        if (_isCourseId(v)) flat.add(v.trim());
      }
    }
    return flat;
  }).toList();
}



  bool _isCourseId(String id) => RegExp(r'^\d{8}$').hasMatch(id);

  Future<void> _buildRecursiveData(String rootId) async {
    final visited = <String>{};
    final queue = <String>[rootId];
    final prereqMap = <String, List<Map<String, List<String>>>>{};
    final nameMap = <String, String>{};
    final facultyMap = <String, String>{};

    final semesters = await GlobalConfigService.getAvailableSemesters();
    semesters.sort((a, b) {
      int getSortYear(String semesterName) {
        final parts = semesterName.split(' ');
        final yearPart = parts.length > 1 ? parts[1] : '';

        if (yearPart.contains('-')) {
          final years = yearPart.split('-');
          return int.tryParse(years.last) ?? 0; // Use later year
        }
        return int.tryParse(yearPart) ?? 0;
      }

      int getSeasonOrder(String semesterName) {
        final season = semesterName.split(' ').first;
        const order = {'Winter': 0, 'Spring': 1, 'Summer': 2};
        return order[season] ?? 99;
      }

      final yearA = getSortYear(a);
      final yearB = getSortYear(b);
      if (yearA != yearB) return yearA.compareTo(yearB);

      final seasonA = getSeasonOrder(a);
      final seasonB = getSeasonOrder(b);
      return seasonA.compareTo(seasonB);
    });
    final latest = semesters.reversed;
    debugPrint('Available semesters: $semesters');
    debugPrint('Latest semesters: $latest');

    while (queue.isNotEmpty) {
      final courseId = queue.removeLast();
      if (visited.contains(courseId)) continue;
      visited.add(courseId);

      for (final sem in latest) {
        final parsed = CourseProvider().parseSemesterCode(sem);
        if (parsed == null) continue;
        final (year, semCode) = parsed;

        final details = await CourseService.getCourseDetails(
          year,
          semCode,
          courseId,
        );
        if (details == null) continue;
        debugPrint("Found course $courseId in semester $sem: $details");

        nameMap[courseId] = details.name;
        facultyMap[courseId] = details.faculty;

        final enriched = _parsePrerequisites(details.prerequisites);
        prereqMap[courseId] = enriched;
        debugPrint('Enriched prerequisites for $courseId: $enriched');
        for (final group in enriched) {
          for (final id in group.entries.expand((e) => [e.key, ...e.value])) {
            if (_isCourseId(id) && !visited.contains(id)) {
              queue.add(id);
            }
          }
        }

        debugPrint('Queue after processing $courseId: $queue');

        break; // Found the course in the most recent semester, stop
      }
    }

    setState(() {
      courseIdToName = nameMap;
      courseFaculties = facultyMap;
      coursePrereqs = prereqMap;
    });
  }
}
