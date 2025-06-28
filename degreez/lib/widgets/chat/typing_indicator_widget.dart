import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TypingIndicatorWidget extends StatelessWidget {
  final AnimationController animationController;

  const TypingIndicatorWidget({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeProvider.primaryColor.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: themeProvider.primaryColor,
                  size: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode 
                          ? Colors.black.withAlpha(51)
                          : Colors.grey.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                                  color: themeProvider.textSecondary,
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
      },
    );
  }
}
