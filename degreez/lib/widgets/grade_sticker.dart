import 'package:degreez/providers/customized_diagram_notifier.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class GradeSticker extends StatefulWidget {
  final String grade;
  const GradeSticker({super.key, required this.grade});

  @override
  State<GradeSticker> createState() => _GradeStickerState();
}

class _GradeStickerState extends State<GradeSticker> {  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      widget.grade.trim(),
      style: TextStyle(
        color: context.watch<CustomizedDiagramNotifier>().cardColorPalette!.cardFG(Provider.of<ThemeProvider>(context).isDarkMode),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
      maxLines: 1,
      minFontSize: 6,
      overflow: TextOverflow.ellipsis,
    );
  }
}
