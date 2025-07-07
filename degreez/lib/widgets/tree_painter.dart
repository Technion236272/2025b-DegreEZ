import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'dart:math';

class TreeNode {
  final String id;
  final String label;
  final List<TreeNode> children;

  TreeNode({required this.id, required this.label, this.children = const []});
}

// Enhanced TreePainter with node position tracking
// Add these properties and methods to your TreePainter class:

// Enhanced TreePainter with node position tracking
// Add these properties and methods to your TreePainter class:

// Enhanced TreePainter with node position tracking
// Add these properties and methods to your TreePainter class:

// Enhanced TreePainter with node position tracking
// Add these properties and methods to your TreePainter class:

class TreePainter extends CustomPainter {
  final TreeNode root;
  final ThemeProvider themeProvider;
  final double nodeWidth;
  final double nodeHeight;
  final Map<String, Offset> _positions = {};
  Rect? _boundingBox;

  // 🔧 CHANGE: Store multiple positions for duplicated courses
  final Map<String, List<Offset>> _allNodePositions = {};

  Rect? getBoundingBox() => _boundingBox;

  // 🔧 CHANGE: Return flattened map of all positions for hit testing
  Map<String, Offset> getNodePositions() {
    final flattenedPositions = <String, Offset>{};

    for (final entry in _allNodePositions.entries) {
      final courseId = entry.key;
      final positions = entry.value;

      // For hit testing, we need to check all positions of duplicated courses
      // Store them with unique keys like "courseId_0", "courseId_1", etc.
      for (int i = 0; i < positions.length; i++) {
        final key = positions.length == 1 ? courseId : '${courseId}_$i';
        flattenedPositions[key] = positions[i];
      }
    }

    return flattenedPositions;
  }

  TreePainter(
    this.root, {
    required this.themeProvider,
    this.nodeWidth = 120,
    this.nodeHeight = 60,
  }) {
    // Debug print to ensure painter is created
    debugPrint(
      '🎨 TreePainter created with nodeWidth: $nodeWidth, nodeHeight: $nodeHeight',
    );
  }

  void _updateBoundingBox(Offset center) {
    final rect = Rect.fromCenter(
      center: center,
      width: nodeWidth,
      height: nodeHeight,
    );
    _boundingBox =
        _boundingBox == null ? rect : _boundingBox!.expandToInclude(rect);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _positions.clear();
    _allNodePositions.clear(); // 🔧 CHANGE: Clear all positions
    debugPrint('🎨 TreePainter painting with size: $size');
    _layoutAndPaint(root, 0, 0, canvas);

    // Debug: Show summary of stored positions
    final totalPositions = _allNodePositions.values.fold(
      0,
      (sum, list) => sum + list.length,
    );
    debugPrint(
      '🎨 TreePainter finished, stored $totalPositions total positions for ${_allNodePositions.length} unique courses',
    );

    // Debug: Show duplicated courses
    _allNodePositions.forEach((courseId, positions) {
      if (positions.length > 1) {
        debugPrint(
          '🔄 Course $courseId appears ${positions.length} times at: ${positions.join(', ')}',
        );
      }
    });
  }

  double _layoutAndPaint(TreeNode node, double x, double y, Canvas canvas) {
    const double horizontalSpacing = 40.0;
    const double verticalSpacing = 100.0;

    double currentX = x;
    final List<double> childrenWidths = [];

    for (final child in node.children) {
      final childWidth = _layoutAndPaint(
        child,
        currentX,
        y + nodeHeight + verticalSpacing,
        canvas,
      );
      childrenWidths.add(childWidth);
      currentX += childWidth + horizontalSpacing;
    }

    final totalWidth =
        childrenWidths.isEmpty
            ? nodeWidth
            : childrenWidths.reduce((a, b) => a + b) +
                horizontalSpacing * (childrenWidths.length - 1);

    final centerX = x + (totalWidth - nodeWidth) / 2;
    final nodeCenter = Offset(centerX + nodeWidth / 2, y + nodeHeight / 2);

    _positions[node.id] = nodeCenter;

    // 🔧 CHANGE: Store all positions for each course ID
    final originalCourseId = _extractOriginalCourseId(node.id);

    // Add this position to the list of positions for this course
    _allNodePositions.putIfAbsent(originalCourseId, () => []);
    _allNodePositions[originalCourseId]!.add(nodeCenter);

    debugPrint(
      '📍 Storing position for "$originalCourseId" at $nodeCenter (total: ${_allNodePositions[originalCourseId]!.length})',
    );

    _updateBoundingBox(nodeCenter);

    // Draw edges from children
    for (final child in node.children) {
      final childCenter = _positions[child.id]!;
      drawEdge(childCenter, nodeCenter, canvas);
    }

    drawNode(nodeCenter, node.label, canvas, node.id);
    return totalWidth;
  }

  // 🔧 NEW: Extract original course ID from node ID
  String _extractOriginalCourseId(String nodeId) {
    // Handle cases like "02340123 (loop)" or just "02340123"
    if (nodeId.contains(' (')) {
      return nodeId.split(' (').first;
    }
    return nodeId;
  }

  // 👈 MODIFIED: Add nodeId parameter to help with debugging
  void drawNode(Offset center, String label, Canvas canvas, String nodeId) {
    final x = center.dx - nodeWidth / 2;
    final y = center.dy - nodeHeight / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, nodeWidth, nodeHeight),
      const Radius.circular(16),
    );

    if (themeProvider.isDarkMode) {
      canvas.drawShadow(
        Path()..addRRect(rect),
        themeProvider.isDarkMode ? Colors.black45 : Colors.grey.shade300,
        4,
        false,
      );
    }

    // 👈 ADD THIS: Visual feedback for interactive nodes
    final paint = Paint()..color = themeProvider.secondaryColor;

    // Add a subtle border to indicate the node is interactive
    final borderPaint =
        Paint()
          ..color = themeProvider.primaryColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, borderPaint);

    drawNodeLabel(label, Offset(x, y), canvas);
  }

  void drawNodeLabel(String label, Offset topLeft, Canvas canvas) {
    // First, try to fit the full text
    var textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: themeProvider.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: nodeWidth - 16);

    // If text doesn't fit, try with smaller font
    if (textPainter.height > nodeHeight - 16) {
      textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 11, // Smaller font
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3, // Allow more lines with smaller font
      )..layout(maxWidth: nodeWidth - 12);
    }

    // If still doesn't fit, try even smaller
    if (textPainter.height > nodeHeight - 12) {
      textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: themeProvider.textPrimary,
            fontSize: 9, // Even smaller font
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 4, // Allow even more lines
      )..layout(maxWidth: nodeWidth - 10);
    }

    final offset = Offset(
      topLeft.dx + (nodeWidth - textPainter.width) / 2,
      topLeft.dy + (nodeHeight - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  void drawEdge(Offset childCenter, Offset parentCenter, Canvas canvas) {
    // Corrected anchor points
    final from = Offset(
      childCenter.dx,
      childCenter.dy - nodeHeight / 2,
    ); // top of child
    final to = Offset(
      parentCenter.dx,
      parentCenter.dy + nodeHeight / 2,
    ); // bottom of parent

    final midY = (from.dy + to.dy) / 2;
    final controlOffset = (from.dx - to.dx).abs() / 2 + 20;

    final controlPoint1 = Offset(from.dx, midY - controlOffset);
    final controlPoint2 = Offset(to.dx, midY + controlOffset);

    final path =
        Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            to.dx,
            to.dy,
          );

    canvas.drawPath(
      path,
      Paint()
        ..color = themeProvider.isDarkMode 
            ? Colors.grey.shade600 
            : Colors.grey.shade800
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
