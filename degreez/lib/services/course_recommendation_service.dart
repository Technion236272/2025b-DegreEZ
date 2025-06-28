// lib/services/course_recommendation_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/course_recommendation_models.dart';
import '../services/ai/base_ai_service.dart';
import '../services/ai/ai_config.dart';
import '../services/ai/ai_utils.dart';
import '../services/course_service.dart';

class CourseRecommendationService extends BaseAiService {
  static const String _systemInstruction = '''
${AiConfig.baseSystemInstruction}

You are a course recommendation specialist for academic planning. Your role is to help students select appropriate courses for a specific semester based on their academic history, major requirements, and catalog information.

Always follow this process:
1. Analyze the student's context (major, completed courses, semester, preferences)
2. Review the catalog PDF to understand available courses (if provided)
3. Identify potential courses that align with the student's needs
4. Create final recommendations totaling 15-18 credit points
5. Provide clear reasoning for each recommendation

Consider these factors:
- Prerequisites and academic progression
- Major requirements vs electives
- Course difficulty and student's academic level
- Schedule conflicts and workload balance
- Student's stated preferences and career goals

Respond with valid JSON only, following the exact schema provided.
''';

  CourseRecommendationService() : super(
    modelName: AiConfig.defaultModel,
    systemInstruction: _systemInstruction,
    generationConfig: AiUtils.createJsonConfig(_createRecommendationSchema()),
  );

  /// Main method to generate course recommendations
  Future<CourseRecommendationResponse> generateRecommendations(
    CourseRecommendationRequest request,
  ) async {
    try {
      // Step 1: Get candidate courses from AI
      final candidateCourses = await _identifyCandidateCourses(request);
      
      // Step 2: Fetch detailed course information
      final courseDetails = await _fetchCourseDetails(
        candidateCourses.courses.keys.toList(),
        request.year,
        request.semester,
      );
      
      // Step 3: Generate final recommendations
      final finalRecommendations = await _generateFinalRecommendations(
        request,
        candidateCourses,
        courseDetails,
      );
      
      return finalRecommendations;
    } catch (e) {
      debugPrint('Course recommendation error: $e');
      throw Exception('Failed to generate course recommendations: $e');
    }
  }

  /// Step 1: Use structured JSON response to identify candidate courses
  Future<CandidateCourses> _identifyCandidateCourses(
    CourseRecommendationRequest request,
  ) async {
    // Create model for candidate course identification
    final candidateModel = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.defaultModel,
      systemInstruction: Content.text(_systemInstruction),
      generationConfig: AiUtils.createJsonConfig(_createCandidateSchema()),
    );

    // Prepare the prompt
    String prompt = '''
Please identify 15 candidate courses for the following student:

${request.userContext}

Target Semester: ${request.semester} ${request.year}

Requirements:
- Select exactly 15 courses that would be appropriate for this student
- Consider the student's academic level, major, and completed courses
- Ensure courses are available in the specified semester
- Focus on courses that advance the student's degree progression
- Include a mix of required courses and suitable electives

Return your response as valid JSON with the required schema.
Each course should have both an id and name.
''';

    // Generate response with or without catalog PDF
    final response = await _generateWithOptionalPdf(candidateModel, prompt, request.catalogFilePath);
    
    try {
      final jsonData = jsonDecode(response.text ?? '{}');
      
      // Convert array format to map format for CandidateCourses
      final coursesArray = jsonData['courses'] as List;
      final coursesMap = <String, String>{};
      
      for (final course in coursesArray) {
        coursesMap[course['id']] = course['name'];
      }
      
      return CandidateCourses(
        courses: coursesMap,
        reasoning: jsonData['reasoning'] ?? '',
      );
    } catch (e) {
      throw Exception('Failed to parse candidate courses response: $e');
    }
  }

  /// Step 2: Fetch detailed course information using CourseService
  Future<List<CourseRecommendationDetails>> _fetchCourseDetails(
    List<String> courseIds,
    int year,
    int semester,
  ) async {
    final courseDetails = <CourseRecommendationDetails>[];
    
    for (final courseId in courseIds) {
      try {
        final courseInfo = await CourseService.getCourseDetails(year, semester, courseId);
        if (courseInfo != null) {
          courseDetails.add(CourseRecommendationDetails.fromCourseService(courseInfo));
        }
      } catch (e) {
        debugPrint('Failed to fetch details for course $courseId: $e');
      }
    }
    
    return courseDetails;
  }

  /// Step 3: Generate final recommendations using detailed course info
  Future<CourseRecommendationResponse> _generateFinalRecommendations(
    CourseRecommendationRequest request,
    CandidateCourses candidateCourses,
    List<CourseRecommendationDetails> courseDetails,
  ) async {
    // Create model for final recommendations
    final recommendationModel = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.defaultModel,
      systemInstruction: Content.text(_systemInstruction),
      generationConfig: AiUtils.createJsonConfig(_createRecommendationSchema()),
    );

    // Prepare detailed course information for the AI
    final courseDetailsJson = courseDetails.map((course) => course.toJson()).toList();
    
    final prompt = '''
Based on the detailed course information below, please generate final course recommendations for this student:

STUDENT CONTEXT:
${request.userContext}

TARGET SEMESTER: ${request.semester} ${request.year}

CANDIDATE COURSES ANALYSIS:
${candidateCourses.reasoning}

DETAILED COURSE INFORMATION:
${jsonEncode(courseDetailsJson)}

REQUIREMENTS:
- Target total credit points: 15-18
- Provide clear reasoning for each recommendation
- Consider prerequisites and academic progression
- Balance workload and difficulty
- Prioritize courses that best fit the student's academic plan

Return your response as valid JSON with the required schema.
''';

    final response = await recommendationModel.generateContent([Content.text(prompt)]);
    
    try {
      final jsonData = jsonDecode(response.text ?? '{}');
      
      final recommendations = (jsonData['recommendations'] as List)
          .map((r) => CourseRecommendation.fromJson(r))
          .toList();
      
      return CourseRecommendationResponse(
        recommendations: recommendations,
        totalCreditPoints: (jsonData['totalCreditPoints'] as num).toDouble(),
        summary: jsonData['summary'] as String,
        reasoning: jsonData['reasoning'] as String,
        generatedAt: DateTime.now(),
        originalRequest: request,
      );
    } catch (e) {
      throw Exception('Failed to parse final recommendations response: $e');
    }
  }

  /// Helper method to generate content with optional PDF
  Future<GenerateContentResponse> _generateWithOptionalPdf(
    GenerativeModel model,
    String prompt,
    String? catalogFilePath,
  ) async {
    if (catalogFilePath != null && catalogFilePath.isNotEmpty) {
      final catalogFile = File(catalogFilePath);
      
      // Validate file before processing
      if (!await AiUtils.validateFileSize(catalogFile)) {
        throw Exception(AiUtils.getFileSizeErrorMessage());
      }
      
      if (!await AiUtils.validatePdfFormat(catalogFile)) {
        throw Exception('Invalid PDF file format');
      }
      
      final catalogBytes = await catalogFile.readAsBytes();
      return await model.generateContent([
        AiUtils.createPdfContent(prompt, catalogBytes)
      ]);
    } else {
      return await model.generateContent([Content.text(prompt)]);
    }
  }

  /// Schema for candidate course identification - using array format
  static Schema _createCandidateSchema() {
    return Schema.object(
      properties: {
        'courses': Schema.array(
          items: Schema.object(
            properties: {
              'id': Schema.string(description: 'Course ID'),
              'name': Schema.string(description: 'Course name'),
            },
          ),
          description: 'Array of exactly 15 courses, each with id and name',
        ),
        'reasoning': Schema.string(
          description: 'Brief explanation of why these courses were selected',
        ),
      },
    );
  }

  /// Schema for final recommendations
  static Schema _createRecommendationSchema() {
    return Schema.object(
      properties: {
        'recommendations': Schema.array(
          items: Schema.object(
            properties: {
              'courseId': Schema.string(),
              'courseName': Schema.string(),
              'creditPoints': Schema.number(),
              'reason': Schema.string(description: 'Why this course is recommended'),
              'priority': Schema.integer(description: 'Priority 1-5 (1=highest)'),
              'category': Schema.string(description: 'e.g., Core, Elective, Prerequisites'),
            },
          ),
          description: 'List of recommended courses (target 15-18 total credit points)',
        ),
        'totalCreditPoints': Schema.number(),
        'summary': Schema.string(description: 'Brief summary of the recommendation set'),
        'reasoning': Schema.string(description: 'Overall reasoning for the recommendation strategy'),
      },
    );
  }
}