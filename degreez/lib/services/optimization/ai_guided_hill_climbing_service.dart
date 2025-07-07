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
  



// --------------- THE OPTIMIZATION PROCESS ---------------
  /// Main optimization method - processes each set individually
  Future<List<CourseSet>> optimize({
    required List<CourseSet> initialSets,
    required List<dynamic> validCandidates,
    required CourseRecommendationRequest request,
    int maxIterations = 5,
    bool fastMode = false, // Fast mode parameter
  }) async {
    if (fastMode) {
      debugPrint('⚡ AI-guided hill climbing: FAST MODE - returning initial sets directly');
      debugPrint('📊 Initial sets: ${initialSets.length}');
      debugPrint('✅ Fast mode optimization complete');
      return initialSets;
    }
    
    debugPrint('🔧 Starting AI-guided hill climbing optimization (Individual Set Processing)');
    debugPrint('📊 Initial sets: ${initialSets.length}');
    debugPrint('🎯 Valid candidates: ${validCandidates.length}');
    debugPrint('🔄 Max iterations per set: $maxIterations');
    debugPrint('🎓 Target semester: ${request.semesterDisplayName}');
    
    final optimizedSets = <CourseSet>[];
    int totalImprovements = 0;
    
    // Process each set individually
    for (int setIndex = 0; setIndex < initialSets.length; setIndex++) {
      final currentSet = initialSets[setIndex];
      debugPrint('\n🎯 === Processing Set ${setIndex + 1}/${initialSets.length} ===');
      debugPrint('� Set reasoning: ${currentSet.reasoning}');
      debugPrint('📊 Set courses: ${currentSet.courses.length}');
      
      try {
        // Optimize individual set
        final optimizedSet = await _optimizeIndividualSet(
          currentSet,
          validCandidates,
          request,
          maxIterations,
          fastMode, // Pass fastMode parameter
        );
        
        optimizedSets.add(optimizedSet);
        
        // Count improvements (compare original vs optimized)
        if (optimizedSet.reasoning.contains('Modified:')) {
          totalImprovements++;
        }
        
        debugPrint('✅ Set ${setIndex + 1} optimization complete');
        
      } catch (e) {
        debugPrint('❌ Error optimizing set ${setIndex + 1}: $e');
        debugPrint('🔄 Using original set as fallback');
        optimizedSets.add(currentSet);
      }
    }
    
    debugPrint('\n🎯 === Hill Climbing Optimization Complete ===');
    debugPrint('📊 Final sets count: ${optimizedSets.length}');
    debugPrint('📈 Sets with improvements: $totalImprovements');
    debugPrint('✅ Optimization completed successfully (validation done per iteration)');
    
    return optimizedSets;
  }
  
  /// AI evaluates current solution quality with full context
  Future<SolutionEvaluation> _evaluateCurrentSolution(
    List<CourseSet> currentSets,
    CourseRecommendationRequest request,
    bool fastMode, // Add fastMode parameter
  ) async {
    debugPrint('📊 Starting solution evaluation...');
    
    try {
      final evaluationModel = FirebaseAI.googleAI().generativeModel(
        model: fastMode ? AiConfig.defaultModel : AiConfig.optimizationModel, // Use appropriate model
        systemInstruction: Content.text(_getEvaluationSystemInstruction()),
        generationConfig: AiUtils.createJsonConfig(_createEvaluationSchema()),
      );
      
      final prompt = '''
Evaluate the quality of ${currentSets.length == 1 ? 'this course set' : 'these course sets'} for optimization:

STUDENT CONTEXT:
${request.userContext}

TARGET SEMESTER: ${request.semesterDisplayName}

CURRENT COURSE ${currentSets.length == 1 ? 'SET' : 'SETS'}:
${jsonEncode(currentSets.map((set) => _courseSetToJson(set)).toList())}

EVALUATION CRITERIA:
1. Academic progression (degree requirements, prerequisites)
2. Workload balance (difficulty, credit distribution)
3. Course availability and scheduling
4. Overall strategic value

${currentSets.length == 1 ? 'Focus on evaluating this single set\'s internal coherence and quality.' : 'Evaluate each set individually and provide overall assessment.'}

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
  /// the number of modifications is limited to 3-5 per set
  /// and they must use only valid candidates.
  Future<List<CourseModification>> _generateModifications(
    List<CourseSet> currentSets,
    List<dynamic> validCandidates,
    SolutionEvaluation evaluation,
    CourseRecommendationRequest request,
    String validationFeedback, // NEW: Include validation feedback
    bool fastMode, // Add fastMode parameter
  ) async {
    final modificationModel = FirebaseAI.googleAI().generativeModel(
      model: fastMode ? AiConfig.defaultModel : AiConfig.optimizationModel, // Use appropriate model
      systemInstruction: Content.text(_getModificationSystemInstruction()),
      generationConfig: AiUtils.createJsonConfig(_createModificationSchema()),
    );
    
    final prompt = '''
            Based on the evaluation, suggest smart modifications to improve ${currentSets.length == 1 ? 'this course set' : 'these course sets'}:

            CURRENT EVALUATION:
            ${evaluation.toJson()}

            CURRENT COURSE ${currentSets.length == 1 ? 'SET' : 'SETS'}:
            ${jsonEncode(currentSets.map((set) => _courseSetToJson(set)).toList())}

            VALID REPLACEMENT CANDIDATES (ONLY USE THESE):
            ${jsonEncode(validCandidates.map((c) => _candidateToJson(c)).toList())}

            STUDENT CONTEXT & PREFERENCES:
            ${request.userContext}

            CRITICAL CONSTRAINT: 
            🚨 ALL COURSE REPLACEMENTS MUST USE ONLY COURSES FROM THE VALID REPLACEMENT CANDIDATES LIST ABOVE
            🚨 You CANNOT suggest courses that are not in the valid candidates list
            🚨 Every course you suggest for addition must have its courseId present in the valid candidates${validationFeedback.isNotEmpty ? '\n\n⚠️ VALIDATION FEEDBACK FROM PREVIOUS ITERATIONS:$validationFeedback' : ''}

            MODIFICATION REQUIREMENTS:
            - Generate 3-5 specific modifications targeting evaluation weaknesses
            - Each modification must specify:
              * Which course to REMOVE (removeId)
              * Which course to ADD (addId) - MUST be from valid candidates list
              * Clear reasoning for the swap
              * Expected improvement score
              * setId: ${currentSets.length == 1 ? '0 (single set being optimized)' : 'Index of the set to modify'}
            - Maintain 15-18 credit total per set (by adding or swapping or removing courses)
            - Remember: Only use courses from the valid candidates list provided above!
            - Do not suggest courses that are not in the valid candidates list

            MODIFICATION TYPES:
            1. **Course Swap**: Replace one course with another from valid candidates
            2. **Course Removal**: Remove a course (set addId to null)
            3. **Course Addition**: Add a course or more from valid candidates (set removeId to null)

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
  /// This method modifies the course sets based on the provided modification details.
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
          creditPoints: (modification.addCourse!['creditPoints'] as num?)?.toDouble() ?? 3.0,
        );
        updatedCourses.add(newCourse);
        debugPrint('➕ Added course: ${modification.addId}');
      }
      
      // Calculate new total credits by summing actual credit points
      double newTotalCredits = updatedCourses.fold(0.0, (sum, course) => sum + course.creditPoints);
      
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
  
  /// Optimize a single course set using ai guided hill climbing
  Future<CourseSet> _optimizeIndividualSet(
    CourseSet initialSet,
    List<dynamic> validCandidates,
    CourseRecommendationRequest request,
    int maxIterations,
    bool fastMode, // Add fastMode parameter
  ) async {
    debugPrint('🔧 Starting individual set optimization');
    debugPrint('📊 Set ID: ${initialSet.setId}');
    debugPrint('🎯 Courses in set: ${initialSet.courses.length}');
    debugPrint('📝 Set reasoning: ${initialSet.reasoning}');
    
    CourseSet currentSet = initialSet;
    int improvementCount = 0;
    String validationFeedback = ''; // Track validation feedback across iterations
    
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      debugPrint('\n🔄 Set ${initialSet.setId} - Iteration ${iteration + 1}/$maxIterations');
      
      try {
        // Wrap single set in a list for existing methods
        final currentSets = [currentSet];
        
        // Step 1: AI evaluates current set quality
        debugPrint('📊 Step 1: Evaluating set quality...');
        final evaluation = await _evaluateCurrentSolution(currentSets, request, fastMode);
        debugPrint('📊 Set score: ${evaluation.overallScore}/10');
        debugPrint('📊 Academic: ${evaluation.academicProgressionScore}/10');
        debugPrint('📊 Workload: ${evaluation.workloadBalanceScore}/10');
        
        if (evaluation.weaknesses.isNotEmpty) {
          debugPrint('⚠️ Weaknesses: ${evaluation.weaknesses.join(', ')}');
        }
        
        // Step 2: AI generates smart modifications
        debugPrint('💡 Step 2: Generating modifications...');
        final modifications = await _generateModifications(
          currentSets,
          validCandidates,
          evaluation,
          request,
          validationFeedback, // Pass validation feedback from previous iterations
          fastMode, // Pass fastMode parameter
        );
        debugPrint('💡 Generated ${modifications.length} potential modifications');
        
        // Step 3: AI selects best modification
        debugPrint('🎯 Step 3: Selecting best modification...');
        final bestModification = await _selectBestModification(
          modifications,
          currentSets,
          request,
        );
        
        // Step 4: Apply modification if it improves solution
        if (bestModification != null && bestModification.expectedImprovement > 0) {
          debugPrint('✅ Selected: ${bestModification.description}');
          debugPrint('🔧 Step 4: Applying modification...');
          
          final modifiedSets = await _applyModification(currentSets, bestModification);
          if (modifiedSets.isNotEmpty) {
            // Step 5: Validate and clean the modified set immediately
            debugPrint('🔍 Step 5: Validating modified set...');
            final cleanedSets = _validateAndCleanSets(modifiedSets, validCandidates);
            if (cleanedSets.isNotEmpty) {
              // Track courses that were removed during validation
              final originalCourseIds = modifiedSets[0].courses.map((c) => c.courseId).toSet();
              final cleanedCourseIds = cleanedSets[0].courses.map((c) => c.courseId).toSet();
              final removedCourses = originalCourseIds.difference(cleanedCourseIds);
              
              if (removedCourses.isNotEmpty) {
                final removedInfo = removedCourses.join(', ');
                validationFeedback += '\nPrevious iteration removed invalid courses: $removedInfo (not found in valid candidates)';
                debugPrint('📝 Updated validation feedback: $removedInfo');
              }
              
              currentSet = cleanedSets[0]; // Take the cleaned set
              improvementCount++;
              debugPrint('✅ Modification applied and validated successfully');
            } else {
              debugPrint('❌ Modification resulted in empty set after validation, keeping original');
            }
          }
        } else {
          debugPrint('🛑 No beneficial modification found');
          debugPrint('🎯 Stopping set optimization early at iteration ${iteration + 1}');
          break;
        }
        
      } catch (e) {
        debugPrint('❌ Error in set ${initialSet.setId} iteration ${iteration + 1}: $e');
        debugPrint('🔄 Continuing with next iteration...');
        continue;
      }
    }
    
    debugPrint('✅ Individual set optimization complete');
    debugPrint('📈 Improvements applied: $improvementCount');
    
    return currentSet;
  }
  
  /// Simple validation: Remove invalid courses from sets
  List<CourseSet> _validateAndCleanSets(
    List<CourseSet> courseSets,
    List<dynamic> validCandidates,
  ) {
    final validCourseIds = validCandidates
        .map((c) => c['general']?['מספר מקצוע']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    
    final cleanedSets = <CourseSet>[];
    
    for (final set in courseSets) {
      final validCourses = <CourseInSet>[];
      final removedCourses = <String>[];
      
      for (final course in set.courses) {
        if (validCourseIds.contains(course.courseId)) {
          validCourses.add(course);
        } else {
          removedCourses.add(course.courseId);
        }
      }
      
      if (removedCourses.isNotEmpty) {
        debugPrint('🚫 In set ${set.setId} removed invalid courses: ${removedCourses.join(', ')}');
      }
      
      // Only add sets that have valid courses
      if (validCourses.isNotEmpty) {
        cleanedSets.add(CourseSet(
          setId: set.setId,
          courses: validCourses,
          totalCredits: validCourses.fold(0.0, (sum, course) => sum + course.creditPoints), // Sum actual credit points
          reasoning: set.reasoning,
        ));
      }
    }
    
    return cleanedSets;
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