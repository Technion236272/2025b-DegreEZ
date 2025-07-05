/// Models for AI-guided hill climbing optimization

/// Model for evaluating solution quality
class SolutionEvaluation {
  final double overallScore;
  final double academicProgressionScore;
  final double workloadBalanceScore;
  final double preferenceAlignmentScore;
  final double availabilityScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> improvementSuggestions;
  
  SolutionEvaluation({
    required this.overallScore,
    required this.academicProgressionScore,
    required this.workloadBalanceScore,
    required this.preferenceAlignmentScore,
    required this.availabilityScore,
    required this.strengths,
    required this.weaknesses,
    required this.improvementSuggestions,
  });

  factory SolutionEvaluation.fromJson(Map<String, dynamic> json) {
    return SolutionEvaluation(
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 5.0,
      academicProgressionScore: (json['academicProgressionScore'] as num?)?.toDouble() ?? 5.0,
      workloadBalanceScore: (json['workloadBalanceScore'] as num?)?.toDouble() ?? 5.0,
      preferenceAlignmentScore: (json['preferenceAlignmentScore'] as num?)?.toDouble() ?? 5.0,
      availabilityScore: (json['availabilityScore'] as num?)?.toDouble() ?? 5.0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      improvementSuggestions: List<String>.from(json['improvementSuggestions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'academicProgressionScore': academicProgressionScore,
      'workloadBalanceScore': workloadBalanceScore,
      'preferenceAlignmentScore': preferenceAlignmentScore,
      'availabilityScore': availabilityScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvementSuggestions': improvementSuggestions,
    };
  }
  
  /// Create a default evaluation for error cases
  static SolutionEvaluation defaultEvaluation() {
    return SolutionEvaluation(
      overallScore: 5.0,
      academicProgressionScore: 5.0,
      workloadBalanceScore: 5.0,
      preferenceAlignmentScore: 5.0,
      availabilityScore: 5.0,
      strengths: ['Current solution is stable'],
      weaknesses: ['Unable to evaluate due to technical issues'],
      improvementSuggestions: ['Continue with current solution'],
    );
  }
}

/// Model for course modification suggestions
class CourseModification {
  final String type; // "swap", "add", "remove", "rebalance"
  final String description;
  final int setId;
  final String? removeId;
  final String? addId;
  final Map<String, dynamic>? addCourse;
  final String reasoning;
  final double expectedImprovement;
  
  CourseModification({
    required this.type,
    required this.description,
    required this.setId,
    this.removeId,
    this.addId,
    this.addCourse,
    required this.reasoning,
    required this.expectedImprovement,
  });

  factory CourseModification.fromJson(Map<String, dynamic> json) {
    return CourseModification(
      type: json['type'] ?? 'swap',
      description: json['description'] ?? '',
      setId: json['setId'] ?? 0,
      removeId: json['removeId'],
      addId: json['addId'],
      addCourse: json['addCourse'],
      reasoning: json['reasoning'] ?? '',
      expectedImprovement: (json['expectedImprovement'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'setId': setId,
      'removeId': removeId,
      'addId': addId,
      'addCourse': addCourse,
      'reasoning': reasoning,
      'expectedImprovement': expectedImprovement,
    };
  }
}
