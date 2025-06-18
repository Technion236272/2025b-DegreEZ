import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../color/color_palette.dart';
import '../providers/student_provider.dart';
import '../providers/course_provider.dart';

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

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  // Smart Context Detection Feature:
  // The AI page now intelligently detects when course-related keywords are used
  // and automatically enables context mode only when relevant, rather than always.
  // It also automatically disables context mode when switching to general questions.
  // This preserves user privacy while still providing contextual assistance when needed.
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _includeUserContext = true; // Toggle for including user context
  bool _contextAutoEnabled = false; // Track if context was automatically enabled
  
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
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
    
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
  }  // Generate user context for AI prompts
  String _generateUserContext() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    final student = studentProvider.student;
    final coursesBySemester = courseProvider.coursesBySemester;
    
    if (student == null) {
      return "";
    }
    
    final contextParts = <String>[
      "--- User Academic Context ---",
      "Student Name: ${student.name}",
      "Major: ${student.major}",
      "Faculty: ${student.faculty}",
      "Current Semester: ${student.semester}",
      "Catalog: ${student.catalog}",
      "Preferences: ${student.preferences}",
    ];
    
    if (coursesBySemester.isNotEmpty) {
      contextParts.add("\n--- Course Information by Semester ---");
      
      for (final entry in coursesBySemester.entries) {
        final semesterKey = entry.key;
        final courses = entry.value;
          if (courses.isNotEmpty) {
          contextParts.add("\nSemester $semesterKey:");
          for (final course in courses) {
            final courseInfo = [
              "  • ${course.name} (${course.courseId})",
              if (course.finalGrade.isNotEmpty) "Grade: ${course.finalGrade}",
              "Credits: ${course.creditPoints}",
              if (course.note != null && course.note!.isNotEmpty) "Note: ${course.note}",
            ].join(", ");
            contextParts.add(courseInfo);
          }
        }
      }
    }
      contextParts.add("\n--- End Context ---\n");
    return contextParts.join("\n");
  }  // Check if user message contains context-relevant keywords
  bool _containsContextRelevantKeywords(String message) {
    final lowercaseMessage = message.toLowerCase();
    
    // Academic/course-related keywords
    final contextKeywords = [
      // Direct course references
      'my courses', 'my course', 'course', 'courses',
      'my classes', 'classes', 'class',
      
      // Degree and academic program references
      'my degree', 'my major', 'degree', 'major',
      'my program', 'program', 'study program',
      
      // Semester and time references
      'semester', 'semesters', 'my semester',
      'this semester', 'next semester', 'current semester',
      
      // Grades and performance
      'my grades', 'grades', 'gpa', 'my gpa',
      'grade point', 'academic performance',
      
      // Schedule and planning
      'my schedule', 'schedule', 'timetable',
      'study plan', 'academic plan',
      
      // Institution references
      'my faculty', 'faculty', 'my department',
      'my university', 'my college',
      
      // Academic records
      'my catalog', 'catalog', 'course catalog',
      'my preferences', 'preferences',
      'my transcript', 'transcript',
      'academic record', 'student record',
      
      // Credits and requirements
      'credit points', 'credits', 'credit hours',
      'graduation', 'graduate', 'graduation requirements',
      'degree requirements', 'my requirements',
      
      // Curriculum references
      'curriculum', 'study plan', 'course plan',
      'academic path', 'degree path',
      
      // Status and progress
      'my progress', 'progress', 'academic progress',
      'my status', 'student status',
      'enrollment', 'enrolled', 'registration',
      
      // Course types and categories
      'requirements', 'requirement', 'required courses',
      'electives', 'elective', 'optional courses',
      'prerequisite', 'prerequisites', 'pre-req',
      'core courses', 'mandatory courses', 'compulsory',
      
      // Academic advice seeking
      'should i take', 'what courses', 'which courses',
      'recommend courses', 'suggest courses',
      'plan my', 'help me plan', 'advice on',
      
      // Personal academic references
      'what am i', 'what have i', 'how many',
      'do i need', 'can i graduate', 'when will i',
      'my academic', 'my studies',
    ];
    
    return contextKeywords.any((keyword) => lowercaseMessage.contains(keyword));
  }  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    // Check if we should auto-disable context mode for non-academic questions
    if (_includeUserContext && _contextAutoEnabled && !_containsContextRelevantKeywords(userMessage)) {
      // Auto-disable context for non-academic questions if it was auto-enabled
      setState(() {
        _includeUserContext = false;
        _contextAutoEnabled = false;
      });
      
      // Show a brief message to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Context mode disabled automatically for general question',
            style: TextStyle(color: AppColorsDarkMode.secondaryColor),
          ),
          backgroundColor: AppColorsDarkMode.accentColorDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    // Check if toggle is off but we should turn it on based on keywords
    else if (!_includeUserContext) {
      final userContext = _generateUserContext();
      if (userContext.isNotEmpty && _containsContextRelevantKeywords(userMessage)) {
        // Automatically turn on the toggle only for relevant queries
        setState(() {
          _includeUserContext = true;
          _contextAutoEnabled = true;
        });
        
        // Show a brief message to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Context mode enabled automatically for your course-related question',
              style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
            backgroundColor: AppColorsDarkMode.accentColorDark,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
    
    await _sendMessageWithContext(userMessage);
  }// Enhanced send message with user context
  Future<void> _sendMessageWithContext(String userMessage) async {
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
      // Check if we should include user context
      String finalMessage = userMessage;
      // Include context if toggle is on
      if (_includeUserContext) {
        final userContext = _generateUserContext();
        if (userContext.isNotEmpty) {
          finalMessage = "$userContext\nUser Question: $userMessage";
        }
      }

      // Use chat session to maintain context
      final response = await _chatSession.sendMessage(Content.text(finalMessage));
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
      _scrollToBottom();    }
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
      final messagesJson = _messages.map((message) => {
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
      }).toList();
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
        final loadedMessages = messagesJson.map((messageData) => ChatMessage(
          text: messageData['text'],
          isUser: messageData['isUser'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(messageData['timestamp']),
        )).toList();
        
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
  // Show user context preview dialog
  void _showUserContextDialog() {
    final userContext = _generateUserContext();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColorsDarkMode.accentColorDark,
        title: Row(
          children: [
            Icon(
              Icons.school,
              color: AppColorsDarkMode.secondaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Your Academic Data',
              style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 400),
          child: SingleChildScrollView(
            child: Text(
              userContext.isEmpty ? 'No academic data available to share.' : userContext,
              style: TextStyle(
                color: AppColorsDarkMode.secondaryColorDim,
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
              style: TextStyle(color: AppColorsDarkMode.secondaryColor),
            ),
          ),
        ],
      ),
    );
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
                  const SizedBox(width: 8),                  // User context toggle button
                  Tooltip(
                    message: _includeUserContext 
                        ? 'Context mode enabled - AI can access your course data\nTap to disable'
                        : 'Context mode disabled - AI cannot access your course data\nWill auto-enable for course-related questions\nTap to enable manually',
                    child: Container(
                      decoration: BoxDecoration(
                        color: _includeUserContext 
                            ? AppColorsDarkMode.secondaryColor.withOpacity(0.2)
                            : AppColorsDarkMode.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),                          onTap: () {
                            setState(() {
                              _includeUserContext = !_includeUserContext;
                              _contextAutoEnabled = false; // Reset auto-enabled flag when manually toggled
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _includeUserContext ? Icons.school : Icons.school_outlined,
                              color: _includeUserContext 
                                  ? AppColorsDarkMode.secondaryColor
                                  : AppColorsDarkMode.secondaryColorDim,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),                  ),
                  const SizedBox(width: 8),
                  // Preview context data button
                  Tooltip(
                    message: 'Preview what data can be shared with AI',
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _showUserContextDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.preview,
                              color: AppColorsDarkMode.secondaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
  }  Widget _buildMessageInput() {
    return Column(
      children: [        // Simplified context indicator
        if (_includeUserContext)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColorsDarkMode.secondaryColor.withOpacity(0.05),
              border: Border(
                top: BorderSide(
                  color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColorsDarkMode.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school,
                    color: AppColorsDarkMode.secondaryColor,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Course data sharing enabled',
                    style: TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _includeUserContext = false;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: AppColorsDarkMode.secondaryColorDim,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        // Message input
        Container(
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
                    ),                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _includeUserContext 
                            ? 'Ask me anything about your studies...'
                            : 'Ask me anything... (Long press send for course data)',
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
                      onSubmitted: (_) => _sendMessage(),                    ),
                  ),
                ),                const SizedBox(width: 8),
                // Smart Send Button with Context Toggle
                _buildSmartSendButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSendButton() {
    final hasText = _messageController.text.trim().isNotEmpty;
    final shouldShowContextOption = !_includeUserContext && hasText;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Context toggle button (only when auto-context is off and there's text)
        if (shouldShowContextOption)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _includeUserContext = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorsDarkMode.mainColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColorsDarkMode.secondaryColorDim.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: AppColorsDarkMode.secondaryColorDim,
                  size: 18,
                ),
              ),
            ),
          ),
        
        // Main send button with smart behavior
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
            color: Colors.transparent,            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _isLoading ? null : () {
                if (_messageController.text.trim().isNotEmpty) {
                  _sendMessage();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send,
                      color: AppColorsDarkMode.accentColor,
                      size: 20,
                    ),
                    // Small context indicator
                    if (_includeUserContext && !_isLoading)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColorsDarkMode.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColorsDarkMode.secondaryColor,
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

