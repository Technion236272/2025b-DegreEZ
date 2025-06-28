import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/chat/pdf_attachment.dart';

class ChatInputWidget extends StatelessWidget {
  final TextEditingController messageController;
  final bool includeUserContext;
  final bool isLoading;
  final VoidCallback onSendMessage;
  final VoidCallback? onToggleContext;
  final VoidCallback? onAttachPdf;
  final PdfAttachment? currentPdfAttachment;
  final VoidCallback? onRemovePdf;

  const ChatInputWidget({
    super.key,
    required this.messageController,
    required this.includeUserContext,
    required this.isLoading,
    required this.onSendMessage,
    this.onToggleContext,
    this.onAttachPdf,
    this.currentPdfAttachment,
    this.onRemovePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            // PDF Attachment Preview
            if (currentPdfAttachment != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.borderPrimary,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: themeProvider.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPdfAttachment!.fileName,
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatFileSize(currentPdfAttachment!.fileSize),
                            style: TextStyle(
                              color: themeProvider.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemovePdf,
                      icon: Icon(
                        Icons.close,
                        color: themeProvider.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: themeProvider.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // PDF Attachment Button
                    if (onAttachPdf != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: isLoading ? null : onAttachPdf,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: currentPdfAttachment != null 
                                  ? themeProvider.primaryColor.withOpacity(0.2)
                                  : themeProvider.mainColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeProvider.borderPrimary,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.attach_file,
                              color: currentPdfAttachment != null 
                                  ? themeProvider.primaryColor
                                  : themeProvider.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeProvider.mainColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: themeProvider.borderPrimary,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: messageController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: isLoading 
                                ? 'Processing your message...'
                                : includeUserContext 
                                    ? 'Ask me anything about your studies... :)'
                                    : 'Ask me anything... :)',
                            hintStyle: TextStyle(
                              color: isLoading 
                                  ? themeProvider.textSecondary.withOpacity(0.5)
                                  : themeProvider.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(
                            color: isLoading 
                                ? themeProvider.textSecondary
                                : themeProvider.textPrimary,
                            fontSize: 16,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => !isLoading ? onSendMessage() : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Smart Send Button
                    _buildSmartSendButton(themeProvider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  Widget _buildSmartSendButton(ThemeProvider themeProvider) {
    final hasText = messageController.text.trim().isNotEmpty;
    final shouldShowContextOption = !includeUserContext && hasText && !isLoading;
    
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
                decoration: BoxDecoration(
                  color: themeProvider.mainColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeProvider.borderPrimary,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: themeProvider.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        // Main send button
        Container(
          decoration: BoxDecoration(
            gradient: isLoading 
                ? LinearGradient(
                    colors: [
                      themeProvider.textSecondary.withOpacity(0.4),
                      themeProvider.textSecondary.withOpacity(0.3),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.accentColor,
                      themeProvider.isLightMode ? themeProvider.primaryColor.withOpacity(0.8) :themeProvider.accentColor.withOpacity(0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: isLoading 
                ? []
                : [
                    BoxShadow(
                      color: themeProvider.isDarkMode 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: isLoading ? null : onSendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isLoading ? Icons.stop_circle_outlined : Icons.send,
                        key: ValueKey(isLoading),
                        color: isLoading 
                            ? themeProvider.textSecondary
                            : themeProvider.mainColor,
                        size: 20,
                      ),
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
                            color: themeProvider.mainColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
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
