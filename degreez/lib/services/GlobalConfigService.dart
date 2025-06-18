import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalConfigService {
  static Future<String?> getCurrentSemester() async {
    final doc = await FirebaseFirestore.instance
        .collection('Global')
        .doc('Settings')
        .get();

    if (doc.exists && doc.data()?['currentSemester'] != null) {
      return doc['currentSemester'] as String;
    }
    return null;
  }

  static Future<List<String>> getAvailableSemesters() async {
    final doc = await FirebaseFirestore.instance
        .collection('Global')
        .doc('Settings')
        .get();

    if (doc.exists && doc.data()?['availableSemesters'] != null) {
      return List<String>.from(doc['availableSemesters']);
    }
    return [];
  }
}
