import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// Widget that renders separate prerequisite graphs for each OR path,
/// recursively splitting OR groups at all levels, and filtering groups
/// to those with the highest count of courses from the student's faculty.
class PrerequisiteGraph extends StatelessWidget {
  final String rootCourseId;
  final String studentFaculty;
  final Map<String, String> courseNames;
  final Map<String, String> courseFaculties;
  final Map<String, List<Map<String, List<String>>>> coursePrereqs;

  const PrerequisiteGraph({
    super.key,
    required this.rootCourseId,
    required this.studentFaculty,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('PrerequisiteGraph: building for root $rootCourseId');
    debugPrint('Full courseFaculties map: $courseFaculties');
    final initialState = _GraphState()..addNode(rootCourseId);
    final allStates = _buildStatesFrom(rootCourseId, [initialState], <String>{});

    if (allStates.isEmpty) {
      return const Text('No valid prerequisite graphs found.');
    }

    final builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 30
      ..levelSeparation = 40
      ..subtreeSeparation = 30
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ListView.builder(
        itemCount: allStates.length,
        itemBuilder: (context, index) {
          final state = allStates[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Path ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 800,
                  child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.01,
                    maxScale: 5.0,
                    child: GraphView(
                      graph: state.graph,
                      algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                      builder: (node) {
                        final id = node.key!.value as String;
                        return _buildCourseBox(courseNames[id] ?? id);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Recursively builds graph states for each OR-path at [currentId], filtering groups
  /// to those with the most courses in [studentFaculty].
  List<_GraphState> _buildStatesFrom(
    String currentId,
    List<_GraphState> states,
    Set<String> visited,
  ) {
    debugPrint('Building states for $currentId, visited=$visited');
    debugPrint('Student faculty: $studentFaculty');
    if (visited.contains(currentId)) return states;
    final nextVisited = {...visited, currentId};

    final groups = coursePrereqs[currentId];
    debugPrint('groups for $currentId: $groups');
    if (groups == null || groups.isEmpty) {
      return states;
    }

    // Keep only groups where all courses have known names
    var validGroups = groups.where((grp) {
      final ids = grp.values.expand((list) => list);
      return ids.every(courseNames.containsKey);
    }).toList();
    debugPrint('validGroups (pre-score) for $currentId: $validGroups');

    if (validGroups.isEmpty) {
      return states;
    }

    // Score each group by how many courses belong to the student's faculty
    final scores = validGroups.map((grp) {
      final ids = grp.values.expand((list) => list).toList();
      for (final cid in ids) {
        debugPrint('Faculty of $cid = ${courseFaculties[cid]}');
      }
      // Use contains to match substring
      return ids.where((cid) =>
        courseFaculties[cid]?.contains(studentFaculty) ?? false
      ).length;
    }).toList();
    debugPrint('scores for $currentId: $scores');

    final maxScore = scores.isNotEmpty
        ? scores.reduce((a, b) => a > b ? a : b)
        : 0;
    debugPrint('maxScore for $currentId: $maxScore');

    validGroups = [
      for (int i = 0; i < validGroups.length; i++)
        if (scores[i] == maxScore) validGroups[i]
    ];
    debugPrint('validGroups (post-score) for $currentId: $validGroups');

    final List<_GraphState> result = [];

    for (final state in states) {
      for (final grp in validGroups) {
        final cloned = _GraphState.clone(state);
        final children = grp.values.expand((list) => list);

        // Add edges for this AND-group
        for (final cid in children) {
          debugPrint('Adding edge $currentId -> $cid');
          cloned.addEdge(currentId, cid);
        }

        // Recursively process each child
        var branchStates = [cloned];
        for (final cid in children) {
          branchStates = branchStates
              .expand((st) => _buildStatesFrom(cid, [st], nextVisited))
              .toList();
        }
        result.addAll(branchStates);
      }
    }

    return result;
  }

  /// Simple course box UI
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

/// Holds a Graph and mapping from courseId -> Node
class _GraphState {
  final Graph graph;
  final Map<String, Node> nodeMap;

  _GraphState()
      : graph = Graph(),
        nodeMap = {};

  /// Deep clone constructor
  _GraphState.clone(_GraphState other)
      : graph = Graph(),
        nodeMap = {} {
    for (final id in other.nodeMap.keys) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
    }
    for (final edge in other.graph.edges) {
      final srcId = edge.source.key!.value as String;
      final dstId = edge.destination.key!.value as String;
      graph.addEdge(nodeMap[srcId]!, nodeMap[dstId]!);
    }
  }

  /// Add node if not present
  void addNode(String id) {
    if (!nodeMap.containsKey(id)) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
    }
  }

  /// Add edge, auto-adding nodes if needed
  void addEdge(String srcId, String dstId) {
    addNode(srcId);
    addNode(dstId);
    graph.addEdge(nodeMap[srcId]!, nodeMap[dstId]!);
  }
}
