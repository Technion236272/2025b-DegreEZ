/// AI configuration constants and utilities shared across all AI services
class AiConfig {
  // Model configurations
  static const String defaultModel = 'gemini-2.5-flash';
  
  // Common system instruction prefixes
  static const String baseSystemInstruction = "You are an AI assistant for DegreEZ, an academic planning app.";
  
  // Chat-specific instructions
  static const String chatSystemInstruction = 
    "$baseSystemInstruction Help students with course planning, academic advice, study tips, and education questions. "
    "When user context is provided, use it for personalized advice. "
    "Be helpful, concise, kind and academically focused.";
    
  // Document analysis instructions
  static const String documentAnalysisInstruction = 
    "$baseSystemInstruction You are an expert at extracting course information from academic documents.";
    
  // Common file size limits
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20MB limit (Gemini's limit)
  
  // Common MIME types
  static const String pdfMimeType = 'application/pdf';
  static const String jsonMimeType = 'application/json';
}
