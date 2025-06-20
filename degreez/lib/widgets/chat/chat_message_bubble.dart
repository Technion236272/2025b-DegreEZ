import 'package:flutter/material.dart';
import '../../color/color_palette.dart';
import '../../models/chat/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppColorsDarkMode.cardDecoration(
                backgroundColor: message.isUser 
                    ? AppColorsDarkMode.primaryColor 
                    : AppColorsDarkMode.surfaceColor,
                elevated: true,
              ).copyWith(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Attachment (show before text for user messages)
                  if (message.isUser && message.pdfAttachment != null)
                    _buildPdfAttachment(),
                  
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? AppColorsDarkMode.textPrimary 
                          : AppColorsDarkMode.textPrimary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  
                  // PDF Attachment (show after text for AI messages, if any)
                  if (!message.isUser && message.pdfAttachment != null)
                    _buildPdfAttachment(),
                  
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? AppColorsDarkMode.textSecondary 
                          : AppColorsDarkMode.textSecondary,
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
                color: AppColorsDarkMode.primaryColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColorsDarkMode.borderAccent,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                color: AppColorsDarkMode.textPrimary,
                size: 16,
              ),
            ),
          ],
        ],
      ),    );
  }

  Widget _buildPdfAttachment() {
    if (message.pdfAttachment == null) return const SizedBox.shrink();
    
    final attachment = message.pdfAttachment!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isUser 
            ? AppColorsDarkMode.primaryColorLight.withOpacity(0.3)
            : AppColorsDarkMode.cardColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: message.isUser 
              ? AppColorsDarkMode.textPrimary.withOpacity(0.3)
              : AppColorsDarkMode.borderAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: message.isUser 
                ? AppColorsDarkMode.textPrimary
                : AppColorsDarkMode.primaryColor,
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
                        ? AppColorsDarkMode.textPrimary
                        : AppColorsDarkMode.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),                Text(
                  _formatFileSize(attachment.fileSize),
                  style: TextStyle(
                    color: message.isUser 
                        ? AppColorsDarkMode.textSecondary
                        : AppColorsDarkMode.textSecondary,
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
