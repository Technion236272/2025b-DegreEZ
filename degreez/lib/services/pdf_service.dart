import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PdfService {
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20MB limit (Gemini's limit)

  /// Pick a PDF file from device storage
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        
        // Check file size
        int fileSize = await file.length();
        if (fileSize > maxFileSizeBytes) {
          throw Exception('PDF file is too large. Maximum size allowed is ${(maxFileSizeBytes / 1024 / 1024).toInt()}MB.');
        }
        
        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick PDF file: ${e.toString()}');
    }
  }

  /// Get basic PDF file information
  static Future<Map<String, dynamic>> getPdfInfo(File pdfFile) async {
    try {
      // Get basic file info
      String fileName = pdfFile.path.split(Platform.pathSeparator).last;
      int fileSize = await pdfFile.length();
      
      // Basic PDF validation - check if file starts with PDF header
      final bytes = await pdfFile.openRead(0, 5).first;
      final header = String.fromCharCodes(bytes);
      
      if (!header.startsWith('%PDF')) {
        throw Exception('Invalid PDF file format');
      }
        Map<String, dynamic> info = {
        'fileName': fileName,
        'fileSize': fileSize,
        'fileSizeFormatted': _formatFileSize(fileSize),
        'isValid': true,
      };
      
      return info;
    } catch (e) {
      throw Exception('Failed to get PDF information: ${e.toString()}');
    }
  }

  /// Format file size in human-readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Basic PDF validation
  static Future<bool> isValidPdf(File pdfFile) async {
    try {
      // Check if file exists and has content
      if (!await pdfFile.exists()) return false;
      
      final fileSize = await pdfFile.length();
      if (fileSize == 0) return false;
      
      // Check PDF header
      final bytes = await pdfFile.openRead(0, 5).first;
      final header = String.fromCharCodes(bytes);
      
      return header.startsWith('%PDF');
    } catch (e) {
      return false;
    }
  }
}
