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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isLightMode 
                          ? [themeProvider.primaryColor, themeProvider.primaryColor.withOpacity(0.7)]
                          : [themeProvider.secondaryColor, themeProvider.secondaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DegreEZ AI',
                        style: TextStyle(
                          color: themeProvider.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Always here to help!',
                        style: TextStyle(
                          color: themeProvider.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      themeProvider: themeProvider,
                      icon: includeUserContext ? Icons.school : Icons.school_outlined,
                      isActive: includeUserContext,
                      onTap: onToggleContext,
                      tooltip: includeUserContext ? 'Context Active, let AI read your academic data' : 'Enable Context',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.data_usage,
                      isActive: false, 
                      onTap: onShowContextDialog,
                      tooltip: 'View Data',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context: context,
                      themeProvider: themeProvider,
                      icon: Icons.delete_outline,
                      isActive: false,
                      isDestructive: true,
                      onTap: () => _showClearChatDialog(context, themeProvider),
                      tooltip: 'Clear Chat',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    final Color iconColor = isDestructive 
        ? Colors.red.withOpacity(0.7)
        : isActive 
          ? (themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor)
          : themeProvider.textSecondary;
          
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive 
                  ? iconColor.withOpacity(0.1) 
                  : themeProvider.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? iconColor.withOpacity(0.2) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, ThemeProvider themeProvider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: themeProvider.surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: themeProvider.borderPrimary.withOpacity(0.5), width: 1),
            ),
            title: Row(
               children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Clear History',
                    style: TextStyle(
                        color: themeProvider.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
               ],
            ),
            content: Text(
              'Are you sure you want to delete all messages? This action cannot be undone.',
              style: TextStyle(color: themeProvider.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: themeProvider.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClearChat();
                },
                style: FilledButton.styleFrom(
                   backgroundColor: Colors.red.withOpacity(0.9),
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete All'),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          ),
        );
      },
    );
  }
}
