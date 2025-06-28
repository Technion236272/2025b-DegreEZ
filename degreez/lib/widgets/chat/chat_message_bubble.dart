import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themeProvider.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeProvider.isLightMode ? themeProvider.primaryColor.withAlpha(76) : themeProvider.secondaryColor.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor,
                    size: 16,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? themeProvider.isLightMode ? themeProvider.secondaryColor : themeProvider.accentColor 
                        : themeProvider.surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PDF Attachment (show before text for user messages)
                      if (message.isUser && message.pdfAttachment != null)
                        _buildPdfAttachment(themeProvider),
                      
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser 
                              ? Colors.white 
                              : themeProvider.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      
                      // PDF Attachment (show after text for AI messages, if any)
                      if (!message.isUser && message.pdfAttachment != null)
                        _buildPdfAttachment(themeProvider),
                      
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser 
                              ? Colors.white.withAlpha(204) 
                              : themeProvider.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themeProvider.isLightMode ? themeProvider.secondaryColor : themeProvider.accentColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeProvider.isLightMode ? themeProvider.secondaryColor.withAlpha(76) : themeProvider.accentColor.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPdfAttachment(ThemeProvider themeProvider) {
    if (message.pdfAttachment == null) return const SizedBox.shrink();
    
    final attachment = message.pdfAttachment!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser 
            ? Colors.white.withAlpha(51)
            : themeProvider.cardColor.withAlpha(178),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: message.isUser 
              ? Colors.white.withAlpha(76)
              : themeProvider.isLightMode ? themeProvider.primaryColor.withAlpha(76) : themeProvider.secondaryColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: message.isUser 
                ? Colors.white
                : themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    color: message.isUser 
                        ? Colors.white
                        : themeProvider.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFileSize(attachment.fileSize),
                  style: TextStyle(
                    color: message.isUser 
                        ? Colors.white.withAlpha(204)
                        : themeProvider.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
