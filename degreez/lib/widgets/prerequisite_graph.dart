import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../services/course_service.dart';
import '../widgets/tree_painter.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';



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
  late List<_GraphState> _allStates;
  final PageController _pageController = PageController(initialPage: 0);
  late Map<String, String> _names;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // start _names with whatever was passed in:
    _names = Map.from(widget.courseNames);
    _computeStates();
  }

  /// Rebuild the graph states based on the current rootCourseId and coursePrereqs:
  void _computeStates() {
    final initial = _GraphState()..addNode(widget.rootCourseId);
    _allStates = _buildStatesFrom(widget.rootCourseId, [initial], {});
    _preloadMissingNames();
  }

  /// Whenever the widget’s inputs change, rebuild:
  @override
  void didUpdateWidget(covariant PrerequisiteGraph old) {
    super.didUpdateWidget(old);
    if (old.rootCourseId != widget.rootCourseId ||
        old.coursePrereqs != widget.coursePrereqs ||
        old.courseNames != widget.courseNames) {
      // reset our name‐map in case the new widget passed more up‐front names
      _names = Map.from(widget.courseNames);
      _computeStates();
      setState(() {}); // trigger a repaint
    }
  }

  /// Fetch any course names we didn’t already have:
  Future<void> _preloadMissingNames() async {
    final allIds = _allStates.expand((st) => st.nodeMap.keys).toSet();
    final missing = allIds.where((id) => !_names.containsKey(id)).toList();
    if (missing.isEmpty) return;

    for (final id in missing) {
      final fetched = await CourseService.getCourseName(id);
      _names[id] = fetched ?? id;
    }
    setState(() {}); // update the labels
  }

  @override
  Widget build(BuildContext context) {
    if (_allStates.isEmpty) {
      return const Center(child: Text('No valid prerequisite graphs found.'));
    }

    final builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 30
      ..levelSeparation = 40
      ..subtreeSeparation = 30
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    return Column(
      children: [
        // 1) The zoomable, paged GraphView
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
  child: LayoutBuilder(
    builder: (context, constraints) {
      // Force the GraphView to live in a finite box, then scale it
final themeProvider = Provider.of<ThemeProvider>(context);
final treeNode = graphState.toTreeNode(widget.rootCourseId, _names);

return InteractiveViewer(
  constrained: false,
  boundaryMargin: const EdgeInsets.all(500),
  minScale: 0.5,
  maxScale: 3.0,
  child: Container(
    width: 2000,
    height: 2000,
    color: themeProvider.mainColor,
    child: CustomPaint(
      painter: TreePainter(
        treeNode,
        themeProvider: themeProvider,
      ),
    ),
  ),
);



    },
  ),
);

            },
          ),
        ),

        const SizedBox(height: 8),

        // 2) The “Graph 1 | Graph 2 | …” button panel
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
                    backgroundColor:
                        selected ? Theme.of(context).colorScheme.primary : null,
                    foregroundColor: selected ? Colors.white : null,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

    // keep only groups whose IDs you actually fetched prereqs for
    var valid = groups.where((g) =>
        g.values.expand((l) => l).every(widget.courseNames.containsKey)).toList();
    if (valid.isEmpty) return states;

    // score by faculty preference
    final scores = valid.map((g) {
      return g.values
          .expand((l) => l)
          .where((cid) =>
              widget.courseFaculties[cid]?.contains(widget.studentFaculty) ??
              false)
          .length;
    }).toList();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    valid = [
      for (var i = 0; i < valid.length; i++) if (scores[i] == maxScore) valid[i]
    ];

    final result = <_GraphState>[];
    for (final st in states) {
      for (final g in valid) {
        final clone = _GraphState.clone(st);
        final children = g.values.expand((l) => l);
        for (final cid in children) clone.addEdge(currentId, cid);
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


  TreeNode toTreeNode(String rootId, Map<String, String> names) {
  final visited = <String>{};
  TreeNode build(String id) {
    if (visited.contains(id)) return TreeNode(id: id, label: names[id] ?? id);
    visited.add(id);
    final children = graph
        .edges
        .where((e) => (e.source.key!.value == id))
        .map((e) => e.destination.key!.value as String)
        .toList();
    return TreeNode(
      id: id,
      label: names[id] ?? id,
      children: children.map(build).toList(),
    );
  }

  return build(rootId);
}


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
