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
  final bool showHeader;

  const PrerequisiteGraph({
    Key? key,
    required this.rootCourseId,
    required this.studentFaculty,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
    this.showHeader = true,
  }) : super(key: key);

  @override
  _PrerequisiteGraphState createState() => _PrerequisiteGraphState();
}

class _PrerequisiteGraphState extends State<PrerequisiteGraph> {
  // Lazy loading configuration
  static const int LAZY_THRESHOLD = 20;  // Start lazy loading if more than 20 graphs
  static const int INITIAL_BATCH_SIZE = 5;
  static const int BATCH_SIZE = 3;
  
  // State management
  List<Map<String, int>> _allCombinations = [];
  List<_GraphState> _displayedStates = [];
  late Map<String, String> _names;
  int _current = 0;
  bool _isLazyMode = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  
  // UI controllers
  final PageController _pageController = PageController(initialPage: 0);
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _names = Map.from(widget.courseNames);
    _computeStates();
  }

  @override
  void didUpdateWidget(covariant PrerequisiteGraph old) {
    super.didUpdateWidget(old);
    if (old.rootCourseId != widget.rootCourseId ||
        old.coursePrereqs != widget.coursePrereqs ||
        old.courseNames != widget.courseNames) {
      _names = Map.from(widget.courseNames);
      _computeStates();
    }
  }

  void _computeStates() async {
    setState(() {
      _isInitialLoading = true;
      _displayedStates.clear();
      _current = 0;
    });

    final stopwatch = Stopwatch()..start();
    debugPrint('🚀 Starting graph computation for: ${widget.rootCourseId}');
    
    // Generate all possible OR-group combinations (fast)
    _allCombinations = _generateORGroupCombinations(widget.rootCourseId, {});
    
    stopwatch.stop();
    debugPrint('⏱️ Combination generation took: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('📊 Generated ${_allCombinations.length} combinations');
    
    // Decide on lazy vs eager loading
    _isLazyMode = _allCombinations.length > LAZY_THRESHOLD;
    
    if (_isLazyMode) {
      debugPrint('🔄 Using lazy loading mode (${_allCombinations.length} > $LAZY_THRESHOLD)');
      await _loadInitialBatch();
    } else {
      debugPrint('⚡ Using eager loading mode');
      await _loadAllGraphs();
    }

    setState(() {
      _isInitialLoading = false;
    });

    _preloadMissingNames();
  }

  Future<void> _loadInitialBatch() async {
    final initialCombinations = _allCombinations.take(INITIAL_BATCH_SIZE).toList();
    final graphs = await _buildGraphsFromCombinations(initialCombinations);
    
    setState(() {
      _displayedStates = graphs;
    });
    
    debugPrint('📦 Loaded initial batch: ${graphs.length} graphs');
  }

  Future<void> _loadAllGraphs() async {
    final graphs = await _buildGraphsFromCombinations(_allCombinations);
    
    setState(() {
      _displayedStates = graphs;
    });
    
    debugPrint('📦 Loaded all graphs: ${graphs.length} graphs');
  }

  Future<void> _loadMoreGraphs() async {
    if (!_isLazyMode || _isLoadingMore || _displayedStates.length >= _allCombinations.length) {
      return;
    }

    setState(() => _isLoadingMore = true);

    // Get next batch of combinations
    final startIndex = _displayedStates.length;
    final endIndex = (startIndex + BATCH_SIZE).clamp(0, _allCombinations.length);
    final nextCombinations = _allCombinations.sublist(startIndex, endIndex);
    
    debugPrint('🔄 Loading batch ${startIndex + 1}-$endIndex of ${_allCombinations.length}');

    // Build graphs for this batch
    final newGraphs = await _buildGraphsFromCombinations(nextCombinations);

    setState(() {
      _displayedStates.addAll(newGraphs);
      _isLoadingMore = false;
    });

    debugPrint('📈 Loaded ${newGraphs.length} more graphs. Total: ${_displayedStates.length}/${_allCombinations.length}');
  }

  Future<List<_GraphState>> _buildGraphsFromCombinations(List<Map<String, int>> combinations) async {
    final graphs = <_GraphState>[];
    
    for (int i = 0; i < combinations.length; i++) {
      final combination = combinations[i];
      
      // Create graph for this combination
      final graphState = _GraphState();
      graphState.addNode(widget.rootCourseId);
      
      final success = _buildGraphWithCombination(widget.rootCourseId, graphState, combination, {});
      
      if (success) {
        graphs.add(graphState);
      }
      
      // Yield control periodically to keep UI responsive
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    
    return graphs;
  }

  // Your existing OR-group combination generation (unchanged)
  List<Map<String, int>> _generateORGroupCombinations(String courseId, Set<String> visited) {
    if (visited.contains(courseId)) return [{}];
    
    final nextVisited = {...visited, courseId};
    final groups = widget.coursePrereqs[courseId];
    
    if (groups == null || groups.isEmpty) return [{}];
    
    final validGroups = _filterValidGroups(groups);
    if (validGroups.isEmpty) return [{}];
    
    final childCombinations = <List<Map<String, int>>>[];
    
    for (int groupIndex = 0; groupIndex < validGroups.length; groupIndex++) {
      final group = validGroups[groupIndex];
      final children = group.values.expand((l) => l).toList();
      
      List<Map<String, int>> groupChildCombos = [{}];
      
      for (final childId in children) {
        final childCombos = _generateORGroupCombinations(childId, nextVisited);
        
        final newGroupChildCombos = <Map<String, int>>[];
        for (final existing in groupChildCombos) {
          for (final childCombo in childCombos) {
            final merged = {...existing, ...childCombo};
            newGroupChildCombos.add(merged);
          }
        }
        groupChildCombos = newGroupChildCombos;
      }
      
      final groupCombosWithChoice = groupChildCombos.map((combo) => {
        ...combo,
        courseId: groupIndex,
      }).toList();
      
      childCombinations.add(groupCombosWithChoice);
    }
    
    final allCombinations = childCombinations.expand((x) => x).toList();
    return allCombinations;
  }

  // Your existing graph building logic (unchanged)
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
    
    final validGroups = _filterValidGroups(groups);
    if (validGroups.isEmpty) return true;
    
    final chosenGroupIndex = combination[courseId];
    if (chosenGroupIndex == null || chosenGroupIndex >= validGroups.length) {
      return false;
    }
    
    final chosenGroup = validGroups[chosenGroupIndex];
    final children = chosenGroup.values.expand((l) => l).toList();
    
    for (final childId in children) {
      graph.addEdge(courseId, childId);
    }
    
    for (final childId in children) {
      if (!_buildGraphWithCombination(childId, graph, combination, nextVisited)) {
        return false;
      }
    }
    
    return true;
  }

  List<Map<String, List<String>>> _filterValidGroups(List<Map<String, List<String>>> groups) {
    var valid = groups.where((g) {
      final children = g.values.expand((l) => l).toList();
      return children.every(widget.courseNames.containsKey);
    }).toList();

    if (valid.isEmpty) return [];

    final scores = valid.map((g) {
      final children = g.values.expand((l) => l).toList();
      return children
          .where((cid) => 
              widget.courseFaculties[cid]?.contains(widget.studentFaculty) ?? false)
          .length;
    }).toList();

    if (scores.isNotEmpty) {
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      if (maxScore > 0) {
        valid = [
          for (int i = 0; i < valid.length; i++)
            if (scores[i] == maxScore) valid[i]
        ];
      }
    }

    return valid;
  }

  Future<void> _preloadMissingNames() async {
    final allIds = _displayedStates.expand((st) => st.nodeMap.keys).toSet();
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

    final dx = -bounds.left * scale + (viewportSize.width - bounds.width * scale) / 2;
    final dy = -bounds.top * scale + (viewportSize.height - bounds.height * scale) / 2;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating prerequisite graphs...'),
          ],
        ),
      );
    }

    if (_displayedStates.isEmpty) {
      return const Center(child: Text('No valid prerequisite graphs found.'));
    }

    return Column(
      children: [
        // Header
      if (widget.showHeader)
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _names[widget.rootCourseId] ?? widget.rootCourseId,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                _isLazyMode 
                    ? 'Loaded ${_displayedStates.length}/${_allCombinations.length} paths'
                    : '${_displayedStates.length} paths',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
           //   if (_displayedStates.isNotEmpty) _buildCurrentGraphInfo(),
            ],
          ),
        ),
        
        // Graph display
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _displayedStates.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              
              // Auto-load more when approaching the end
              if (_isLazyMode && i >= _displayedStates.length - 2) {
                _loadMoreGraphs();
              }
            },
            itemBuilder: (_, index) {
              final graphState = _displayedStates[index];
              return Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final themeProvider = Provider.of<ThemeProvider>(context);
                    final treeNode = graphState.toTreeNode(widget.rootCourseId, _names);
                    final painter = TreePainter(treeNode, themeProvider: themeProvider);
                    
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final bounds = painter.getBoundingBox();
                      if (bounds != null) {
                        _zoomToFit(bounds, constraints.biggest);
                      }
                    });

return InteractiveViewer(
  transformationController: _transformationController,
  constrained: false,
  boundaryMargin: const EdgeInsets.all(1000), // big margin for easier pan
  minScale: 0.2,
  maxScale: 5.0,
  panEnabled: true,
  scaleEnabled: true,
  child: Container(
    padding: const EdgeInsets.all(100), // 👈 this gives space for gestures
    alignment: Alignment.topLeft,
    child: CustomPaint(
      size: const Size(2000, 2000), // 👈 this replaces getPreferredSize
      painter: painter,
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

        // Navigation controls
        _buildNavigationControls(),

        const SizedBox(height: 8),
      ],
    );
  }




  Widget _buildNavigationControls() {
    return Column(
      children: [
        SizedBox(
          height: 48, // Fixed height to prevent overflow
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Graph navigation buttons
                ...List.generate(_displayedStates.length, (i) {
                  final selected = i == _current;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: SizedBox(
                      width: 60, // Fixed width to prevent overflow
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected 
                              ? Theme.of(context).colorScheme.primary 
                              : null,
                          foregroundColor: selected ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
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
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }),
                
                // Load more button
                if (_isLazyMode && _displayedStates.length < _allCombinations.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : SizedBox(
                            width: 50,
                            child: ElevatedButton(
                              onPressed: _loadMoreGraphs,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              ),
                              child: Text(
                                '+${_allCombinations.length - _displayedStates.length}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
        
        // Progress indicator for lazy loading
        if (_isLazyMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _displayedStates.length / _allCombinations.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_displayedStates.length} of ${_allCombinations.length} paths loaded',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Enhanced _GraphState with better tree conversion
class _GraphState {
  final Graph graph = Graph();
  final Map<String, Node> nodeMap = {};
  final Set<String> _addedEdges = {};

  void addNode(String id) {
    if (!nodeMap.containsKey(id)) {
      nodeMap[id] = Node.Id(id);
      graph.addNode(nodeMap[id]!);
    }
  }

  void addEdge(String from, String to) {
    final edgeKey = '$from→$to';
    
    if (_addedEdges.contains(edgeKey)) return;
    
    addNode(from);
    addNode(to);
    
    final fromNode = nodeMap[from]!;
    final toNode = nodeMap[to]!;
    
    graph.addEdge(fromNode, toNode);
    _addedEdges.add(edgeKey);
  }

  List<String> _getDirectChildren(String parentId) {
    final parentNode = nodeMap[parentId];
    if (parentNode == null) return [];
    
    return graph.edges
        .where((edge) => edge.source == parentNode)
        .map((edge) => edge.destination.key!.value as String)
        .toList();
  }

  TreeNode toTreeNode(String rootId, Map<String, String> names) {
    // Use the duplicates approach for now - most reliable
    TreeNode build(String id, Set<String> currentPath) {
      if (currentPath.contains(id)) {
        return TreeNode(id: id, label: "${names[id] ?? id} (loop)", children: []);
      }

      final newPath = {...currentPath, id};
      final children = _getDirectChildren(id);

      final childNodes = children.map((childId) => 
        build(childId, newPath)
      ).toList();
      
      return TreeNode(
        id: id,
        label: names[id] ?? id,
        children: childNodes,
      );
    }

    return build(rootId, {});
  }

  _GraphState();
}