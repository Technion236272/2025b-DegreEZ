import 'package:flutter/material.dart';
import '../../color/color_palette.dart';

class ChatHeaderWidget extends StatelessWidget {
  final bool includeUserContext;
  final bool isLoading;
  final VoidCallback onToggleContext;
  final VoidCallback onShowContextDialog;
  final VoidCallback onClearChat;
  final AnimationController typingAnimationController;
  final BuildContext parentContext;

  const ChatHeaderWidget({
    super.key,
    required this.includeUserContext,
    required this.isLoading,
    required this.onToggleContext,
    required this.onShowContextDialog,
    required this.onClearChat,
    required this.typingAnimationController,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: AppColorsDarkMode.cardDecoration(
        backgroundColor: AppColorsDarkMode.surfaceColor,
        elevated: true,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsDarkMode.overlayMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColorsDarkMode.borderAccent,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColorsDarkMode.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your academic companion',
                    style: TextStyle(
                      color: AppColorsDarkMode.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // User context toggle button
            Tooltip(
              message: includeUserContext 
                  ? 'Context mode enabled - AI can access your course data\nTap to disable'
                  : 'Context mode disabled - AI works with general knowledge only\nTap to enable',
              child: Container(
                decoration: BoxDecoration(
                  color: includeUserContext 
                      ? AppColorsDarkMode.primaryColor.withOpacity(0.1)
                      : AppColorsDarkMode.overlayLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: includeUserContext 
                        ? AppColorsDarkMode.primaryColor
                        : AppColorsDarkMode.borderSecondary,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onToggleContext,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        includeUserContext ? Icons.school : Icons.school_outlined,
                        color: includeUserContext 
                            ? AppColorsDarkMode.primaryColor
                            : AppColorsDarkMode.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Preview context data button
            Tooltip(
              message: 'Preview what data can be shared with AI',
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.overlayLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColorsDarkMode.borderSecondary,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onShowContextDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.preview,
                        color: AppColorsDarkMode.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Clear chat button
            Container(
              decoration: BoxDecoration(
                color: AppColorsDarkMode.overlayLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorsDarkMode.borderSecondary,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showClearChatDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.refresh,
                      color: AppColorsDarkMode.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedBuilder(
                  animation: typingAnimationController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.primaryColor.withOpacity(typingAnimationController.value),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  void _showClearChatDialog() {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        backgroundColor: AppColorsDarkMode.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Clear Chat History',
          style: TextStyle(color: AppColorsDarkMode.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all chat messages?',
          style: TextStyle(color: AppColorsDarkMode.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsDarkMode.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClearChat();
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColorsDarkMode.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
