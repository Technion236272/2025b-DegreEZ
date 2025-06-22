import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// Base AI service that provides common Firebase AI functionality
/// This eliminates redundant model initialization across different AI services
abstract class BaseAiService {
  late final GenerativeModel _model;
  
  BaseAiService({
    required String modelName,
    required String systemInstruction,
    GenerationConfig? generationConfig,
  }) {
    _initializeModel(
      modelName: modelName,
      systemInstruction: systemInstruction,
      generationConfig: generationConfig,
    );
  }

  void _initializeModel({
    required String modelName,
    required String systemInstruction,
    GenerationConfig? generationConfig,
  }) {
    _model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.text(systemInstruction),
      generationConfig: generationConfig,
    );
  }

  /// Provides access to the underlying model for subclasses
  GenerativeModel get model => _model;

  /// Generate content from text prompt
  Future<GenerateContentResponse> generateContent(String prompt) async {
    return await _model.generateContent([Content.text(prompt)]);
  }
  /// Generate content with file attachment
  Future<GenerateContentResponse> generateContentWithFile({
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final content = Content.multi([
      TextPart(prompt),
      InlineDataPart(mimeType, fileBytes),
    ]);
    
    return await _model.generateContent([content]);
  }

  /// Generate streaming content
  Stream<GenerateContentResponse> generateContentStream(String prompt) {
    return _model.generateContentStream([Content.text(prompt)]);
  }
  /// Generate streaming content with file
  Stream<GenerateContentResponse> generateContentStreamWithFile({
    required String prompt,
    required Uint8List fileBytes,
    required String mimeType,
  }) async* {
    final content = Content.multi([
      TextPart(prompt),
      InlineDataPart(mimeType, fileBytes),
    ]);
    
    yield* _model.generateContentStream([content]);
  }
}
