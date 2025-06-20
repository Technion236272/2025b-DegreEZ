import 'package:flutter/material.dart';
import '../../color/color_palette.dart';
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
    return Column(
      children: [
        // PDF Attachment Preview
        if (currentPdfAttachment != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: AppColorsDarkMode.cardDecoration(
              backgroundColor: AppColorsDarkMode.cardColor,
              withBorder: true,
            ).copyWith(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: AppColorsDarkMode.primaryColor,
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
                          color: AppColorsDarkMode.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),                      Text(
                        formatFileSize(currentPdfAttachment!.fileSize),
                        style: TextStyle(
                          color: AppColorsDarkMode.textSecondary,
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
                    color: AppColorsDarkMode.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
                // PDF Attachment Button
                if (onAttachPdf != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: isLoading ? null : onAttachPdf,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: AppColorsDarkMode.cardDecoration(
                          backgroundColor: currentPdfAttachment != null 
                              ? AppColorsDarkMode.primaryColor.withOpacity(0.2)
                              : AppColorsDarkMode.mainColor,
                          withBorder: true,
                        ).copyWith(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.attach_file,
                          color: currentPdfAttachment != null 
                              ? AppColorsDarkMode.primaryColor
                              : AppColorsDarkMode.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: AppColorsDarkMode.cardDecoration(
                      backgroundColor: AppColorsDarkMode.mainColor,
                      withBorder: true,
                    ).copyWith(
                      borderRadius: BorderRadius.circular(25),
                    ),child: TextField(
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
                              ? AppColorsDarkMode.textTertiary.withOpacity(0.5)
                              : AppColorsDarkMode.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        color: isLoading 
                            ? AppColorsDarkMode.textTertiary
                            : AppColorsDarkMode.textPrimary,
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
                _buildSmartSendButton(),
              ],
            ),
          ),
        ),      ],
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  Widget _buildSmartSendButton() {
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
            gradient: isLoading 
                ? LinearGradient(
                    colors: [
                      AppColorsDarkMode.textTertiary.withOpacity(0.4),
                      AppColorsDarkMode.textTertiary.withOpacity(0.3),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppColorsDarkMode.primaryColor,
                      AppColorsDarkMode.primaryColorLight,
                    ],
                  ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: isLoading 
                ? []
                : [
                    BoxShadow(
                      color: AppColorsDarkMode.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,            child: InkWell(
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
                            ? AppColorsDarkMode.textTertiary
                            : AppColorsDarkMode.textPrimary,
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
