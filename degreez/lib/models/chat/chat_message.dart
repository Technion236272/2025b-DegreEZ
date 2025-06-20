import 'pdf_attachment.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final PdfAttachment? pdfAttachment;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.pdfAttachment,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'pdfAttachment': pdfAttachment?.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      pdfAttachment: json['pdfAttachment'] != null 
          ? PdfAttachment.fromJson(json['pdfAttachment'])
          : null,
    );
  }
}
