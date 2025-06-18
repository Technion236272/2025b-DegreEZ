import 'package:flutter/material.dart';
import '../../color/color_palette.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController messageController;
  final bool includeUserContext;
  final bool isLoading;
  final VoidCallback onSendMessage;
  final VoidCallback? onToggleContext;

  const ChatInputWidget({
    super.key,
    required this.messageController,
    required this.includeUserContext,
    required this.isLoading,
    required this.onSendMessage,
    this.onToggleContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simplified context indicator
        if (includeUserContext)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.overlayLight,
              border: Border(
                top: BorderSide(
                  color: AppColorsDarkMode.borderSecondary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColorsDarkMode.overlayMedium,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorsDarkMode.borderAccent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppColorsDarkMode.primaryColor,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Course data sharing enabled',
                    style: TextStyle(
                      color: AppColorsDarkMode.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onToggleContext != null)
                  GestureDetector(
                    onTap: onToggleContext,
                    child: Icon(
                      Icons.close,
                      color: AppColorsDarkMode.textSecondary,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColorsDarkMode.surfaceDecoration().copyWith(
            border: Border(
              top: BorderSide(
                color: AppColorsDarkMode.borderSecondary,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: AppColorsDarkMode.cardDecoration(
                      backgroundColor: AppColorsDarkMode.mainColor,
                      withBorder: true,
                    ).copyWith(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: includeUserContext 
                            ? 'Ask me anything about your studies... :)'
                            : 'Ask me anything... :)',
                        hintStyle: TextStyle(
                          color: AppColorsDarkMode.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: AppColorsDarkMode.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => onSendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Smart Send Button
                _buildSmartSendButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSendButton() {
    final hasText = messageController.text.trim().isNotEmpty;
    final shouldShowContextOption = !includeUserContext && hasText;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Context toggle button (only when auto-context is off and there's text)
        if (shouldShowContextOption && onToggleContext != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onToggleContext,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: AppColorsDarkMode.cardDecoration(
                  backgroundColor: AppColorsDarkMode.mainColor,
                  withBorder: true,
                ).copyWith(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: AppColorsDarkMode.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        // Main send button
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColorsDarkMode.primaryColor,
                AppColorsDarkMode.primaryColorLight,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColorsDarkMode.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: isLoading ? null : () {
                if (messageController.text.trim().isNotEmpty) {
                  onSendMessage();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isLoading ? Icons.hourglass_empty : Icons.send,
                      color: AppColorsDarkMode.textPrimary,
                      size: 20,
                    ),
                    // Small context indicator
                    if (includeUserContext && !isLoading)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColorsDarkMode.mainColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColorsDarkMode.textPrimary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
