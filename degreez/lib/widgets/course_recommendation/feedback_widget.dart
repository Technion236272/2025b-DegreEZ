// lib/widgets/course_recommendation/feedback_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_recommendation_models.dart';
import '../../providers/theme_provider.dart';

class FeedbackWidget extends StatefulWidget {
  final List<CourseSet> currentRecommendations;
  final Function(UserFeedback feedback) onFeedbackSubmitted;

  const FeedbackWidget({
    super.key,
    required this.currentRecommendations,
    required this.onFeedbackSubmitted,
  });

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.general;
  String? _selectedCourseId;
  String? _selectedSetId;
  bool _isSubmitting = false;

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
            // Header
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: themeProvider.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Provide Feedback',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Help me improve the recommendations by sharing your thoughts:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),

            // Quick Action Buttons
            _buildQuickActionButtons(),
            
            const SizedBox(height: 16),

            // Feedback Type Selector
            _buildFeedbackTypeSelector(),
            
            const SizedBox(height: 12),

            // Course/Set Selector (if specific feedback)
            if (_selectedType != FeedbackType.general) ...[
              _buildTargetSelector(),
              const SizedBox(height: 12),
            ],

            // Feedback Text Input
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _getHintText(),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            
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
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Processing...' : 'Send Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickButton(
          '👍 Like recommendations',
          FeedbackType.like,
          Colors.green,
        ),
        _buildQuickButton(
          '👎 Don\'t like',
          FeedbackType.dislike,
          Colors.red,
        ),
        _buildQuickButton(
          '🔄 Replace a course',
          FeedbackType.replace,
          Colors.orange,
        ),
        _buildQuickButton(
          '✏️ Modify suggestions',
          FeedbackType.modify,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, FeedbackType type, Color color) {
    final isSelected = _selectedType == type;
    
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _selectedType = type;
          if (type == FeedbackType.like) {
            _feedbackController.text = 'I like these recommendations!';
          } else if (type == FeedbackType.dislike) {
            _feedbackController.text = 'I don\'t like these recommendations because...';
          }
        });
      },
      backgroundColor: isSelected ? color.withOpacity(0.2) : null,
      side: BorderSide(
        color: isSelected ? color : Colors.grey,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildFeedbackTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback Type:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<FeedbackType>(
          value: _selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: FeedbackType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getFeedbackTypeLabel(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
                _selectedCourseId = null;
                _selectedSetId = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedType == FeedbackType.replace 
              ? 'Which course to replace?'
              : 'About which course/set?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Course Set Selector
        DropdownButtonFormField<String>(
          value: _selectedSetId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            labelText: 'Course Set (Optional)',
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All sets')),
            ...widget.currentRecommendations.map((set) {
              return DropdownMenuItem(
                value: set.setId.toString(),
                child: Text('Set ${set.setId} (${set.totalCredits} credits)'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSetId = value;
              _selectedCourseId = null; // Reset course selection
            });
          },
        ),
        
        const SizedBox(height: 8),
        
        // Course Selector (if set is selected)
        if (_selectedSetId != null) ...[
          DropdownButtonFormField<String>(
            value: _selectedCourseId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelText: 'Specific Course (Optional)',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Entire set')),
              ...(_getCoursesForSet(_selectedSetId!).map((course) {
                return DropdownMenuItem(
                  value: course.courseId,
                  child: Text('${course.courseId} - ${course.courseName}'),
                );
              })),
            ],
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

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.like:
        return '👍 Like';
      case FeedbackType.dislike:
        return '👎 Dislike';
      case FeedbackType.replace:
        return '🔄 Replace Course';
      case FeedbackType.modify:
        return '✏️ Modify';
      case FeedbackType.general:
        return '💬 General Feedback';
    }
  }

  String _getHintText() {
    switch (_selectedType) {
      case FeedbackType.like:
        return 'What do you like about these recommendations?';
      case FeedbackType.dislike:
        return 'What don\'t you like? What would you prefer instead?';
      case FeedbackType.replace:
        return 'Which course would you prefer instead? Why?';
      case FeedbackType.modify:
        return 'How would you like to modify the recommendations?';
      case FeedbackType.general:
        return 'Share any thoughts or suggestions about the recommendations...';
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = UserFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        message: _feedbackController.text.trim(),
        courseId: _selectedCourseId,
        setId: _selectedSetId,
        timestamp: DateTime.now(),
      );

      await widget.onFeedbackSubmitted(feedback);

      // Clear form
      _feedbackController.clear();
      setState(() {
        _selectedType = FeedbackType.general;
        _selectedCourseId = null;
        _selectedSetId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted! Processing your request...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
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
}
