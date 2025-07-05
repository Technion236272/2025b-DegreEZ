import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';

class PrerequisiteGraph extends StatelessWidget {
  final String rootCourseId;
  final Map<String, String> courseNames;
  final Map<String, String> courseFaculties;
  final Map<String, List<Map<String, List<String>>>> coursePrereqs;

  const PrerequisiteGraph({
    super.key,
    required this.rootCourseId,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
  });

  @override
  Widget build(BuildContext context) {
    final studentFaculty =
        context.read<StudentProvider>().student?.faculty ?? 'Unknown';

    final graph = Graph();
    final nodeMap = <String, Node>{};

    Node getNode(String courseId) {
      return nodeMap.putIfAbsent(
        courseId,
        () => Node.Id(courseId),
      );
    }

    void buildGraph(String courseId, Set<String> visited) {
      if (visited.contains(courseId)) return;
      visited.add(courseId);

      final enriched = coursePrereqs[courseId];
      if (enriched == null || enriched.isEmpty) return;

      // Filter valid groups
      final validGroups = enriched.where((group) {
        final allIds = group.entries.expand((e) => e.value);
        return allIds.every((id) => courseNames.containsKey(id));
      }).toList();

      if (validGroups.isEmpty) return;

      validGroups.sort((a, b) {
        int count(String id) => courseFaculties[id] == studentFaculty ? 1 : 0;
        final aScore = a.entries.expand((e) => e.value).map(count).fold(0, (a, b) => a + b);
        final bScore = b.entries.expand((e) => e.value).map(count).fold(0, (a, b) => a + b);
        return bScore.compareTo(aScore);
      });

      final bestGroup = validGroups.first;
      final childIds = bestGroup.entries.expand((e) => e.value);

      for (final child in childIds) {
        graph.addEdge(getNode(courseId), getNode(child));
        buildGraph(child, {...visited});
      }
    }

    buildGraph(rootCourseId, {});

    final builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = (30)
      ..levelSeparation = (40)
      ..subtreeSeparation = (30)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

return SizedBox(
  width: double.infinity,
  height: 600, // or any fixed height you want
  child: InteractiveViewer(
    constrained: false,
    boundaryMargin: const EdgeInsets.all(100),
    minScale: 0.01,
    maxScale: 5.0,
    child: GraphView(
      graph: graph,
      algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
      builder: (node) {
        final id = node.key!.value as String;
        return _buildCourseBox(courseNames[id] ?? id);
      },
    ),
  ),
);


  }

  Widget _buildCourseBox(String title) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade100,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title, textAlign: TextAlign.center),
    );
  }
}
