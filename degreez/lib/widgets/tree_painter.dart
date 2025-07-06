import 'package:flutter/material.dart';

class TreeNode {
  final String id;
  final String label;
  final List<TreeNode> children;

  TreeNode({required this.id, required this.label, this.children = const []});
}

class TreePainter extends CustomPainter {
  final TreeNode root;
  final double nodeWidth;
  final double nodeHeight;
  final Map<String, Offset> _positions = {};

  TreePainter(this.root, {this.nodeWidth = 120, this.nodeHeight = 60});

  @override
  void paint(Canvas canvas, Size size) {
    _layoutAndPaint(root, 0, 0, canvas);
  }

  double _layoutAndPaint(TreeNode node, double x, double y, Canvas canvas) {
    const horizontalSpacing = 40.0;
    const verticalSpacing = 100.0;

    double nextX = x;
    final childrenWidths = <double>[];

    for (final child in node.children) {
      final childWidth = _layoutAndPaint(child, nextX, y + nodeHeight + verticalSpacing, canvas);
      childrenWidths.add(childWidth);
      nextX += childWidth + horizontalSpacing;
    }

    final totalWidth = childrenWidths.isEmpty
        ? nodeWidth
        : childrenWidths.reduce((a, b) => a + b) + horizontalSpacing * (childrenWidths.length - 1);

    final centerX = x + (totalWidth - nodeWidth) / 2;

    final nodeCenter = Offset(centerX + nodeWidth / 2, y + nodeHeight / 2);
    _positions[node.id] = nodeCenter;

    // Draw edges
    for (final child in node.children) {
      final childCenter = _positions[child.id]!;
      canvas.drawLine(
        nodeCenter,
        childCenter,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }

    // Draw node
    final rect = Rect.fromLTWH(centerX, y, nodeWidth, nodeHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = Colors.orangeAccent,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: node.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: nodeWidth - 12);
    textPainter.paint(canvas, Offset(centerX + 6, y + 18));

    return totalWidth;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
