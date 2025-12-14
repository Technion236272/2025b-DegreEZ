// lib/widgets/course_recommendation/catalog_upload_widget.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/course_recommendation_provider.dart';

class CatalogUploadWidget extends StatelessWidget {
  final String? catalogFilePath;
  final Function(String?) onFileSelected;

  const CatalogUploadWidget({
    super.key,
    required this.catalogFilePath,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Course Catalog (Recommended)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your course catalog PDF for more accurate recommendations',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeProvider.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            if (catalogFilePath == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickFile(context),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Select Catalog PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: themeProvider.primaryColor),
                    foregroundColor: themeProvider.secondaryColor,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeProvider.primaryColor.withAlpha(76),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, 
                         color: themeProvider.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(catalogFilePath!),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'PDF file selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: themeProvider.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _clearFile(context),
                      icon: const Icon(Icons.close),
                      color: themeProvider.textSecondary,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFileName(String filePath) {
    // Handle both path separators for cross-platform compatibility
    final parts = filePath.split(RegExp(r'[/\\]'));
    return parts.last;
  }

  void _clearFile(BuildContext context) {
    // Clear both path and bytes
    context.read<CourseRecommendationProvider>().clearCatalogFile();
  }

  void _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Always get bytes for web compatibility
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final provider = context.read<CourseRecommendationProvider>();
        
        // Get file bytes (works on all platforms)
        final Uint8List? bytes = file.bytes;
        
        if (kIsWeb) {
          // For web, we only have file name and bytes
          debugPrint('Web: Selected file: ${file.name}, bytes: ${bytes?.length ?? 0}');
          provider.setCatalogFile(file.name, bytes);
        } else {
          // For mobile/desktop, we can use both path and bytes
          if (file.path != null) {
            debugPrint('Mobile: Selected file path: ${file.path}, bytes: ${bytes?.length ?? 0}');
            provider.setCatalogFile(file.path!, bytes);
          } else if (bytes != null) {
            // Fallback to bytes only if path is somehow null
            debugPrint('Mobile: File path is null, using bytes only');
            provider.setCatalogFile(file.name, bytes);
          } else {
            debugPrint('Error: Both file path and bytes are null');
          }
        }
      }
    } catch (e) {
      // Handle error - you might want to show a snackbar
      debugPrint('Error picking file: $e');
    }
  }
}