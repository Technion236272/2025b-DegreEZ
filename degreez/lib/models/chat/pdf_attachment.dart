import 'dart:io';
import 'dart:typed_data';

class PdfAttachment {
  final File? file; // Nullable for web compatibility
  final Uint8List? bytes; // For web platform
  final String fileName;
  final int fileSize;
  final int pageCount;
  final Map<String, dynamic> metadata;
  final DateTime attachedAt;
  
  PdfAttachment({
    this.file,
    this.bytes,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.metadata,
    required this.attachedAt,
  }) : assert(file != null || bytes != null, 'Either file or bytes must be provided');
  /// Get a summary for display in the UI
  String getSummary() {
    return '''
📄 $fileName
📊 ${_formatFileSize(fileSize)}
📅 Attached: ${attachedAt.toString().split('.')[0]}
''';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  /// Convert to JSON for storage (without file reference for security)
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'metadata': metadata,
      'attachedAt': attachedAt.toIso8601String(),
      'filePath': file?.path ?? '',
    };
  }

  /// Create from JSON
  static PdfAttachment fromJson(Map<String, dynamic> json) {
    return PdfAttachment(
      file: json['filePath'] != null && json['filePath'].isNotEmpty ? File(json['filePath']) : null,
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      pageCount: json['pageCount'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      attachedAt: DateTime.parse(json['attachedAt']),
    );
  }
  
  /// Get bytes for sending to AI (works on both mobile and web)
  Future<Uint8List> getBytes() async {
    if (bytes != null) {
      return bytes!;
    } else if (file != null) {
      return await file!.readAsBytes();
    } else {
      throw Exception('No file or bytes available');
    }
  }
}
