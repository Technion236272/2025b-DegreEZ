import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GradeSticker extends StatefulWidget {
  final String grade;
  const GradeSticker({super.key, required this.grade});

  @override
  State<GradeSticker> createState() => _GradeStickerState();
}

class _GradeStickerState extends State<GradeSticker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG, width: 1), // background color
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
              widget.grade.trim(),
              style: TextStyle(color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG,fontSize: 7, fontWeight: FontWeight.w900),
            ),
      ),
    );
  }
}
