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
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: themeProvider.borderPrimary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                        size: 24,
                      ),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: themeProvider.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // PDF Attachment Button
                    if (onAttachPdf != null)
                      Container(
                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                        child: IconButton(
                          onPressed: isLoading ? null : onAttachPdf,
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: currentPdfAttachment != null
                                ? themeProvider.primaryColor
                                : themeProvider.textSecondary,
                            size: 28,
                          ),
                          tooltip: 'Attach PDF',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeProvider.mainColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: themeProvider.borderPrimary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 120, 
                          ),
                          child: TextField(
                            controller: messageController,
                            scrollController:
                                ScrollController(), 
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              hintText: isLoading
                                  ? 'Thinking...'
                                  : 'Message...',
                              hintStyle: TextStyle(
                                color: themeProvider.textSecondary.withOpacity(0.7),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              color: themeProvider.textPrimary,
                              fontSize: 16,
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted:
                                (_) => !isLoading ? onSendMessage() : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Smart Send Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _buildSmartSendButton(themeProvider),
                    ),
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Widget _buildSmartSendButton(ThemeProvider themeProvider) {
    final hasText = messageController.text.trim().isNotEmpty;
    final shouldShowContextOption =
        !includeUserContext && hasText && !isLoading;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (shouldShowContextOption && onToggleContext != null)
            Padding(
               padding: const EdgeInsets.only(right: 8),
               child: IconButton(
                  onPressed: onToggleContext,
                  icon: Icon(
                    Icons.school_outlined,
                    color: themeProvider.textSecondary,
                    size: 24,
                   ),
                  tooltip: 'Enable Context',
               )
            ),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onSendMessage,
            borderRadius: BorderRadius.circular(30),
            child: Container(
               width: 48,
               height: 48,
               decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoading 
                      ? [themeProvider.textSecondary.withOpacity(0.5), themeProvider.textSecondary.withOpacity(0.5)]
                      : themeProvider.isLightMode
                          ? [themeProvider.primaryColor, themeProvider.secondaryColor]
                          : [themeProvider.secondaryColor, themeProvider.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: isLoading ? [] : [
                    BoxShadow(
                       color: (themeProvider.isLightMode ? themeProvider.primaryColor : themeProvider.secondaryColor).withOpacity(0.3),
                       blurRadius: 8,
                       offset: const Offset(0, 4),
                    )
                  ]
               ),
               child: Icon(
                  isLoading ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 24,
               ),
            ),
          ),
        ),
      ],
    );
  }
}
