import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat/chat_message.dart';
import 'package:flutter/services.dart'; // for Clipboard

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment:
                message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser) ...[
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
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isUser
                            ? themeProvider.isLightMode
                                ? themeProvider.secondaryColor
                                : themeProvider.accentColor
                            : themeProvider.surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(message.isUser ? 24 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PDF Attachment (show before text for user messages)
                      if (message.isUser && message.pdfAttachment != null)
                        _buildPdfAttachment(themeProvider),

                      SelectableText(
                        message.text,
                        style: TextStyle(
                          color:
                              message.isUser
                                  ? Colors.white
                                  : themeProvider.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        contextMenuBuilder: (context, editableTextState) {
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: editableTextState.contextMenuAnchors,
                            buttonItems:
                                editableTextState.contextMenuButtonItems,
                          );
                        },
                      ),

                      // PDF Attachment (show after text for AI messages, if any)
                      if (!message.isUser && message.pdfAttachment != null)
                        _buildPdfAttachment(themeProvider),

                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color:
                                  message.isUser
                                      ? Colors.white.withOpacity(0.7)
                                      : themeProvider.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!message.isUser) ...[
                             const SizedBox(width: 8),
                            InkWell(
                              onTap: (){
                                Clipboard.setData(ClipboardData(text: message.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Copied to clipboard!", style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.black87,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: themeProvider.textSecondary.withOpacity(0.5),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Removed the redundant user icon
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
        color:
            message.isUser
                ? Colors.white.withAlpha(51)
                : themeProvider.cardColor.withAlpha(178),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              message.isUser
                  ? Colors.white.withAlpha(76)
                  : themeProvider.isLightMode
                  ? themeProvider.primaryColor.withAlpha(76)
                  : themeProvider.secondaryColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            color:
                message.isUser
                    ? Colors.white
                    : themeProvider.isLightMode
                    ? themeProvider.primaryColor
                    : themeProvider.secondaryColor,
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
                    color:
                        message.isUser
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
                    color:
                        message.isUser
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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
