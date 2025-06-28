import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/chat/chat_message.dart';

class ChatStorageService {
  static const String _chatHistoryKey = 'chat_history';

  static Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((message) => {
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
      }).toList();
      await prefs.setString(_chatHistoryKey, json.encode(messagesJson));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  static Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_chatHistoryKey);
      if (historyString != null) {
        final messagesJson = json.decode(historyString) as List;
        return messagesJson.map((messageData) => ChatMessage(
          text: messageData['text'],
          isUser: messageData['isUser'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(messageData['timestamp']),
        )).toList();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
    return [];
  }

  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatHistoryKey);
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }
}
