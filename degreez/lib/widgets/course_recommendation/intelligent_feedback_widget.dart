// lib/widgets/course_recommendation/intelligent_feedback_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_recommendation_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/course_recommendation_provider.dart';

class IntelligentFeedbackWidget extends StatefulWidget {
  final List<CourseSet> currentRecommendations;
  final Function(UserFeedback feedback) onFeedbackSubmitted;

  const IntelligentFeedbackWidget({
    super.key,
    required this.currentRecommendations,
    required this.onFeedbackSubmitted,
  });

  @override
  State<IntelligentFeedbackWidget> createState() => _IntelligentFeedbackWidgetState();
}

class _IntelligentFeedbackWidgetState extends State<IntelligentFeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.question;
  String? _selectedCourseId;
  String? _selectedSetId;
  bool _isSubmitting = false;
  bool _showConversationLog = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with conversation toggle
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Improve Your Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Clear conversation button
                if (_showConversationLog) ...[
                  Consumer<CourseRecommendationProvider>(
                    builder: (context, provider, child) {
                      final hasConversation = provider.getConversationHistory().isNotEmpty;
                      if (!hasConversation) return const SizedBox();
                      return IconButton(
                        icon:                        Icon(
                          Icons.clear_all,
                          color: themeProvider.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _showClearConversationDialog(context);
                        },
                        tooltip: 'Clear conversation history',
                      );
                    },
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _showConversationLog ? Icons.expand_less : Icons.expand_more,
                    color: themeProvider.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConversationLog = !_showConversationLog;
                    });
                  },
                  tooltip: _showConversationLog ? 'Hide conversation' : 'Show conversation',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Ask questions or request specific course replacements:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
            
            const SizedBox(height: 16),

            // Conversation Log (expandable)
            if (_showConversationLog) ...[
              _buildConversationLog(themeProvider),
              const SizedBox(height: 16),
            ],

            // Simple Action Buttons
            _buildSimpleActionButtons(themeProvider),
            
            const SizedBox(height: 16),

            // Course Selector (only for replace)
            if (_selectedType == FeedbackType.replace) ...[
              _buildCourseSelector(themeProvider),
              const SizedBox(height: 12),
            ],

            // Input field with smart hints
            _buildSmartInputField(themeProvider),
            
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_selectedType == FeedbackType.replace ? Icons.swap_horiz : Icons.send),
                label: Text(_isSubmitting ? 'Processing...' : _getSubmitButtonText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationLog(ThemeProvider themeProvider) {
    return Consumer<CourseRecommendationProvider>(
      builder: (context, provider, child) {
        final conversation = provider.getConversationHistory();
        
        if (conversation.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: themeProvider.borderPrimary),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: themeProvider.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'No conversation yet. Start by asking a question!',
                  style: TextStyle(color: themeProvider.textSecondary),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: themeProvider.borderPrimary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withAlpha(26),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: themeProvider.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Conversation History',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: conversation.length,
                  itemBuilder: (context, index) {
                    final message = conversation[index];
                    return _buildConversationBubble(message, themeProvider);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationBubble(ConversationMessage message, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: message.isUser                ? themeProvider.primaryColor
                : themeProvider.textSecondary,
            child: Icon(
              message.isUser ? Icons.person : Icons.smart_toy,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? themeProvider.primaryColor.withAlpha(26)
                    : themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show feedback type for user messages
                  if (message.isUser && message.feedback != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: message.feedback!.type == FeedbackType.replace 
                            ? Colors.orange.withAlpha(51)
                            : themeProvider.primaryColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.feedback!.type == FeedbackType.replace 
                            ? '🔄 Course Replacement'
                            : '❓ Question',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: message.feedback!.type == FeedbackType.replace 
                              ? Colors.orange[700]
                              : themeProvider.primaryColor,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActionButtons(ThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Ask Question',
            FeedbackType.question,
            Icons.help_outline,
            themeProvider.primaryColor,
            'Ask about recommendations, courses, or get explanations',
            themeProvider,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Replace Course',
            FeedbackType.replace,
            Icons.swap_horiz,
            themeProvider.warningColor,
            'Request to replace a specific course',
            themeProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, FeedbackType type, IconData icon, Color color, String tooltip, ThemeProvider themeProvider) {
    final isSelected = _selectedType == type;
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCourseId = null;
            _selectedSetId = null;
            _feedbackController.clear();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(26) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : themeProvider.borderPrimary,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : themeProvider.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : themeProvider.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which course would you like to replace?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Set Selector
        DropdownButtonFormField<String>(
          value: _selectedSetId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            labelText: 'Select Set',
          ),
          items: widget.currentRecommendations.map((set) {
            return DropdownMenuItem(
              value: set.setId.toString(),
              child: Text('Set ${set.setId} (${set.totalCredits.toStringAsFixed(1)} credits)'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSetId = value;
              _selectedCourseId = null;
            });
          },
        ),
        
        if (_selectedSetId != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelText: 'Select Course to Replace',
            ),
            items: _getCoursesForSet(_selectedSetId!).map((course) {
              return DropdownMenuItem(
                value: course.courseId,
                child: Text('${course.courseId} - ${course.courseName}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourseId = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSmartInputField(ThemeProvider themeProvider) {
    return TextField(
      controller: _feedbackController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: _getSmartHintText(),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        prefixIcon: Icon(
          _selectedType == FeedbackType.question ? Icons.help_outline : Icons.swap_horiz,
          color: themeProvider.primaryColor,
        ),
      ),
    );
  }

  List<CourseInSet> _getCoursesForSet(String setId) {
    try {
      final setIdInt = int.parse(setId);
      final set = widget.currentRecommendations.firstWhere(
        (s) => s.setId == setIdInt,
      );
      return set.courses;
    } catch (e) {
      return [];
    }
  }

  String _getSmartHintText() {
    switch (_selectedType) {
      case FeedbackType.question:
        return 'Ask me anything about these recommendations...\nExample: "Why was this course recommended?" or "What prerequisites do I need?"';
      case FeedbackType.replace:
        if (_selectedCourseId == null) {
          return 'First select a course to replace above, then explain what you want instead...';
        }
        return 'What course would you prefer instead? Please specify the course name or explain your preference...';
    }
  }

  String _getSubmitButtonText() {
    switch (_selectedType) {
      case FeedbackType.question:
        return 'Ask Question';
      case FeedbackType.replace:
        return 'Request Replacement';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message')),
      );
      return;
    }

    if (_selectedType == FeedbackType.replace && _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course to replace')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build intelligent message based on type
      String intelligentMessage = _buildIntelligentMessage();

      final feedback = UserFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        message: intelligentMessage,
        courseId: _selectedCourseId,
        setId: _selectedSetId,
        timestamp: DateTime.now(),
      );

      await widget.onFeedbackSubmitted(feedback);

      // Clear form but keep type selected for easy follow-up
      _feedbackController.clear();
      setState(() {
        _selectedCourseId = null;
        _selectedSetId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _buildIntelligentMessage() {
    final userInput = _feedbackController.text.trim();
    
    switch (_selectedType) {
      case FeedbackType.question:
        return userInput;
        
      case FeedbackType.replace:
        if (_selectedCourseId != null) {
          final course = _getCoursesForSet(_selectedSetId!).firstWhere(
            (c) => c.courseId == _selectedCourseId,
          );
          return 'I want to replace course ${course.courseId} (${course.courseName}). $userInput';
        }
        return 'Course replacement request: $userInput';
    }
  }

  String _getSuccessMessage() {
    switch (_selectedType) {
      case FeedbackType.question:
        return '🤖 Question sent! Getting answer...';
      case FeedbackType.replace:
        return '🔄 Replacement request sent! Finding alternatives...';
    }
  }

  void _showClearConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear the conversation history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CourseRecommendationProvider>().clearConversationHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation history cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
