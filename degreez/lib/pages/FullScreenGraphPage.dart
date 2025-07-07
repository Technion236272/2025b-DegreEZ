import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:degreez/widgets/prerequisite_graph.dart';
import 'package:degreez/providers/theme_provider.dart';

class FullScreenGraphPage extends StatefulWidget {
  final String rootCourseId;
  final String studentFaculty;
  final Map<String, String> courseNames;
  final Map<String, String> courseFaculties;
  final Map<String, List<Map<String, List<String>>>> coursePrereqs;

  const FullScreenGraphPage({
    Key? key,
    required this.rootCourseId,
    required this.studentFaculty,
    required this.courseNames,
    required this.courseFaculties,
    required this.coursePrereqs,
  }) : super(key: key);

  @override
  State<FullScreenGraphPage> createState() => _FullScreenGraphPageState();
}

class _FullScreenGraphPageState extends State<FullScreenGraphPage> {
  bool _isFullscreen = true; // Always start in fullscreen since this is a fullscreen page

  @override
  void initState() {
    super.initState();
    // Set fullscreen mode immediately since this is a fullscreen page
    _enterFullscreen();
  }

  @override
  void dispose() {
    // Exit fullscreen mode when leaving
    _exitFullscreen();
    super.dispose();
  }

  void _enterFullscreen() {
    // Hide system UI for true fullscreen experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _exitFullscreen() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final courseName = widget.courseNames[widget.rootCourseId] ?? widget.rootCourseId;

    return PopScope(
      // Handle back button properly
      onPopInvoked: (didPop) {
        if (!didPop) {
          _exitFullscreen();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
    
        // Conditionally show app bar - always hidden since this is fullscreen
        appBar: null,
        body: Stack(
          children: [
            // Main graph content - positioned to avoid overlap with floating elements
            Positioned.fill(
              child: PrerequisiteGraph(
                key: ValueKey('${widget.rootCourseId}_fullscreen'),
                rootCourseId: widget.rootCourseId,
                studentFaculty: widget.studentFaculty,
                courseNames: widget.courseNames,
                courseFaculties: widget.courseFaculties,
                coursePrereqs: widget.coursePrereqs,
                showHeader: false, // 👈 HIDE THE HEADER IN FULLSCREEN
              ),
            ),
            
            // Floating close button for fullscreen mode
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Card(
                color: themeProvider.cardColor.withOpacity(0.9),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: themeProvider.textPrimary,
                  ),
                  onPressed: () {
                    _exitFullscreen();
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Close',
                ),
              ),
            ),
            
            // Course info overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Card(
                color: themeProvider.cardColor.withOpacity(0.9),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.rootCourseId,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      if (courseName != widget.rootCourseId)
                        SizedBox(
                          width: 200,
                          child: Text(
                            courseName,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeProvider.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}