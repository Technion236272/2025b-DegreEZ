import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import '../../models/course_recommendation_models.dart';
import '../../models/optimization_models.dart';
import '../ai/ai_utils.dart';
import '../ai/ai_config.dart';

/// AI-Guided Hill Climbing Service for course optimization
///
/// This service implements hill climbing optimization where:
/// 1. AI evaluates solution quality contextually
/// 2. AI generates smart modifications (not random)
/// 3. AI selects best improvements systematically
/// 4. Maintains PDF and preference context throughout
class AiGuidedHillClimbingService {
  
  /// Main optimization method
  Future<List<CourseSet>> optimize({
    required List<CourseSet> initialSets,
    required List<dynamic> validCandidates,
    required CourseRecommendationRequest request,
    int maxIterations = 5,
  }) async {
    debugPrint('🔧 Starting AI-guided hill climbing optimization');
    debugPrint('📊 Initial sets: ${initialSets.length}');
    debugPrint('🎯 Valid candidates: ${validCandidates.length}');
    debugPrint('🔄 Max iterations: $maxIterations');
    debugPrint('🎓 Target semester: ${request.semesterDisplayName}');
    
    List<CourseSet> currentSets = List.from(initialSets);
    int improvementCount = 0;
    
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      debugPrint('\n🔄 === Hill Climbing Iteration ${iteration + 1}/$maxIterations ===');
      
      try {
        // Step 1: AI evaluates current solution quality
        debugPrint('📊 Step 1: Evaluating current solution quality...');
        final evaluation = await _evaluateCurrentSolution(currentSets, request);
        debugPrint('📊 Current solution score: ${evaluation.overallScore}/10');
        debugPrint('📊 Academic progression: ${evaluation.academicProgressionScore}/10');
        debugPrint('📊 Workload balance: ${evaluation.workloadBalanceScore}/10');
        debugPrint('📊 Preference alignment: ${evaluation.preferenceAlignmentScore}/10');
        debugPrint('📊 Availability: ${evaluation.availabilityScore}/10');
        
        if (evaluation.weaknesses.isNotEmpty) {
          debugPrint('⚠️ Identified weaknesses: ${evaluation.weaknesses.join(', ')}');
        }
        
        // Step 2: AI generates smart modifications
        debugPrint('💡 Step 2: Generating smart modifications...');
        final modifications = await _generateModifications(
          currentSets,
          validCandidates,
          evaluation,
          request,
        );
        debugPrint('💡 Generated ${modifications.length} potential modifications');
        
        for (int i = 0; i < modifications.length; i++) {
          final mod = modifications[i];
          debugPrint('💡 Modification ${i + 1}: ${mod.type} - ${mod.description} (Expected improvement: ${mod.expectedImprovement})');
        }
        
        // Step 3: AI selects best modification
        debugPrint('🎯 Step 3: Selecting best modification...');
        final bestModification = await _selectBestModification(
          modifications,
          currentSets,
          request,
        );
        
        // Step 4: Apply modification if it improves solution
        if (bestModification != null && bestModification.expectedImprovement > 0) {
          debugPrint('✅ Selected modification: ${bestModification.description}');
          debugPrint('🔧 Step 4: Applying modification...');
          
          currentSets = await _applyModification(currentSets, bestModification);
          improvementCount++;
          
          debugPrint('✅ Applied modification successfully');
          debugPrint('📈 Total improvements applied: $improvementCount');
        } else {
          debugPrint('🛑 No beneficial modification found');
          debugPrint('🎯 Stopping optimization early at iteration ${iteration + 1}');
          break;
        }
        
      } catch (e) {
        debugPrint('❌ Error in iteration ${iteration + 1}: $e');
        debugPrint('🔄 Continuing with next iteration...');
        continue;
      }
    }
    
    debugPrint('\n🎯 === Hill Climbing Optimization Complete ===');
    debugPrint('📊 Final sets count: ${currentSets.length}');
    debugPrint('📈 Total improvements applied: $improvementCount');
    debugPrint('✅ Optimization completed successfully');
    
    return currentSets;
  }
  
  /// AI evaluates current solution quality with full context
  Future<SolutionEvaluation> _evaluateCurrentSolution(
    List<CourseSet> currentSets,
    CourseRecommendationRequest request,
  ) async {
    debugPrint('📊 Starting solution evaluation...');
    
    try {
      final evaluationModel = FirebaseAI.googleAI().generativeModel(
        model: AiConfig.defaultModel,
        systemInstruction: Content.text(_getEvaluationSystemInstruction()),
        generationConfig: AiUtils.createJsonConfig(_createEvaluationSchema()),
      );
      
      final prompt = '''
Evaluate the quality of these course sets for optimization:

STUDENT CONTEXT:
${request.userContext}

TARGET SEMESTER: ${request.semesterDisplayName}

CURRENT COURSE SETS:
${jsonEncode(currentSets.map((set) => _courseSetToJson(set)).toList())}

EVALUATION CRITERIA:
1. Academic progression (degree requirements, prerequisites)
2. Workload balance (difficulty, credit distribution)
3. Course availability and scheduling
4. Overall strategic value

Provide detailed scores (1-10) and specific improvement suggestions.
''';
      
      debugPrint('🔧 Sending evaluation request to AI...');
      debugPrint('📄 Prompt length: ${prompt.length} characters');
      debugPrint('🎯 Sets to evaluate: ${currentSets.length}');
      
      final response = await _generateWithOptionalPdf(
        evaluationModel,
        prompt,
        request.catalogFilePath,
      );
      
      debugPrint('🤖 AI evaluation response received');
      debugPrint('📄 Response length: ${response.text?.length ?? 0} characters');
      
      final jsonData = jsonDecode(response.text ?? '{}');
      final evaluation = SolutionEvaluation.fromJson(jsonData);
      
      debugPrint('✅ Successfully parsed evaluation response');
      debugPrint('📊 Evaluation scores: Overall=${evaluation.overallScore}, Academic=${evaluation.academicProgressionScore}, Workload=${evaluation.workloadBalanceScore}');
      
      return evaluation;
      
    } catch (e) {
      debugPrint('❌ Error during evaluation: $e');
      debugPrint('🔄 Returning default evaluation');
      return SolutionEvaluation.defaultEvaluation();
    }
  }
  
  /// Generate smart modifications based on evaluation
  Future<List<CourseModification>> _generateModifications(
    List<CourseSet> currentSets,
    List<dynamic> validCandidates,
    SolutionEvaluation evaluation,
    CourseRecommendationRequest request,
  ) async {
    final modificationModel = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.defaultModel,
      systemInstruction: Content.text(_getModificationSystemInstruction()),
      generationConfig: AiUtils.createJsonConfig(_createModificationSchema()),
    );
    
    final prompt = '''
Based on the evaluation, suggest smart modifications to improve these course sets:

CURRENT EVALUATION:
${evaluation.toJson()}

CURRENT COURSE SETS:
${jsonEncode(currentSets.map((set) => _courseSetToJson(set)).toList())}

VALID REPLACEMENT CANDIDATES (ONLY USE THESE):
${jsonEncode(validCandidates.take(50).map((c) => _candidateToJson(c)).toList())}

STUDENT CONTEXT & PREFERENCES:
${request.userContext}

CRITICAL CONSTRAINT: 
🚨 ALL COURSE REPLACEMENTS MUST USE ONLY COURSES FROM THE VALID REPLACEMENT CANDIDATES LIST ABOVE
🚨 You CANNOT suggest courses that are not in the valid candidates list
🚨 Every course you suggest for addition must have its courseId present in the valid candidates

MODIFICATION REQUIREMENTS:
- Generate 3-5 specific modifications targeting evaluation weaknesses
- Each modification must specify:
  * Which course to REMOVE (removeId)
  * Which course to ADD (addId) - MUST be from valid candidates list
  * Clear reasoning for the swap
  * Expected improvement score
- Maintain 15-18 credit total per set
- Remember: Only use courses from the valid candidates list provided above!
- Do not suggest courses that are not in the valid candidates list

MODIFICATION TYPES:
1. **Course Swap**: Replace one course with another from valid candidates
2. **Course Removal**: Remove a course (set addId to null)
3. **Course Addition**: Add a course from valid candidates (set removeId to null)

Provide clear reasoning for each modification and expected improvement.
''';
    
    final response = await _generateWithOptionalPdf(
      modificationModel,
      prompt,
      request.catalogFilePath,
    );
    
    try {
      final jsonData = jsonDecode(response.text ?? '{}');
      final modifications = (jsonData['modifications'] as List)
          .map((m) => CourseModification.fromJson(m))
          .toList();
      
      // Additional validation: ensure all suggested courses are from valid candidates
      final validCourseIds = validCandidates.map((c) => 
        c['general']?['מספר מקצוע']?.toString() ?? ''
      ).toSet();
      
      final validatedModifications = modifications.where((mod) {
        if (mod.addId != null && !validCourseIds.contains(mod.addId)) {
          debugPrint('⚠️ Filtered out invalid modification: Suggested course ${mod.addId} not in valid candidates');
          return false;
        }
        return true;
      }).toList();
      
      debugPrint('✅ Validated ${validatedModifications.length} modifications against valid candidates');
      
      return validatedModifications;
    } catch (e) {
      debugPrint('❌ Error parsing modifications response: $e');
      return [];
    }
  }
  
  /// AI selects the best modification from candidates
  Future<CourseModification?> _selectBestModification(
    List<CourseModification> modifications,
    List<CourseSet> currentSets,
    CourseRecommendationRequest request,
  ) async {
    if (modifications.isEmpty) return null;
    
    // For now, select the modification with highest expected improvement
    // In future iterations, we can add AI-based selection logic
    modifications.sort((a, b) => b.expectedImprovement.compareTo(a.expectedImprovement));
    
    return modifications.first;
  }
  
  /// Apply a modification to the course sets
  Future<List<CourseSet>> _applyModification(
    List<CourseSet> currentSets,
    CourseModification modification,
  ) async {
    debugPrint('🔧 Applying modification: ${modification.description}');
    
    final modifiedSets = List<CourseSet>.from(currentSets);
    
    if (modification.setId >= 0 && modification.setId < modifiedSets.length) {
      final targetSet = modifiedSets[modification.setId];
      var updatedCourses = List<CourseInSet>.from(targetSet.courses);
      
      // Remove course if specified
      if (modification.removeId != null) {
        updatedCourses.removeWhere((course) => 
          course.courseId == modification.removeId
        );
        debugPrint('🗑️ Removed course: ${modification.removeId}');
      }
      
      // Add course if specified
      if (modification.addId != null && modification.addCourse != null) {
        final newCourse = CourseInSet(
          courseId: modification.addId!,
          courseName: modification.addCourse!['courseName'] ?? '',
        );
        updatedCourses.add(newCourse);
        debugPrint('➕ Added course: ${modification.addId}');
      }
      
      // Calculate new total credits
      double newTotalCredits = updatedCourses.length * 3.0; // Estimate 3 credits per course
      
      // Update the set
      modifiedSets[modification.setId] = CourseSet(
        setId: targetSet.setId,
        courses: updatedCourses,
        totalCredits: newTotalCredits,
        reasoning: '${targetSet.reasoning} | Modified: ${modification.description}',
      );
      
      debugPrint('✅ Successfully applied modification to set ${modification.setId}');
    } else {
      debugPrint('❌ Invalid setId: ${modification.setId}');
    }
    
    return modifiedSets;
  }
  
  /// Helper method to generate content with optional PDF
  Future<GenerateContentResponse> _generateWithOptionalPdf(
    GenerativeModel model,
    String prompt,
    String? catalogFilePath,
  ) async {
    debugPrint('🔧 Generating AI content with PDF: ${catalogFilePath != null ? 'Yes' : 'No'}');
    
    if (catalogFilePath != null && catalogFilePath.isNotEmpty) {
      final catalogFile = File(catalogFilePath);

      // Validate file before processing
      if (!await AiUtils.validateFileSize(catalogFile)) {
        debugPrint('❌ PDF file size validation failed');
        throw Exception(AiUtils.getFileSizeErrorMessage());
      }

      if (!await AiUtils.validatePdfFormat(catalogFile)) {
        debugPrint('❌ PDF format validation failed');
        throw Exception('Invalid PDF file format');
      }

      final catalogBytes = await catalogFile.readAsBytes();
      debugPrint('📄 PDF loaded successfully, size: ${catalogBytes.length} bytes');
      
      return await model.generateContent([
        AiUtils.createPdfContent(prompt, catalogBytes),
      ]);
    } else {
      debugPrint('💭 Generating text-only content');
      return await model.generateContent([Content.text(prompt)]);
    }
  }
  
  /// Convert CourseSet to JSON for AI processing
  Map<String, dynamic> _courseSetToJson(CourseSet set) {
    return {
      'setId': set.setId,
      'courses': set.courses.map((c) => c.toJson()).toList(),
      'totalCredits': set.totalCredits,
      'reasoning': set.reasoning,
    };
  }
  
  /// Convert candidate course to JSON for AI processing
  Map<String, dynamic> _candidateToJson(dynamic candidate) {
    return {
      'courseId': candidate['general']?['מספר מקצוע']?.toString() ?? '',
      'courseName': candidate['general']?['שם מקצוע']?.toString() ?? '',
      'creditPoints': (candidate['general']?['נקודות זכות'] as num?)?.toDouble() ?? 3.0,
      'faculty': candidate['general']?['פקולטה']?.toString() ?? '',
      'department': candidate['general']?['חוג']?.toString() ?? '',
    };
  }
  
  /// System instruction for evaluation
  String _getEvaluationSystemInstruction() {
    return '''
You are an expert academic advisor evaluating course set quality.
Provide objective, detailed assessments with specific scores and actionable feedback.
Focus on academic progression, workload balance, and student success.
''';
  }
  
  /// System instruction for modification generation
  String _getModificationSystemInstruction() {
    return '''
You are an expert academic optimizer generating course modifications.

CRITICAL RULES:
1. ALL course replacements must use ONLY courses from the provided valid candidates list
2. NEVER suggest courses that are not in the valid candidates list
3. Every courseId you suggest must be present in the valid candidates
4. Focus on solving specific problems identified in the evaluation
5. Maintain academic logic and credit balance

Create specific, actionable improvements that target evaluation weaknesses.
Each modification should provide measurable improvement while respecting all constraints.
''';
  }
  
  /// Create schema for evaluation responses
  Schema _createEvaluationSchema() {
    return Schema.object(
      properties: {
        'overallScore': Schema.number(description: 'Overall quality score 1-10'),
        'academicProgressionScore': Schema.number(description: 'Academic progression score 1-10'),
        'workloadBalanceScore': Schema.number(description: 'Workload balance score 1-10'),
        'preferenceAlignmentScore': Schema.number(description: 'Preference alignment score 1-10'),
        'availabilityScore': Schema.number(description: 'Course availability score 1-10'),
        'strengths': Schema.array(
          items: Schema.string(),
          description: 'List of current solution strengths'
        ),
        'weaknesses': Schema.array(
          items: Schema.string(),
          description: 'List of current solution weaknesses'
        ),
        'improvementSuggestions': Schema.array(
          items: Schema.string(),
          description: 'List of specific improvement suggestions'
        ),
      },
    );
  }
  
  /// Create schema for modification responses
  Schema _createModificationSchema() {
    return Schema.object(
      properties: {
        'modifications': Schema.array(
          items: Schema.object(
            properties: {
              'type': Schema.string(description: 'Type of modification: swap, add, remove, rebalance'),
              'description': Schema.string(description: 'Clear description of what this modification does'),
              'setId': Schema.integer(description: 'Index of the course set to modify (0-based)'),
              'removeId': Schema.string(description: 'Course ID to remove (optional)'),
              'addId': Schema.string(description: 'Course ID to add (optional)'),
              'addCourse': Schema.object(
                properties: {
                  'courseId': Schema.string(),
                  'courseName': Schema.string(),
                },
                description: 'Course details to add (optional)'
              ),
              'reasoning': Schema.string(description: 'Detailed reasoning for this modification'),
              'expectedImprovement': Schema.number(description: 'Expected improvement score (0-10)'),
            },
          ),
        ),
      },
    );
  }
}