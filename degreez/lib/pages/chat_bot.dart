import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import '../color/color_palette.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/pdf_attachment.dart';
import '../services/chat/gemini_chat_service.dart';
import '../services/chat/chat_storage_service.dart';
import '../services/chat/context_generator_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_header_widget.dart';
import '../widgets/chat/chat_input_widget.dart';
import '../widgets/chat/typing_indicator_widget.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  // Controllers and state
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];  bool _isLoading = false;
  bool _includeUserContext = true;
  bool _contextAutoEnabled = false;
  PdfAttachment? _currentPdfAttachment;
  
  // Services
  late GeminiChatService _chatService;
  late AnimationController _typingAnimationController;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _chatService = GeminiChatService();
    _firestoreService = FirestoreService();
    // Initialize typing animation
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Load chat history
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final loadedMessages = await ChatStorageService.loadChatHistory();
    setState(() {
      _messages.clear();
      _messages.addAll(loadedMessages);
    });

    if (_messages.isNotEmpty) {
      _chatService.rebuildChatSession(_messages);
    }

    // Add welcome message if no history
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I'm your AI assistant. I can help you with academic questions, course planning, study tips, and more. How can I assist you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }
  Future<String> _getCombinedUserContext() async {
    // Get context from providers (local session data)
    // final providerContext = ContextGeneratorService.generateUserContext(context);

    // Get context from Firestore (full academic history)
    final firestoreData = await _firestoreService.getFullStudentData();

    String firestoreContext = "";
    if (firestoreData.isNotEmpty) {
      // Remove the Id field from the data before displaying to user
      final dataWithoutId = Map<String, dynamic>.from(firestoreData);
      dataWithoutId.remove('Id');
      
      // The firestoreContextParts list was used to build a formatted,
      // human-readable string from the map. This is easier for the AI to
      // understand than a raw JSON string.
      // We can simplify this by encoding the map to a formatted
      // JSON string, which is also highly readable for the model.
      const jsonEncoder = JsonEncoder.withIndent('  ');
      final formattedJson = jsonEncoder.convert(dataWithoutId);

      firestoreContext = [
        "--- User Firebase Data ---",
        formattedJson,
        "--------------------------"
      ].join("\n");
    }

    // Combine local and Firestore contexts
    return firestoreContext;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Smart context detection
    await _handleContextDetection(userMessage);

    // Send message with streaming
    await _sendMessageWithStreaming(userMessage);
  }

  Future<void> _handleContextDetection(String userMessage) async {
    // Auto-disable context for non-academic questions
    if (_includeUserContext &&
        _contextAutoEnabled &&
        !ContextGeneratorService.containsContextRelevantKeywords(userMessage)) {
      setState(() {
        _includeUserContext = false;
        _contextAutoEnabled = false;
      });
      _showSnackBar('Context mode disabled automatically for general question');
    }
    // Auto-enable context for academic questions
    else if (!_includeUserContext) {
      final userContext = await _getCombinedUserContext();
      if (userContext.isNotEmpty &&
          ContextGeneratorService.containsContextRelevantKeywords(userMessage)) {
        setState(() {
          _includeUserContext = true;
          _contextAutoEnabled = true;
        });
        _showSnackBar(
            'Context mode enabled automatically for your course-related question');
      }
    }
  }  Future<void> _sendMessageWithStreaming(String userMessage) async {
    // Create message with PDF attachment if available
    final messageToAdd = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      pdfAttachment: _currentPdfAttachment,
    );
    
    setState(() {
      _messages.add(messageToAdd);
      _isLoading = true;
    });

    _scrollToBottom();
    _typingAnimationController.repeat();

    try {
      // Prepare message with context if enabled
      String finalMessage = userMessage;
      if (_includeUserContext) {
        final userContext = await _getCombinedUserContext();
        if (userContext.isNotEmpty) {
          finalMessage = "$userContext\nUser Question: $userMessage";
        }
      }

      // Choose stream method based on PDF attachment
      Stream<GenerateContentResponse> responseStream;
      if (_currentPdfAttachment != null) {
        responseStream = _chatService.sendMessageWithPdfStream(
          finalMessage, 
          _currentPdfAttachment!.file
        );
      } else {
        responseStream = _chatService.sendMessageStream(finalMessage);
      }

      String fullResponse = '';
      bool isFirstChunk = true;
      ChatMessage? responseMessage;

      await for (final chunk in responseStream) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          if (isFirstChunk) {
            fullResponse = chunk.text!;
            isFirstChunk = false;
            // Add the first response message
            responseMessage = ChatMessage(
              text: fullResponse,
              isUser: false,
              timestamp: DateTime.now(),
            );
            setState(() {
              _messages.add(responseMessage!);
            });
          } else {
            fullResponse += chunk.text!;
            // Update the existing response message
            setState(() {
              _messages.last = ChatMessage(
                text: fullResponse,
                isUser: false,
                timestamp: responseMessage!.timestamp,
              );
            });
          }
          _scrollToBottom();

          // Small delay to make streaming visible
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Ensure we have a response
      if (fullResponse.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I could not generate a response.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }

      // Clear PDF attachment after sending
      if (_currentPdfAttachment != null) {
        setState(() {
          _currentPdfAttachment = null;
        });
      }

      // Save chat history
      ChatStorageService.saveChatHistory(_messages);
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      // Always ensure loading state is cleared
      setState(() {
        _isLoading = false;
      });
      _typingAnimationController.stop();
    }
    _scrollToBottom();
  }

  void _clearChatHistory() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Hello! I'm your AI assistant. I can help you with academic questions, course planning, study tips, and more. How can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _chatService.clearSession();
    ChatStorageService.saveChatHistory(_messages);
  }

  void _showUserContextDialog() async {
    final userContext = await _getCombinedUserContext();
    showDialog(
      context: context,      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColorsDarkMode.mainColor, // Changed to night black
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              Icons.school,
              color: AppColorsDarkMode.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Academic Data',
              style: TextStyle(color: AppColorsDarkMode.textPrimary),
            ),
          ],
        ),        content: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          decoration: AppColorsDarkMode.surfaceDecoration(),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Text(
              userContext.isEmpty ? 'No academic data available to share.' : userContext,
              style: TextStyle(
                color: AppColorsDarkMode.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(color: AppColorsDarkMode.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppColorsDarkMode.textPrimary),
        ),
        backgroundColor: AppColorsDarkMode.surfaceColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  Future<void> _attachPdf() async {
    try {
      // Show loading indicator
      _showSnackBar('Selecting PDF file...');
      
      // Pick PDF file
      final file = await PdfService.pickPdfFile();
      if (file == null) return;
      
      // Show processing indicator
      _showSnackBar('Processing PDF file...');
      
      // Validate PDF
      final isValid = await PdfService.isValidPdf(file);
      if (!isValid) {
        _showSnackBar('Selected file is not a valid PDF.');
        return;
      }
      
      // Get PDF info (no text extraction needed)
      final pdfInfo = await PdfService.getPdfInfo(file);
        // Create PDF attachment
      final attachment = PdfAttachment(
        file: file,
        fileName: pdfInfo['fileName'],
        fileSize: pdfInfo['fileSize'],
        pageCount: 0, // Not needed anymore
        metadata: pdfInfo,
        attachedAt: DateTime.now(),
      );
      
      setState(() {
        _currentPdfAttachment = attachment;
      });
      
      _showSnackBar('PDF attached successfully! ${attachment.fileName}');
    } catch (e) {
      _showSnackBar('Error attaching PDF: ${e.toString()}');
    }
  }

  void _removePdfAttachment() {
    setState(() {
      _currentPdfAttachment = null;
    });
    _showSnackBar('PDF attachment removed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Column(
        children: [
          // Chat header
          ChatHeaderWidget(
            includeUserContext: _includeUserContext,
            isLoading: _isLoading,
            onToggleContext: () {
              setState(() {
                _includeUserContext = !_includeUserContext;
              });
            },
            onShowContextDialog: _showUserContextDialog,
            onClearChat: _clearChatHistory,
            typingAnimationController: _typingAnimationController,
            parentContext: context,
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return TypingIndicatorWidget(
                    animationController: _typingAnimationController,
                  );
                }
                return ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),
            // Message input
          ChatInputWidget(
            messageController: _messageController,
            includeUserContext: _includeUserContext,
            isLoading: _isLoading,
            onSendMessage: _sendMessage,
            onToggleContext: () {
              setState(() {
                _includeUserContext = true;
              });
            },
            onAttachPdf: _attachPdf,
            currentPdfAttachment: _currentPdfAttachment,
            onRemovePdf: _removePdfAttachment,
          ),
        ],
      ),
    );
  }
}
