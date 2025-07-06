import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'dart:math';

class TreeNode {
  final String id;
  final String label;
  final List<TreeNode> children;

  TreeNode({required this.id, required this.label, this.children = const []});
}

class TreePainter extends CustomPainter {
  final TreeNode root;
  final ThemeProvider themeProvider; 
  final double nodeWidth;
  final double nodeHeight;
  final Map<String, Offset> _positions = {};
  
  TreePainter(
    this.root, {
    required this.themeProvider, 
    this.nodeWidth = 120,
    this.nodeHeight = 60,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _positions.clear();
    _layoutAndPaint(root, 0, 0, canvas);
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

    // Draw edges from children
    for (final child in node.children) {
      final childCenter = _positions[child.id]!;
      drawEdge(childCenter, nodeCenter, canvas);
    }

    drawNode(nodeCenter, node.label, canvas);
    return totalWidth;
  }

  void drawNode(Offset center, String label, Canvas canvas) {
    final x = center.dx - nodeWidth / 2;
    final y = center.dy - nodeHeight / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, nodeWidth, nodeHeight),
      const Radius.circular(16),
    );

    if (themeProvider.isDarkMode) {
      canvas.drawShadow(Path()..addRRect(rect), Colors.black45, 4, false);
    }

    canvas.drawRRect(rect, Paint()..color = themeProvider.primaryColor);

    drawNodeLabel(label, Offset(x, y), canvas);
  }

  void drawNodeLabel(String label, Offset topLeft, Canvas canvas) {
    final textPainter = TextPainter(
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

    final offset = Offset(
      topLeft.dx + (nodeWidth - textPainter.width) / 2,
      topLeft.dy + (nodeHeight - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

void drawEdge(Offset childCenter, Offset parentCenter, Canvas canvas) {
  // Corrected anchor points
  final from = Offset(childCenter.dx, childCenter.dy - nodeHeight / 2);  // top of child
  final to = Offset(parentCenter.dx, parentCenter.dy + nodeHeight / 2);  // bottom of parent

  final midY = (from.dy + to.dy) / 2;
  final controlOffset = (from.dx - to.dx).abs() / 2 + 20;

  final controlPoint1 = Offset(from.dx, midY - controlOffset);
  final controlPoint2 = Offset(to.dx, midY + controlOffset);

  final path = Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      to.dx, to.dy,
    );

  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke,
  );
}







  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
