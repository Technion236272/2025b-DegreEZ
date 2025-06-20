import 'dart:io';

class PdfAttachment {
  final File file;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final Map<String, dynamic> metadata;
  final DateTime attachedAt;
  
  PdfAttachment({
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.metadata,
    required this.attachedAt,
  });
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
      'filePath': file.path,
    };
  }

  /// Create from JSON
  static PdfAttachment fromJson(Map<String, dynamic> json) {
    return PdfAttachment(
      file: File(json['filePath']),
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      pageCount: json['pageCount'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      attachedAt: DateTime.parse(json['attachedAt']),
    );
  }
}
