import 'package:flutter/material.dart';
import '../../color/color_palette.dart';

class TypingIndicatorWidget extends StatelessWidget {
  final AnimationController animationController;

  const TypingIndicatorWidget({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColorsDarkMode.borderAccent,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.smart_toy,
              color: AppColorsDarkMode.primaryColor,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppColorsDarkMode.surfaceDecoration().copyWith(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      final delay = i * 0.2;
                      final animationValue = (animationController.value - delay).clamp(0.0, 1.0);
                      return Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: Transform.translate(
                          offset: Offset(0, -4 * (1 - (1 - animationValue).abs())),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColorsDarkMode.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
