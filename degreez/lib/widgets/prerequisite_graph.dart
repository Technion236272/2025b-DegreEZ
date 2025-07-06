import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class PrerequisiteGraph extends StatefulWidget {
  final String rootCourseId;
  final String studentFaculty;
  final Map<String, String> courseNames;
  final Map<String, String> courseFaculties;
  final Map<String, List<Map<String, List<String>>>> coursePrereqs;

  const PrerequisiteGraph({
    Key? key,
    required this.rootCourseId,
    required this.studentFaculty,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
  }) : super(key: key);

  @override
  _PrerequisiteGraphState createState() => _PrerequisiteGraphState();
}

class _PrerequisiteGraphState extends State<PrerequisiteGraph> {
  late final List<_GraphState> _allStates;
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // Build all the graph states just once
    final initial = _GraphState()..addNode(widget.rootCourseId);
    _allStates = _buildStatesFrom(widget.rootCourseId, [initial], <String>{});
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_allStates.isEmpty) {
      return const Center(child: Text('No valid prerequisite graphs found.'));
    }

    // Layout configuration for Buchheim-Walker
    final builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 30
      ..levelSeparation = 40
      ..subtreeSeparation = 30
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    return Column(
      children: [
        // 1) The PageView that shows one graph at a time
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allStates.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) {
              final graphState = _allStates[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.0,
                  child: GraphView(
                    graph: graphState.graph,
                    algorithm: BuchheimWalkerAlgorithm(
                      builder,
                      TreeEdgeRenderer(builder),
                    ),
                    builder: (node) {
                      final id = node.key!.value as String;
                      return _buildCourseBox(widget.courseNames[id] ?? id);
                    },
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 2) The scrollable panel of buttons for jumping to any graph
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(_allStates.length, (i) {
              final selected = i == _current;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    foregroundColor:
                        selected ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text('Graph ${i + 1}'),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  List<_GraphState> _buildStatesFrom(
    String currentId,
    List<_GraphState> states,
    Set<String> visited,
  ) {
    if (visited.contains(currentId)) return states;
    final nextVisited = {...visited, currentId};
    final groups = widget.coursePrereqs[currentId];
    if (groups == null || groups.isEmpty) return states;

    // Filter out any group whose courses lack names
    var valid = groups.where((g) {
      return g.values.expand((l) => l).every(widget.courseNames.containsKey);
    }).toList();
    if (valid.isEmpty) return states;

    // Score each OR-group by how many courses match the student's faculty
    final scores = valid.map((g) {
      return g.values
          .expand((l) => l)
          .where((cid) =>
              widget.courseFaculties[cid]?.contains(widget.studentFaculty) ??
              false)
          .length;
    }).toList();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    // Keep only those groups tied for the top score
    valid = [
      for (var i = 0; i < valid.length; i++)
        if (scores[i] == maxScore) valid[i]
    ];

    // For each state so far, branch it by each valid OR-group
    final result = <_GraphState>[];
    for (final st in states) {
      for (final g in valid) {
        final clone = _GraphState.clone(st);
        final children = g.values.expand((l) => l);
        for (final cid in children) {
          clone.addEdge(currentId, cid);
        }
        var next = [clone];
        for (final cid in children) {
          next = next
              .expand((s) => _buildStatesFrom(cid, [s], nextVisited))
              .toList();
        }
        result.addAll(next);
      }
    }
    return result;
  }

  Widget _buildCourseBox(String title) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(title, textAlign: TextAlign.center),
      );
}

/// Holds a Graph and a map from courseId → Node
class _GraphState {
  final Graph graph = Graph();
  final Map<String, Node> nodeMap = {};

  _GraphState();

  _GraphState.clone(_GraphState other) {
    for (var id in other.nodeMap.keys) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
    }
    for (var e in other.graph.edges) {
      final s = e.source.key!.value as String;
      final d = e.destination.key!.value as String;
      graph.addEdge(nodeMap[s]!, nodeMap[d]!);
    }
  }

  void addNode(String id) {
    if (!nodeMap.containsKey(id)) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
    }
  }

  void addEdge(String from, String to) {
    addNode(from);
    addNode(to);
    graph.addEdge(nodeMap[from]!, nodeMap[to]!);
  }
}
