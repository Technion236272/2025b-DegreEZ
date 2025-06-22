import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import '../../models/chat/chat_message.dart';
import '../ai/base_ai_service.dart';
import '../ai/ai_config.dart';

class GeminiChatService extends BaseAiService {
  late ChatSession _chatSession;

  GeminiChatService() : super(
    modelName: AiConfig.defaultModel,
    systemInstruction: AiConfig.chatSystemInstruction,
  ) {
    _initializeChatSession();
  }

  void _initializeChatSession() {
    _chatSession = model.startChat(
      history: [],
      // System instructions are built into the model configuration above
    );
  }void rebuildChatSession(List<ChatMessage> messages) {
    // SDK handles context automatically, we just need to restore conversation history
    final conversationHistory = <Content>[];
    
    // Convert UI messages to SDK format (skip welcome message)
    final chatMessages = messages
        .where((msg) => !msg.text.contains('Hello! I\'m your AI assistant'))
        .toList();
    
    // Take recent conversation pairs for context
    for (final message in chatMessages) {
      if (message.isUser) {
        conversationHistory.add(Content.text(message.text));
      } else {
        // For model responses, use Content.model with TextPart
        conversationHistory.add(Content.model([TextPart(message.text)]));
      }
    }
      // Let SDK handle the rest
    _chatSession = model.startChat(history: conversationHistory);
  }
  Stream<GenerateContentResponse> sendMessageStream(String message) {
    return _chatSession.sendMessageStream(Content.text(message));
  }
  Stream<GenerateContentResponse> sendMessageWithPdfStream(String message, File pdfFile) async* {
    try {
      // Read PDF as bytes
      final pdfBytes = await pdfFile.readAsBytes();
        // Use base class method for streaming with file
      yield* generateContentStreamWithFile(
        prompt: message,
        fileBytes: pdfBytes,
        mimeType: AiConfig.pdfMimeType,
      );
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }

  void clearSession() {
    _initializeChatSession();
  }
}
