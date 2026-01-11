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
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: themeProvider.isLightMode 
                        ? themeProvider.primaryColor.withOpacity(0.1) 
                        : themeProvider.secondaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: themeProvider.isLightMode 
                          ? themeProvider.primaryColor 
                          : themeProvider.secondaryColor,
                      size: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      _buildDot(i, themeProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index, ThemeProvider themeProvider) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
          child: Transform.translate(
            offset: Offset(0, -4 * (0.5 + 0.5 * (1.0 - (animationController.value * 3 - index).abs().clamp(0.0, 1.0)))),
            child: Opacity(
              opacity: 0.6 + 0.4 * (1.0 - (animationController.value * 3 - index).abs().clamp(0.0, 1.0)),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
