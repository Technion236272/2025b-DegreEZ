import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'ai_config.dart';

/// Utility class for common AI operations shared across different services
class AiUtils {
  
  /// Validates file size against AI service limits
  static Future<bool> validateFileSize(File file) async {
    final fileSize = await file.length();
    return fileSize <= AiConfig.maxFileSizeBytes;
  }
  
  /// Gets formatted file size error message
  static String getFileSizeErrorMessage() {
    final maxSizeMB = (AiConfig.maxFileSizeBytes / 1024 / 1024).toInt();
    return 'File is too large. Maximum size allowed is ${maxSizeMB}MB.';
  }
  
  /// Validates PDF file format
  static Future<bool> validatePdfFormat(File file) async {
    try {
      final bytes = await file.openRead(0, 5).first;
      final header = String.fromCharCodes(bytes);
      return header.startsWith('%PDF');
    } catch (e) {
      return false;
    }
  }
  
  /// Creates a Content object for text + PDF combination
  static Content createPdfContent(String prompt, Uint8List pdfBytes) {
    return Content.multi([
      TextPart(prompt),
      InlineDataPart(AiConfig.pdfMimeType, pdfBytes),
    ]);
  }
  
  /// Creates standard JSON generation config for structured responses
  static GenerationConfig createJsonConfig(Schema responseSchema) {
    return GenerationConfig(
      responseMimeType: AiConfig.jsonMimeType,
      responseSchema: responseSchema,
    );
  }
    /// Creates standard course extraction schema
  static Schema createCourseExtractionSchema() {
    return Schema.object(
      properties: {
        'courses': Schema.array(
          items: Schema.object(
            properties: {
              'courseId': Schema.string(),
              'Name': Schema.string(),
              'Credit_points': Schema.number(),
              'Final_grade': Schema.string(),
              'Semester': Schema.string(), // e.g., "Fall", "Spring", "Winter", "Summer"
              'Year': Schema.string(), // e.g., "2023-2024", "2024"
            },
            optionalProperties: ['Final_grade', 'Semester', 'Year'],
          ),
        ),
      },
    );
  }
  
  /// Standard error handling for AI responses
  static String handleAiError(dynamic error) {
    if (error.toString().contains('quota')) {
      return 'AI service quota exceeded. Please try again later.';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toString().contains('authentication')) {
      return 'AI service authentication failed. Please contact support.';
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }
}
