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
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _names = Map.from(widget.courseNames);
    _computeStates();
  }

  void _computeStates() {
    debugPrint('🚀 Starting graph computation for: ${widget.rootCourseId}');
     _inspectPrerequisiteData();
    // Create one graph per OR-group combination
    _allStates = _buildOneGraphPerORGroup(widget.rootCourseId);
    
    debugPrint('📊 Generated ${_allStates.length} total graphs');
    _preloadMissingNames();
  }

  /// NEW METHOD: Build one graph for each valid OR-group combination
  List<_GraphState> _buildOneGraphPerORGroup(String rootId) {
    final result = <_GraphState>[];
    final allORGroupCombinations = _generateORGroupCombinations(rootId, {});
    
    debugPrint('🔍 Found ${allORGroupCombinations.length} OR-group combinations');
    
    for (int i = 0; i < allORGroupCombinations.length; i++) {
      final combination = allORGroupCombinations[i];
      debugPrint('\n🎯 Building graph ${i + 1} with combination: $combination');
      
      final graphState = _GraphState();
      graphState.addNode(rootId);
      
      final success = _buildGraphWithCombination(rootId, graphState, combination, {});
      
      if (success) {
        debugPrint('✅ Graph ${i + 1} built successfully');
        graphState._debugGraphStructure();
        result.add(graphState);
      } else {
        debugPrint('❌ Graph ${i + 1} failed to build');
      }
    }
    
    return result;
  }

  

  /// Build a graph using a specific OR-group combination
// Modified _buildGraphWithCombination method with specific debugging for 02340141
bool _buildGraphWithCombination(
  String courseId,
  _GraphState graph,
  Map<String, int> combination,
  Set<String> visited,
) {
  if (visited.contains(courseId)) return true;
  
  final nextVisited = {...visited, courseId};
  final groups = widget.coursePrereqs[courseId];
  
  if (groups == null || groups.isEmpty) return true;
  
  // Add specific debugging for the problematic course
  if (courseId == '02340141') {
    debugPrint('\n🚨 SPECIAL DEBUG FOR 02340141 🚨');
    _debugSpecificCourse(courseId);
  }
  
  final validGroups = _filterValidGroups(groups);
  if (validGroups.isEmpty) return true;
  
  // Get the chosen OR-group for this course
  final chosenGroupIndex = combination[courseId];
  if (chosenGroupIndex == null || chosenGroupIndex >= validGroups.length) {
    debugPrint('❌ Invalid group index for $courseId: $chosenGroupIndex');
    debugPrint('   Available groups: ${validGroups.length}');
    debugPrint('   Combination: $combination');
    
    if (courseId == '02340141') {
      debugPrint('🚨 02340141 GROUP SELECTION FAILED!');
      debugPrint('   chosenGroupIndex: $chosenGroupIndex');
      debugPrint('   validGroups.length: ${validGroups.length}');
      debugPrint('   Full combination map: $combination');
    }
    return false;
  }
  
  final chosenGroup = validGroups[chosenGroupIndex];
  final children = chosenGroup.values.expand((l) => l).toList();
  
  if (courseId == '02340141') {
    debugPrint('🚨 02340141 CHOSEN GROUP:');
    debugPrint('   Chosen index: $chosenGroupIndex');
    debugPrint('   Chosen group: $chosenGroup');
    debugPrint('   Children: ${children.join(', ')} (${children.length} total)');
  }
  
  debugPrint('🔗 Adding ${children.length} children to $courseId: ${children.join(', ')}');
  
  // Add all children to this parent
  for (final childId in children) {
    graph.addEdge(courseId, childId);
  }
  
  // Verify the edges were added correctly
  final actualChildren = graph._getDirectChildren(courseId);
  if (actualChildren.length != children.length) {
    debugPrint('❌ Edge count mismatch for $courseId:');
    debugPrint('   Expected: ${children.join(', ')} (${children.length})');
    debugPrint('   Actual: ${actualChildren.join(', ')} (${actualChildren.length})');
    
    if (courseId == '02340141') {
      debugPrint('🚨 02340141 EDGE MISMATCH DETECTED!');
    }
    return false;
  }
  
  debugPrint('✅ Successfully added ${children.length} children to $courseId');
  
  // Recursively build for all children
  for (final childId in children) {
    if (!_buildGraphWithCombination(childId, graph, combination, nextVisited)) {
      return false;
    }
  }
  
  return true;
}

// Also add debugging to the combination generation for 02340141
List<Map<String, int>> _generateORGroupCombinations(String courseId, Set<String> visited) {
  if (visited.contains(courseId)) return [{}];
  
  final nextVisited = {...visited, courseId};
  final groups = widget.coursePrereqs[courseId];
  
  if (groups == null || groups.isEmpty) return [{}];
  
  // Special debugging for 02340141
  if (courseId == '02340141') {
    debugPrint('\n🔍 GENERATING COMBINATIONS FOR 02340141');
    _debugSpecificCourse(courseId);
  }
  
  // Filter valid groups
  final validGroups = _filterValidGroups(groups);
  if (validGroups.isEmpty) return [{}];
  
  if (courseId == '02340141') {
    debugPrint('🔍 02340141 valid groups after filtering: ${validGroups.length}');
    for (int i = 0; i < validGroups.length; i++) {
      final group = validGroups[i];
      final children = group.values.expand((l) => l).toList();
      debugPrint('   Group $i: ${children.join(', ')}');
    }
  }
  
  debugPrint('📋 Course $courseId has ${validGroups.length} valid OR-groups');
  
  // Get combinations for all children
  final childCombinations = <List<Map<String, int>>>[];
  
  for (int groupIndex = 0; groupIndex < validGroups.length; groupIndex++) {
    final group = validGroups[groupIndex];
    final children = group.values.expand((l) => l).toList();
    
    if (courseId == '02340141') {
      debugPrint('🔍 02340141 processing group $groupIndex with children: ${children.join(', ')}');
    }
    
    // Get combinations for each child
    List<Map<String, int>> groupChildCombos = [{}];
    
    for (final childId in children) {
      final childCombos = _generateORGroupCombinations(childId, nextVisited);
      
      // Merge child combinations
      final newGroupChildCombos = <Map<String, int>>[];
      for (final existing in groupChildCombos) {
        for (final childCombo in childCombos) {
          final merged = {...existing, ...childCombo};
          newGroupChildCombos.add(merged);
        }
      }
      groupChildCombos = newGroupChildCombos;
    }
    
    // Add this course's OR-group choice to each combination
    final groupCombosWithChoice = groupChildCombos.map((combo) => {
      ...combo,
      courseId: groupIndex,
    }).toList();
    
    if (courseId == '02340141') {
      debugPrint('🔍 02340141 group $groupIndex produces ${groupCombosWithChoice.length} combinations');
    }
    
    childCombinations.add(groupCombosWithChoice);
  }
  
  // Flatten all combinations
  final allCombinations = childCombinations.expand((x) => x).toList();
  
  if (courseId == '02340141') {
    debugPrint('🔍 02340141 FINAL: ${allCombinations.length} total combinations');
    for (int i = 0; i < allCombinations.length; i++) {
      debugPrint('   Combination $i: ${allCombinations[i]}');
    }
  }
  
  debugPrint('🔢 Course $courseId contributes ${allCombinations.length} combinations');
  
  return allCombinations;
}

  /// Filter and score OR-groups
  List<Map<String, List<String>>> _filterValidGroups(List<Map<String, List<String>>> groups) {
    // Filter groups where all children exist in courseNames
    var valid = groups.where((g) {
      final children = g.values.expand((l) => l).toList();
      return children.every(widget.courseNames.containsKey);
    }).toList();

    if (valid.isEmpty) return [];

    // Score groups by faculty matching
    final scores = valid.map((g) {
      final children = g.values.expand((l) => l).toList();
      return children
          .where((cid) => 
              widget.courseFaculties[cid]?.contains(widget.studentFaculty) ?? false)
          .length;
    }).toList();

    // If we have faculty-matching groups, prefer them
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    if (maxScore > 0) {
      valid = [
        for (int i = 0; i < valid.length; i++)
          if (scores[i] == maxScore) valid[i]
      ];
    }

    return valid;
  }

  @override
  void didUpdateWidget(covariant PrerequisiteGraph old) {
    super.didUpdateWidget(old);
    if (old.rootCourseId != widget.rootCourseId ||
        old.coursePrereqs != widget.coursePrereqs ||
        old.courseNames != widget.courseNames) {
      _names = Map.from(widget.courseNames);
      _computeStates();
      setState(() {});
    }
  }

  Future<void> _preloadMissingNames() async {
    final allIds = _allStates.expand((st) => st.nodeMap.keys).toSet();
    final missing = allIds.where((id) => !_names.containsKey(id)).toList();
    if (missing.isEmpty) return;

    for (final id in missing) {
      final fetched = await CourseService.getCourseName(id);
      _names[id] = fetched ?? id;
    }
    setState(() {});
  }

  void _zoomToFit(Rect bounds, Size viewportSize) {
    const padding = 40.0;

    final scaleX = (viewportSize.width - padding * 2) / bounds.width;
    final scaleY = (viewportSize.height - padding * 2) / bounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final dx =
        -bounds.left * scale + (viewportSize.width - bounds.width * scale) / 2;
    final dy =
        -bounds.top * scale + (viewportSize.height - bounds.height * scale) / 2;

    _transformationController.value =
        Matrix4.identity()
          ..translate(dx, dy)
          ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    if (_allStates.isEmpty) {
      return const Center(child: Text('No valid prerequisite graphs found.'));
    }

    return Column(
      children: [
        // Header with graph information
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _names[widget.rootCourseId] ?? widget.rootCourseId,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_allStates.length} different prerequisite paths',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (_allStates.isNotEmpty) _buildCurrentGraphInfo(),
            ],
          ),
        ),
        
        // Graph display
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
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    final treeNode = graphState.toTreeNode(
                      widget.rootCourseId,
                      _names,
                    );
                    final painter = TreePainter(
                      treeNode,
                      themeProvider: themeProvider,
                    );
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final bounds = painter.getBoundingBox();
                      if (bounds != null) {
                        _zoomToFit(bounds, constraints.biggest);
                      }
                    });

                    return InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(500),
                      minScale: 0.2,
                      maxScale: 5.0,
                      child: Container(
                        key: ValueKey("graph_$index"),
                        width: 2000,
                        height: 2000,
                        color: themeProvider.mainColor,
                        child: CustomPaint(painter: painter),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Navigation buttons
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text('Path ${i + 1}'),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCurrentGraphInfo() {
    if (_allStates.isEmpty) return const SizedBox();

    final currentState = _allStates[_current];
    final nodeCount = currentState.nodeMap.length;
    final edgeCount = currentState.graph.edges.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoChip('Courses', nodeCount.toString()),
          _buildInfoChip('Prerequisites', edgeCount.toString()),
          _buildInfoChip('Path', '${_current + 1} of ${_allStates.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }


  void _debugSpecificCourse(String courseId) {
  debugPrint('\n🔍 === DEBUGGING COURSE: $courseId ===');
  
  final groups = widget.coursePrereqs[courseId];
  if (groups == null || groups.isEmpty) {
    debugPrint('❌ No prerequisite groups found for $courseId');
    return;
  }
  
  debugPrint('📋 Raw prerequisite groups for $courseId:');
  for (int i = 0; i < groups.length; i++) {
    final group = groups[i];
    debugPrint('  OR-group ${i + 1}: $group');
    
    final children = group.values.expand((l) => l).toList();
    debugPrint('    → Flattened children: ${children.join(', ')} (${children.length} total)');
    
    // Check if all children exist in courseNames
    for (final child in children) {
      if (widget.courseNames.containsKey(child)) {
        debugPrint('    ✅ $child exists in courseNames: ${widget.courseNames[child]}');
      } else {
        debugPrint('    ❌ $child MISSING from courseNames');
      }
    }
    
    // Check faculty matching
    final facultyMatches = children.where((cid) => 
        widget.courseFaculties[cid]?.contains(widget.studentFaculty) ?? false
    ).length;
    debugPrint('    🎯 Faculty matches: $facultyMatches/${children.length}');
  }
  
  // Test the filtering logic
  final validGroups = _filterValidGroups(groups);
  debugPrint('\n📊 After filtering:');
  debugPrint('  Valid groups: ${validGroups.length}/${groups.length}');
  
  for (int i = 0; i < validGroups.length; i++) {
    final group = validGroups[i];
    final children = group.values.expand((l) => l).toList();
    debugPrint('  Valid group ${i + 1}: ${children.join(', ')}');
  }
  
  debugPrint('=== END DEBUG FOR $courseId ===\n');
}
void _inspectPrerequisiteData() {
  debugPrint('\n🔍 === INSPECTING ALL PREREQUISITE DATA ===');
  
  final problematicCourses = ['02340141', '02340218', '02340123'];
  
  for (final courseId in problematicCourses) {
    debugPrint('\n📋 Course: $courseId');
    debugPrint('   Name: ${widget.courseNames[courseId] ?? 'NOT FOUND'}');
    debugPrint('   Faculty: ${widget.courseFaculties[courseId] ?? 'NOT FOUND'}');
    debugPrint('   Student Faculty: ${widget.studentFaculty}');
    
    final groups = widget.coursePrereqs[courseId];
    if (groups == null || groups.isEmpty) {
      debugPrint('   ❌ No prerequisite groups');
      continue;
    }
    
    debugPrint('   📊 ${groups.length} prerequisite groups:');
    
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      debugPrint('     Group ${i + 1}: $group');
      
      // Extract all course IDs from this group
      final allCourseIds = <String>[];
      for (final entry in group.entries) {
        final key = entry.key;
        final values = entry.value;
        
        // Check if key looks like a course ID
        if (RegExp(r'^\d{8}$').hasMatch(key)) {
          allCourseIds.add(key);
        }
        
        // Add all values that look like course IDs
        for (final value in values) {
          if (RegExp(r'^\d{8}$').hasMatch(value)) {
            allCourseIds.add(value);
          }
        }
      }
      
      debugPrint('     → Course IDs: ${allCourseIds.join(', ')} (${allCourseIds.length} total)');
      
      // Check availability of each course ID
      for (final id in allCourseIds) {
        final exists = widget.courseNames.containsKey(id);
        final name = widget.courseNames[id] ?? 'UNKNOWN';
        final faculty = widget.courseFaculties[id] ?? 'UNKNOWN';
        final facultyMatch = widget.courseFaculties[id]?.contains(widget.studentFaculty) ?? false;
        
        debugPrint('       $id: ${exists ? '✅' : '❌'} $name ($faculty) ${facultyMatch ? '🎯' : ''}');
      }
    }
  }
  
  debugPrint('\n=== END PREREQUISITE DATA INSPECTION ===\n');
}

}

/// Enhanced GraphState class with better edge management
// Simple fix: Allow nodes to appear multiple times in the tree if they have different paths

class _GraphState {
  final Graph graph = Graph();
  final Map<String, Node> nodeMap = {};
  final Set<String> _addedEdges = {};

  void addNode(String id) {
    if (!nodeMap.containsKey(id)) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
      debugPrint('✅ Added node: $id');
    }
  }

  void addEdge(String from, String to) {
    final edgeKey = '$from→$to';
    
    if (_addedEdges.contains(edgeKey)) {
      debugPrint('⚠️  Edge already exists: $from → $to');
      return;
    }
    
    debugPrint('🔗 Adding edge: $from → $to');
    
    addNode(from);
    addNode(to);
    
    final fromNode = nodeMap[from]!;
    final toNode = nodeMap[to]!;
    
    graph.addEdge(fromNode, toNode);
    _addedEdges.add(edgeKey);
    
    debugPrint('✅ Edge added successfully: $from → $to');
  }

  List<String> _getDirectChildren(String parentId) {
    final parentNode = nodeMap[parentId];
    if (parentNode == null) {
      debugPrint('❌ Parent node not found: $parentId');
      return [];
    }
    
    final children = graph.edges
        .where((edge) => edge.source == parentNode)
        .map((edge) => edge.destination.key!.value as String)
        .toList();
    
    debugPrint('📊 Direct children of $parentId: ${children.join(', ')} (count: ${children.length})');
    return children;
  }

  // SOLUTION 1: Show full tree for each path (nodes can appear multiple times)
  TreeNode toTreeNodeWithDuplicates(String rootId, Map<String, String> names) {
    debugPrint('🌳 Converting to tree starting from: $rootId (allowing duplicates)');
    
    TreeNode build(String id, Set<String> currentPath, int depth) {
      final indent = '  ' * depth;
      debugPrint('${indent}🔍 Building node: $id (depth: $depth)');
      
      // Only prevent infinite loops within the same path
      if (currentPath.contains(id)) {
        debugPrint("${indent}🔄 Loop detected in current path, stopping: $id");
        return TreeNode(id: id, label: names[id] ?? id, children: []);
      }

      final newPath = {...currentPath, id};
      final children = _getDirectChildren(id);
      
      debugPrint("${indent}👶 Children of $id: ${children.join(', ')} (count: ${children.length})");

      final childNodes = children.map((childId) => 
        build(childId, newPath, depth + 1)
      ).toList();
      
      debugPrint("${indent}✅ Built node $id with ${childNodes.length} children");
      
      return TreeNode(
        id: id,
        label: names[id] ?? id,
        children: childNodes,
      );
    }

    final result = build(rootId, {}, 0);
    debugPrint('🌳 Tree conversion completed (with duplicates allowed)');
    return result;
  }

  // SOLUTION 2: Show tree with shared nodes marked
  TreeNode toTreeNodeWithSharedMarking(String rootId, Map<String, String> names) {
    debugPrint('🌳 Converting to tree starting from: $rootId (marking shared nodes)');
    
    // First pass: identify nodes that appear multiple times
    final nodeOccurrences = <String, int>{};
    void countOccurrences(String id, Set<String> visited) {
      if (visited.contains(id)) return;
      final newVisited = {...visited, id};
      
      nodeOccurrences[id] = (nodeOccurrences[id] ?? 0) + 1;
      
      final children = _getDirectChildren(id);
      for (final child in children) {
        countOccurrences(child, newVisited);
      }
    }
    countOccurrences(rootId, {});
    
    // Second pass: build tree with shared node indicators
    TreeNode build(String id, Set<String> currentPath, int depth) {
      final indent = '  ' * depth;
      debugPrint('${indent}🔍 Building node: $id (depth: $depth)');
      
      if (currentPath.contains(id)) {
        debugPrint("${indent}🔄 Loop detected, stopping: $id");
        return TreeNode(id: id, label: names[id] ?? id, children: []);
      }

      final newPath = {...currentPath, id};
      final children = _getDirectChildren(id);
      
      // Check if this node appears elsewhere (shared)
      final isShared = (nodeOccurrences[id] ?? 0) > 1;
      final hasBeenVisitedBefore = currentPath.isNotEmpty; // Not the root
      
      if (isShared && hasBeenVisitedBefore) {
        debugPrint("${indent}🔗 Shared node $id - showing as reference");
        final label = "${names[id] ?? id} (shared)";
        return TreeNode(id: id, label: label, children: []);
      }
      
      debugPrint("${indent}👶 Children of $id: ${children.join(', ')} (count: ${children.length})");

      final childNodes = children.map((childId) => 
        build(childId, newPath, depth + 1)
      ).toList();
      
      debugPrint("${indent}✅ Built node $id with ${childNodes.length} children");
      
      return TreeNode(
        id: id,
        label: names[id] ?? id,
        children: childNodes,
      );
    }

    final result = build(rootId, {}, 0);
    debugPrint('🌳 Tree conversion completed (with shared marking)');
    return result;
  }

  // Your original method - just renamed for clarity
  TreeNode toTreeNode(String rootId, Map<String, String> names) {
    // Use the solution that works best for you:
    return toTreeNodeWithDuplicates(rootId, names);
 //   return toTreeNodeWithSharedMarking(rootId, names);
  }

  void _debugGraphStructure() {
    debugPrint('📊 === GRAPH STRUCTURE DEBUG ===');
    debugPrint('Nodes: ${nodeMap.keys.join(', ')}');
    debugPrint('Total nodes: ${nodeMap.length}');
    debugPrint('Total edges: ${graph.edges.length}');
    
    debugPrint('Edges:');
    for (final edge in graph.edges) {
      final from = edge.source.key?.value as String?;
      final to = edge.destination.key?.value as String?;
      debugPrint('  $from → $to');
    }
    
    // Check for nodes with multiple parents (diamond dependencies)
    final nodeParents = <String, List<String>>{};
    for (final edge in graph.edges) {
      final from = edge.source.key?.value as String?;
      final to = edge.destination.key?.value as String?;
      if (from != null && to != null) {
        nodeParents.putIfAbsent(to, () => []).add(from);
      }
    }
    
    debugPrint('Node parents:');
    for (final entry in nodeParents.entries) {
      final nodeId = entry.key;
      final parents = entry.value;
      if (parents.length > 1) {
        debugPrint('  🔹 $nodeId has ${parents.length} parents: ${parents.join(', ')} (DIAMOND DEPENDENCY)');
      } else {
        debugPrint('  $nodeId: ${parents.join(', ')}');
      }
    }
    
    debugPrint('Node children count:');
    for (final nodeId in nodeMap.keys) {
      final childCount = _getDirectChildren(nodeId).length;
      debugPrint('  $nodeId: $childCount children');
    }
    debugPrint('=== END GRAPH DEBUG ===');
  }

  _GraphState();
}