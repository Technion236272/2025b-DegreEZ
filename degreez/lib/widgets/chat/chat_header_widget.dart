import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode 
                    ? Colors.black.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeProvider.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: themeProvider.primaryColor,
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
                          color: themeProvider.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your academic companion',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
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
                          ? themeProvider.primaryColor.withOpacity(0.1)
                          : themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: includeUserContext 
                            ? themeProvider.primaryColor
                            : themeProvider.borderPrimary,
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
                                ? themeProvider.primaryColor
                                : themeProvider.textSecondary,
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
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: themeProvider.borderPrimary,
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
                            color: themeProvider.primaryColor,
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
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.borderPrimary,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showClearChatDialog(context, themeProvider),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.refresh,
                          color: themeProvider.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),            
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearChatDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: themeProvider.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Clear Chat History',
          style: TextStyle(color: themeProvider.textPrimary),
        ),
        content: Text(
          'Are you sure you want to clear all chat messages?',
          style: TextStyle(color: themeProvider.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: themeProvider.secondaryColor),
            ),
          ),
          TextButton(
                          style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return context.read<ThemeProvider>().accentColor;
      }
      return context.read<ThemeProvider>().accentColor;
    }),
                  ),
            onPressed: () {
              Navigator.pop(dialogContext);
              onClearChat();
            },
            child: Text(
              'Clear',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
