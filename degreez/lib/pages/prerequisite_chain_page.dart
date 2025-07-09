import 'package:degreez/models/student_model.dart';
import 'package:degreez/providers/student_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../services/course_service.dart';
import '../widgets/add_course_dialog.dart';
import '../widgets/prerequisite_graph.dart';
import '../services/global_config_service.dart';
import '../pages/FullScreenGraphPage.dart';

class PrerequisiteChainPage extends StatefulWidget {
  const PrerequisiteChainPage({super.key});

  @override
  State<PrerequisiteChainPage> createState() => _PrerequisiteChainPageState();
}

class _PrerequisiteChainPageState extends State<PrerequisiteChainPage> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State variables
  List<CourseSearchResult> searchResults = [];
  EnhancedCourseDetails? selectedCourse;
  List<Map<String, List<String>>> enrichedPrereqs = [];
  List<String> missingIds = [];
  Map<String, String> courseIdToName = {};
  Map<String, String> courseFaculties = {};
  Map<String, List<Map<String, List<String>>>> coursePrereqs = {};

  bool isLoading = false;
  bool isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
        /*  SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Prerequisite Explorer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.account_tree,
                    size: 80,
                    color: Theme.of(context).colorScheme.onPrimary.withAlpha(61),
                  ),
                ),
              ),
            ),
          ),
*/
          // Search Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _buildSearchSection(),
            ),
          ),

          // Content Section
          if (selectedCourse == null && searchResults.isEmpty && !isLoading)
            _buildWelcomeSection(),

          if (isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          if (searchResults.isNotEmpty)
            _buildSearchResultsSection(),

          if (selectedCourse != null)
            _buildSelectedCourseSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Find Course',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by course ID or name (e.g., "02340123" or "calculus")',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                prefixIcon: const Icon(Icons.school),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchResults.clear();
                            isSearchExpanded = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  isSearchExpanded = value.isNotEmpty;
                });
                if (value.length >= 3) {
                  _search(value);
                } else {
                  setState(() {
                    searchResults.clear();
                  });
                }
              },
            ),
            if (_searchController.text.isNotEmpty && _searchController.text.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Type at least 3 characters to search',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.explore,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withAlpha(178),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover Course Prerequisites',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for any course to visualize its prerequisite chain and explore different prerequisite paths.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildFeaturesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      ('Interactive prerequisite trees', Icons.account_tree),
      ('Multiple prerequisite paths', Icons.alt_route),
      ('Faculty-specific recommendations', Icons.school),
      ('Real-time course data', Icons.refresh),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                feature.$2,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature.$1,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResultsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search Results (${searchResults.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              if (isLoading && searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching courses...'),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      final course = result.course;

                      return _buildSearchResultItem(course, index);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(EnhancedCourseDetails course, int index) {
    return InkWell(
      onTap: () async {
        await _handleCourseSelected(course);
        _animationController.forward();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: index < searchResults.length - 1
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.2,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  course.courseNumber.length >= 2 
                      ? course.courseNumber.substring(0, 2)
                      : course.courseNumber,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseNumber,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildInfoTag('${course.points} credits', Icons.star),
                      _buildInfoTag(_shortenFacultyName(course.faculty), Icons.school),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _shortenFacultyName(String faculty) {
    // Shorten long faculty names for better display
    if (faculty.length > 15) {
      return '${faculty.substring(0, 12)}...';
    }
    return faculty;
  }

  Widget _buildInfoTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
Widget _buildSelectedCourseSection() {
  return SliverToBoxAdapter(
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSelectedCourseHeader(),
            const SizedBox(height: 16),
            if (coursePrereqs.isNotEmpty) ...[
              _buildPrerequisiteGraph(),
              const SizedBox(height: 16),
              
              // Enhanced button row with multiple options
              Row(
                children: [
                  // Fullscreen button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fullscreen, size: 20),
                      label: const Text('Fullscreen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _openFullscreenGraph(),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Quick action buttons
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withAlpha(76),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 1,
                          height: 24,
                          color: Theme.of(context).colorScheme.outline.withAlpha(76),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Graph statistics
              const SizedBox(height: 12),
             // _buildGraphStatistics(),
            ] else
              _buildNoPrerequisitesCard(),
          ],
        ),
      ),
    ),
  );
}

void _openFullscreenGraph() {
  // Ensure we have the required data
  if (selectedCourse == null || coursePrereqs.isEmpty) {
    _showErrorSnackBar('Graph data not available');
    return;
  }

  // Add loading indicator for better UX
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(230),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Opening fullscreen view...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  );

  // Small delay to show loading indicator
  Future.delayed(const Duration(milliseconds: 300), () {
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FullScreenGraphPage(
            rootCourseId: selectedCourse!.courseNumber,
            studentFaculty: context.read<StudentProvider>().student?.faculty ?? '',
            courseNames: courseIdToName,
            courseFaculties: courseFaculties,
            coursePrereqs: coursePrereqs,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth fade transition
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  });
}


void _showGraphHelp() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('How to Use the Graph'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpSection(
              'Navigation',
              [
                'Tap numbered buttons to switch between prerequisite paths',
                'Each path shows a different way to complete prerequisites',
                'Use the fullscreen button for a better view',
              ],
              Icons.navigation,
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              'Fullscreen Mode',
              [
                'Pan: Drag to move around the graph',
                'Zoom: Pinch to zoom in/out',
                'Better visibility for complex graphs',
              ],
              Icons.fullscreen,
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              'Understanding the Graph',
              [
                'Boxes represent courses',
                'Lines show prerequisite relationships',
                'Multiple paths show alternative prerequisites',
              ],
              Icons.account_tree,
            ),
          ],
        ),
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

Widget _buildHelpSection(String title, List<String> points, IconData icon) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...points.map((point) => Padding(
        padding: const EdgeInsets.only(left: 26, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                point,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      )),
    ],
  );
}



Widget _buildStatItem(String label, String value, IconData icon, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}


  Widget _buildSelectedCourseHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withAlpha(178),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.book,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCourse!.courseNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCourse!.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedCourse = null;
                      coursePrereqs.clear();
                      _animationController.reset();
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 8),
                _buildInfoTag('${selectedCourse!.points} credits', Icons.star),
                const SizedBox(width: 8),
                _buildInfoTag(selectedCourse!.faculty, Icons.school),
                const SizedBox(width: 8),
            //    if (missingIds.isNotEmpty)
            //      _buildInfoTag('${missingIds.length} missing', Icons.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrerequisiteGraph() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 500,
          child: PrerequisiteGraph(
            key: ValueKey(selectedCourse!.courseNumber),
            rootCourseId: selectedCourse!.courseNumber,
            studentFaculty: context.read<StudentProvider>().student?.faculty ?? '',
            courseNames: courseIdToName,
            courseFaculties: courseFaculties,
            coursePrereqs: coursePrereqs,
          ),
        ),
      ),
    );
  }

  Widget _buildNoPrerequisitesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Prerequisites Required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This course has no prerequisite requirements. You can enroll directly!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Your existing methods remain the same
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
          count: 6, // Show more results
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
    
    // Show loading state
    setState(() {
      selectedCourse = course;
      coursePrereqs.clear();
      searchResults.clear();
      _searchController.clear();
    });

    final parsed = _parsePrerequisites(course.prerequisites);
    final flattened = _flattenEnriched(parsed);
    final courseProvider = context.read<CourseProvider>();

    final takenCourseIds = courseProvider.sortedCoursesBySemester.values
        .expand((s) => s)
        .map((c) => c.courseId)
        .toSet();

    final allMentioned = flattened.expand((e) => e).toSet();

    final nameMap = {
      for (var c in courseProvider.sortedCoursesBySemester.values.expand((x) => x))
        c.courseId: c.name,
    };

    for (final id in allMentioned) {
      if (!nameMap.containsKey(id)) {
        final resolved = await CourseService.getCourseName(id);
        nameMap[id] = resolved ?? 'Unknown';
      }
    }

    final missing = <String>{
      for (final group in flattened)
        if (!group.every(takenCourseIds.contains))
          ...group.where((id) => !takenCourseIds.contains(id)),
    };

    setState(() {
      enrichedPrereqs = parsed;
      courseIdToName = nameMap;
      missingIds = missing.toList();
    });

    await _buildRecursiveData(course.courseNumber);
  }

  // Keep all your existing parsing and data building methods
  List<Map<String, List<String>>> _parsePrerequisites(dynamic raw) {
    if (raw is List) {
      try {
        return raw
            .cast<Map>()
            .map((e) => Map<String, List<String>>.from(
                  e.map((k, v) => MapEntry(k as String, List<String>.from(v))),
                ))
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
          return int.tryParse(years.last) ?? 0;
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

    while (queue.isNotEmpty) {
      final courseId = queue.removeLast();
      if (visited.contains(courseId)) continue;
      visited.add(courseId);

      for (final sem in latest) {
        final parsed = CourseProvider().parseSemesterCode(sem);
        if (parsed == null) continue;
        final (year, semCode) = parsed;

        final details = await CourseService.getCourseDetails(year, semCode, courseId);
        if (details == null) continue;

        nameMap[courseId] = details.name;
        facultyMap[courseId] = details.faculty;

        final enriched = _parsePrerequisites(details.prerequisites);
        prereqMap[courseId] = enriched;

        for (final group in enriched) {
          for (final id in group.entries.expand((e) => [e.key, ...e.value])) {
            if (_isCourseId(id) && !visited.contains(id)) {
              queue.add(id);
            }
          }
        }
        break;
      }
    }

    setState(() {
      courseIdToName = nameMap;
      courseFaculties = facultyMap;
      coursePrereqs = prereqMap;
    });
  }
}