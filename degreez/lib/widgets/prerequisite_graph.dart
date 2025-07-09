import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../services/course_service.dart';
import '../widgets/tree_painter.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';

class PrerequisiteGraph extends StatefulWidget {
  final String rootCourseId;
  final String studentFaculty;
  final Map<String, String> courseNames;
  final Map<String, String> courseFaculties;
  final Map<String, List<Map<String, List<String>>>> coursePrereqs;
  final bool showHeader;

  const PrerequisiteGraph({
    super.key,
    required this.rootCourseId,
    required this.studentFaculty,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
    this.showHeader = true,
  });

  @override
  _PrerequisiteGraphState createState() => _PrerequisiteGraphState();
}

class _PrerequisiteGraphState extends State<PrerequisiteGraph> {
  // Lazy loading configuration
  static const int LAZY_THRESHOLD =
      20; // Start lazy loading if more than 20 graphs
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
  final TransformationController _transformationController =
      TransformationController();

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
    debugPrint(
      '⏱️ Combination generation took: ${stopwatch.elapsedMilliseconds}ms',
    );
    debugPrint('📊 Generated ${_allCombinations.length} combinations');

    // Decide on lazy vs eager loading
    _isLazyMode = _allCombinations.length > LAZY_THRESHOLD;

    if (_isLazyMode) {
      debugPrint(
        '🔄 Using lazy loading mode (${_allCombinations.length} > $LAZY_THRESHOLD)',
      );
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
    final initialCombinations =
        _allCombinations.take(INITIAL_BATCH_SIZE).toList();
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
    if (!_isLazyMode ||
        _isLoadingMore ||
        _displayedStates.length >= _allCombinations.length) {
      return;
    }

    setState(() => _isLoadingMore = true);

    // Get next batch of combinations
    final startIndex = _displayedStates.length;
    final endIndex = (startIndex + BATCH_SIZE).clamp(
      0,
      _allCombinations.length,
    );
    final nextCombinations = _allCombinations.sublist(startIndex, endIndex);

    debugPrint(
      '🔄 Loading batch ${startIndex + 1}-$endIndex of ${_allCombinations.length}',
    );

    // Build graphs for this batch
    final newGraphs = await _buildGraphsFromCombinations(nextCombinations);

    setState(() {
      _displayedStates.addAll(newGraphs);
      _isLoadingMore = false;
    });

    debugPrint(
      '📈 Loaded ${newGraphs.length} more graphs. Total: ${_displayedStates.length}/${_allCombinations.length}',
    );
  }

  Future<List<_GraphState>> _buildGraphsFromCombinations(
    List<Map<String, int>> combinations,
  ) async {
    final graphs = <_GraphState>[];

    for (int i = 0; i < combinations.length; i++) {
      final combination = combinations[i];

      // Create graph for this combination
      final graphState = _GraphState();
      graphState.addNode(widget.rootCourseId);

      final success = _buildGraphWithCombination(
        widget.rootCourseId,
        graphState,
        combination,
        {},
      );

      if (success) {
        graphs.add(graphState);
      }

      // Yield control periodically to keep UI responsive
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    // 🎯 NEW: Sort graphs by "best" (most matching courses with student's taken courses)
    final sortedGraphs = _sortGraphsByBestMatch(graphs);

    return sortedGraphs;
  }

  // Your existing OR-group combination generation (unchanged)
  List<Map<String, int>> _generateORGroupCombinations(
    String courseId,
    Set<String> visited,
  ) {
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

      final groupCombosWithChoice =
          groupChildCombos
              .map((combo) => {...combo, courseId: groupIndex})
              .toList();

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
      if (!_buildGraphWithCombination(
        childId,
        graph,
        combination,
        nextVisited,
      )) {
        return false;
      }
    }

    return true;
  }

  List<Map<String, List<String>>> _filterValidGroups(
    List<Map<String, List<String>>> groups,
  ) {
    var valid =
        groups.where((g) {
          final children = g.values.expand((l) => l).toList();
          return children.every(widget.courseNames.containsKey);
        }).toList();

    if (valid.isEmpty) return [];

    final scores =
        valid.map((g) {
          final children = g.values.expand((l) => l).toList();
          return children
              .where(
                (cid) =>
                    widget.courseFaculties[cid]?.contains(
                      widget.studentFaculty,
                    ) ??
                    false,
              )
              .length;
        }).toList();

    if (scores.isNotEmpty) {
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      if (maxScore > 0) {
        valid = [
          for (int i = 0; i < valid.length; i++)
            if (scores[i] == maxScore) valid[i],
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                    return GestureDetector(
                      onLongPressStart: (details) {
                        _handleLongPress(
                          details.localPosition,
                          painter,
                          treeNode,
                        );
                      },
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(1000),
                        minScale: 0.2,
                        maxScale: 5.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: Container(
                          padding: const EdgeInsets.all(100),
                          alignment: Alignment.topLeft,
                          child: CustomPaint(
                            size: const Size(2000, 2000),
                            painter: painter,
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

        // Navigation controls
        _buildNavigationControls(),

        const SizedBox(height: 8),
      ],
    );
  }

  // Replace your _buildNavigationControls method with this enhanced version:

  Widget _buildNavigationControls() {
    return Column(
      children: [
        // Best graph info banner (only show if there are multiple graphs)
        if (_displayedStates.length > 1)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withAlpha(76),
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withAlpha(26),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(76),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Graph 1 is your best match based on your taken courses',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showBestGraphInfo,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Why?',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Navigation buttons
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
                  final isBestGraph = i == 0; // First graph is the best

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: SizedBox(
                      width: 60, // Fixed width to prevent overflow
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isBestGraph && !selected)
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : null,
                          foregroundColor:
                              selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : (isBestGraph && !selected)
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                  : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          side:
                              isBestGraph && !selected
                                  ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        onPressed: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBestGraph) ...[
                              Icon(
                                Icons.star,
                                size: 10,
                                color:
                                    selected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isBestGraph
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Load more button
                if (_isLazyMode &&
                    _displayedStates.length < _allCombinations.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child:
                        _isLoadingMore
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
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
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_displayedStates.length} of ${_allCombinations.length} paths loaded',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleLongPress(
    Offset tapPosition,
    TreePainter painter,
    TreeNode treeNode,
  ) {
    debugPrint('🎯 Long press detected at: $tapPosition');

    // Get the current transformation matrix
    final transform = _transformationController.value;

    // Get scale and translation from the matrix
    final scale = transform.getMaxScaleOnAxis();
    final translation = transform.getTranslation();

    debugPrint(
      '📐 Scale: $scale, Translation: ${translation.x}, ${translation.y}',
    );

    // More precise coordinate transformation
    // Account for the InteractiveViewer's transformation and container padding
    final adjustedX =
        (tapPosition.dx - translation.x) / scale - 100; // Container padding
    final adjustedY = (tapPosition.dy - translation.y) / scale - 100;
    final adjustedPosition = Offset(adjustedX, adjustedY);

    debugPrint('📍 Adjusted position: $adjustedPosition');

    // Also try a simpler approach - just use the raw tap position with larger hit radius
    debugPrint('📍 Raw tap position: $tapPosition');

    // Try both approaches
    _findAndShowTappedNode(adjustedPosition, painter);

    // If that fails, also try with raw position (for debugging)
    // This will help us understand which coordinate system works better
  }

  void _findAndShowTappedNode(Offset position, TreePainter painter) {
    final nodePositions = painter.getNodePositions();
    debugPrint('🔍 Checking against ${nodePositions.length} node positions');
    debugPrint(
      '📋 Available node position keys: ${nodePositions.keys.toList()}',
    );

    String? tappedCourseId;
    double minDistance = double.infinity;

    // More generous hit detection - use a reasonable hit radius
    const double hitRadius = 100.0; // Increased hit radius for easier tapping

    // Find the closest node within hit radius
    for (final entry in nodePositions.entries) {
      final positionKey =
          entry.key; // This might be "courseId" or "courseId_0", "courseId_1"
      final nodeCenter = entry.value;

      // Calculate distance from tap to node center
      final distance = (position - nodeCenter).distance;
      debugPrint(
        '📏 Distance to $positionKey: $distance (center: $nodeCenter)',
      );

      if (distance < hitRadius && distance < minDistance) {
        minDistance = distance;
        tappedCourseId = positionKey;
      }
    }

    debugPrint(
      '🎯 Tapped position key: $tappedCourseId (min distance: $minDistance)',
    );

    if (tappedCourseId != null) {
      // 🔧 FIX: Extract original course ID from position key
      final originalCourseId = _extractOriginalCourseIdFromKey(tappedCourseId);
      debugPrint(
        '🔧 Using original course ID: $originalCourseId (from key: $tappedCourseId)',
      );
      _showCourseInfo(originalCourseId);
    } else {
      // If no exact hit, try with an even more generous radius
      const double veryGenerousRadius = 150.0;

      for (final entry in nodePositions.entries) {
        final positionKey = entry.key;
        final nodeCenter = entry.value;
        final distance = (position - nodeCenter).distance;

        if (distance < veryGenerousRadius && distance < minDistance) {
          minDistance = distance;
          tappedCourseId = positionKey;
        }
      }

      if (tappedCourseId != null) {
        final originalCourseId = _extractOriginalCourseIdFromKey(
          tappedCourseId,
        );
        debugPrint(
          '🎯 Found with generous radius: $originalCourseId (distance: $minDistance)',
        );
        _showCourseInfo(originalCourseId);
      } else {
        _showDebugInfo(position, nodePositions);
      }
    }
  }

  // 🔧 NEW: Extract original course ID from position key (handles "courseId_0" format)
  String _extractOriginalCourseIdFromKey(String positionKey) {
    // Handle cases like:
    // "02340123" -> "02340123"
    // "02340123_0" -> "02340123"
    // "02340123 (loop)" -> "02340123"

    if (positionKey.contains('_')) {
      // Remove the "_0", "_1" suffix for duplicated positions
      return positionKey.split('_').first;
    }

    if (positionKey.contains(' (')) {
      // Remove " (loop)" suffix
      return positionKey.split(' (').first;
    }

    return positionKey;
  }

  void _showDebugInfo(Offset tapPosition, Map<String, Offset> nodePositions) {
    debugPrint('❌ No node found at $tapPosition');

    // Find the closest node for debugging
    String? closestNode;
    double closestDistance = double.infinity;

    for (final entry in nodePositions.entries) {
      final distance = (tapPosition - entry.value).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestNode = entry.key;
      }
    }

    debugPrint('🔍 Closest node: $closestNode at distance: $closestDistance');

    // Show a snackbar with debug info and offer to select the closest node
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Long press detected at ${tapPosition.dx.toInt()}, ${tapPosition.dy.toInt()}',
            ),
            if (closestNode != null)
              Text('Closest: $closestNode (${closestDistance.toInt()}px away)'),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.error,
        action:
            closestNode != null && closestDistance < 200
                ? SnackBarAction(
                  label: 'Select',
                  textColor: Theme.of(context).colorScheme.onError,
                  onPressed: () => _showCourseInfo(closestNode!),
                )
                : null,
      ),
    );
  }

  void _showCourseInfo(String courseId) {
    final courseName = _names[courseId] ?? 'Unknown Course';
    final faculty = widget.courseFaculties[courseId] ?? 'Unknown Faculty';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Course Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Course ID', courseId, Icons.tag, isLightText: true),
                const SizedBox(height: 12),
                _buildDetailRow('Course Name', courseName, Icons.book),
                const SizedBox(height: 12),
                _buildDetailRow('Faculty', faculty, Icons.business),
                const SizedBox(height: 16),

                // Quick actions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withAlpha(76),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Long press on any course node to view its details',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (courseId != widget.rootCourseId) // Don't show for root course
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _focusOnCourse(courseId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Focus on this course'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isLightText = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLightText 
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _focusOnCourse(String courseId) {
    // This method would create a new graph focused on the selected course
    // You can implement this to navigate to a new PrerequisiteGraph with the selected course as root
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Focus on $courseId feature coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<_GraphState> _sortGraphsByBestMatch(List<_GraphState> graphs) {
    if (!mounted) return graphs;

    // Get student's taken courses
    final takenCourses = _getStudentTakenCourses();

    debugPrint(
      '🎓 Student has taken ${takenCourses.length} courses: $takenCourses',
    );

    // Calculate score for each graph
    final graphsWithScores =
        graphs.map((graph) {
          final score = _calculateGraphScore(graph, takenCourses);
          return _GraphWithScore(graph, score);
        }).toList();

    // Sort by score (highest first)
    graphsWithScores.sort((a, b) => b.score.compareTo(a.score));

    // Log the scores for debugging
    debugPrint('📊 Graph scores (best to worst):');
    for (int i = 0; i < graphsWithScores.length && i < 5; i++) {
      final item = graphsWithScores[i];
      final courses = item.graph.nodeMap.keys.toList();
      debugPrint('  Graph ${i + 1}: Score ${item.score} (courses: $courses)');
    }

    return graphsWithScores.map((item) => item.graph).toList();
  }

  Set<String> _getStudentTakenCourses() {
    try {
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );
      final takenCourses = <String>{};

      // Get all courses from all semesters
      for (final semester in courseProvider.sortedCoursesBySemester.values) {
        for (final course in semester) {
          takenCourses.add(course.courseId);
        }
      }

      return takenCourses;
    } catch (e) {
      debugPrint('❌ Error getting student courses: $e');
      return <String>{};
    }
  }

  int _calculateGraphScore(_GraphState graph, Set<String> takenCourses) {
    final graphCourses = graph.nodeMap.keys.toSet();

    // Calculate different scoring factors

    // 1. Number of matching courses (main factor)
    final matchingCourses = graphCourses.intersection(takenCourses);
    final matchScore =
        matchingCourses.length * 100; // Weight: 100 points per match

    // 2. Percentage of graph covered by taken courses
    final coverageScore =
        graphCourses.isEmpty
            ? 0
            : ((matchingCourses.length / graphCourses.length) * 50)
                .round(); // Weight: up to 50 points

    // 3. Bonus for having the root course taken (if applicable)

    // 4. Penalty for very complex graphs (encourage simpler paths)
    final complexityPenalty =
        graphCourses.length > 10 ? -(graphCourses.length - 10) : 0;

    final totalScore = matchScore + coverageScore + complexityPenalty;

    debugPrint('📈 Graph score calculation:');
    debugPrint('  Courses in graph: ${graphCourses.length}');
    debugPrint(
      '  Matching courses: ${matchingCourses.length} (${matchingCourses.take(3).join(', ')}${matchingCourses.length > 3 ? '...' : ''})',
    );
    debugPrint('  Match score: $matchScore');
    debugPrint('  Coverage score: $coverageScore');
    debugPrint('  Complexity penalty: $complexityPenalty');
    debugPrint('  Total score: $totalScore');

    return totalScore;
  }

  void _showBestGraphInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Best Graph'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The "best graph" is automatically selected based on:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildCriteriaItem(
                  '📚 Course matches',
                  'Prioritizes paths with courses you\'ve already taken',
                ),
                _buildCriteriaItem(
                  '📊 Coverage percentage',
                  'Higher percentage of familiar courses in the path',
                ),
                _buildCriteriaItem(
                  '🎯 Path simplicity',
                  'Prefers simpler, more direct prerequisite paths',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withAlpha(76),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'The graph with the star ⭐ is your best match!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  Widget _buildCriteriaItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to pair graphs with their scores
class _GraphWithScore {
  final _GraphState graph;
  final int score;

  _GraphWithScore(this.graph, this.score);
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
        return TreeNode(
          id: id,
          label: "${names[id] ?? id} (loop)",
          children: [],
        );
      }

      final newPath = {...currentPath, id};
      final children = _getDirectChildren(id);

      final childNodes =
          children.map((childId) => build(childId, newPath)).toList();

      return TreeNode(id: id, label: names[id] ?? id, children: childNodes);
    }

    return build(rootId, {});
  }

  _GraphState();
}
