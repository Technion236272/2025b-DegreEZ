import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../color/color_palette.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Chat history management
  static const int _maxContextMessages = 10; // Keep last 10 messages for context
  late ChatSession _chatSession;

  late final GenerativeModel _model;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  @override
  void initState() {
    super.initState();
    // Initialize the Gemini Developer API backend service
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');
    
    // Initialize chat session for context management
    _chatSession = _model.startChat(history: []);
    
    // Initialize typing animation
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingAnimationController, curve: Curves.easeInOut),
    );
    
    // Load previous chat history
    _loadChatHistory().then((_) {
      // If no history loaded, add welcome message
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Hello! I'm your AI assistant. I can help you with academic questions, course planning, study tips, and more. How can I assist you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();
    _typingAnimationController.repeat();

    try {
      // Use chat session to maintain context
      final response = await _chatSession.sendMessage(Content.text(userMessage));
        setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? 'Sorry, I could not generate a response.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      // Clean up old messages to prevent context overflow
      _cleanupOldMessages();
      
      // Save chat history after successful response
      _saveChatHistory();
      
      _typingAnimationController.stop();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _typingAnimationController.stop();
      _scrollToBottom();
    }
  }
  void _cleanupOldMessages() {
    // Keep only the last _maxContextMessages in the chat session
    // This prevents the context from growing too large
    if (_messages.length > _maxContextMessages + 5) { // +5 for buffer
      // We keep the messages in the UI but the API will only use recent context
      // The ChatSession automatically manages context, but we can restart it if needed
      final recentMessages = _messages
          .skip(_messages.length - _maxContextMessages)
          .where((msg) => !msg.text.contains('Hello! I\'m your AI assistant'))
          .toList();
      
      if (recentMessages.length >= 4) { // Ensure we have enough context
        // Create new chat session with recent context
        final history = <Content>[];
        for (int i = 0; i < recentMessages.length - 1; i += 2) {
          if (i + 1 < recentMessages.length) {
            history.add(Content.text(recentMessages[i].text));
            history.add(Content.model([TextPart(recentMessages[i + 1].text)]));
          }
        }
        _chatSession = _model.startChat(history: history);
      }
    }
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
    // Start fresh chat session
    _chatSession = _model.startChat(history: []);
    _saveChatHistory(); // Save the cleared state
  }
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((message) => message.toJson()).toList();
      await prefs.setString('chat_history', json.encode(messagesJson));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('chat_history');
      if (historyString != null) {
        final messagesJson = json.decode(historyString) as List;
        final loadedMessages = messagesJson
            .map((messageData) => ChatMessage.fromJson(messageData))
            .toList();
        
        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
        });

        // Rebuild chat session with recent context for continuity
        _rebuildChatSession();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }
  void _rebuildChatSession() {
    // Rebuild chat session with recent messages for context continuity
    final recentMessages = _messages
        .where((msg) => !msg.text.contains('Hello! I\'m your AI assistant'))
        .toList();
    
    // Take last _maxContextMessages
    final contextMessages = recentMessages.length > _maxContextMessages 
        ? recentMessages.sublist(recentMessages.length - _maxContextMessages)
        : recentMessages;
    
    if (contextMessages.length >= 2) {
      final history = <Content>[];
      for (int i = 0; i < contextMessages.length - 1; i += 2) {
        if (i + 1 < contextMessages.length && 
            contextMessages[i].isUser && 
            !contextMessages[i + 1].isUser) {
          history.add(Content.text(contextMessages[i].text));
          history.add(Content.model([TextPart(contextMessages[i + 1].text)]));
        }
      }
      _chatSession = _model.startChat(history: history);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDarkMode.mainColor,
      body: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorsDarkMode.accentColor,
                  AppColorsDarkMode.accentColorDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.secondaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: AppColorsDarkMode.secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            color: AppColorsDarkMode.secondaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your academic companion',
                          style: TextStyle(
                            color: AppColorsDarkMode.secondaryColorDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),                  ),
                  const SizedBox(width: 12),
                  // Clear chat button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColorsDarkMode.accentColorDark,
                              title: Text(
                                'Clear Chat History',
                                style: TextStyle(color: AppColorsDarkMode.secondaryColor),
                              ),
                              content: Text(
                                'Are you sure you want to clear all chat messages?',
                                style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _clearChatHistory();
                                  },
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(color: AppColorsDarkMode.secondaryColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.refresh,
                            color: AppColorsDarkMode.secondaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedBuilder(
                        animation: _typingAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColorsDarkMode.secondaryColor.withOpacity(_typingAnimation.value),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
                color: AppColorsDarkMode.accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColorsDarkMode.secondaryColor,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColorsDarkMode.secondaryColor 
                    : AppColorsDarkMode.accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? AppColorsDarkMode.accentColor 
                          : AppColorsDarkMode.secondaryColor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? AppColorsDarkMode.accentColorDim 
                          : AppColorsDarkMode.secondaryColorDim,
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
                color: AppColorsDarkMode.secondaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                color: AppColorsDarkMode.accentColor,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.smart_toy,
              color: AppColorsDarkMode.secondaryColor,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++)
                  AnimatedBuilder(
                    animation: _typingAnimationController,
                    builder: (context, child) {
                      final delay = i * 0.2;
                      final animationValue = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
                      return Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: Transform.translate(
                          offset: Offset(0, -4 * (1 - (1 - animationValue).abs())),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColorsDarkMode.secondaryColorDim,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsDarkMode.accentColorDark,
        border: Border(
          top: BorderSide(
            color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.mainColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about your studies...',
                    hintStyle: TextStyle(
                      color: AppColorsDarkMode.secondaryColorDim,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    color: AppColorsDarkMode.secondaryColor,
                    fontSize: 16,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColorsDarkMode.secondaryColor,
                    AppColorsDarkMode.secondaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsDarkMode.secondaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send,
                      color: AppColorsDarkMode.accentColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

