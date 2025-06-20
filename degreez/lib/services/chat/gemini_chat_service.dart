import 'package:firebase_ai/firebase_ai.dart';
import '../../models/chat/chat_message.dart';

class GeminiChatService {
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  GeminiChatService() {
    _initializeModel();
  }

  void _initializeModel() {
    // Initialize the Gemini Developer API backend service with system instructions
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(
        "You are an AI assistant for DegreEZ, an academic planning app. "
        "Help students with course planning, academic advice, study tips, and education questions. "
        "When user context is provided, use it for personalized advice. "
        "Be helpful, concise, kind and academically focused."
      ),
    );
    
    _initializeChatSession();
  }

  void _initializeChatSession() {
    _chatSession = _model.startChat(
      history: [],
      // System instructions are built into the model configuration above
    );
  }  void rebuildChatSession(List<ChatMessage> messages) {
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
    _chatSession = _model.startChat(history: conversationHistory);
  }

  Stream<GenerateContentResponse> sendMessageStream(String message) {
    return _chatSession.sendMessageStream(Content.text(message));
  }

  void clearSession() {
    _initializeChatSession();
  }
}
