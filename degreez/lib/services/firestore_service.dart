import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches the user's main profile data and all their nested courses,
  /// organized by semester, from Firestore.
  Future<Map<String, dynamic>> getFullStudentData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      // Return an empty map if no user is logged in
      return {};
    }

    try {
      // 1. Fetch the main student document
      final studentDocRef = _firestore.collection('Students').doc(user.uid);
      final studentSnapshot = await studentDocRef.get();

      if (!studentSnapshot.exists) {
        // Return an empty map if the student document doesn't exist
        return {};
      }

      Map<String, dynamic> studentData = studentSnapshot.data()!;

      // 2. Fetch the semesters subcollection
      final semestersSnapshot =
          await studentDocRef.collection('Courses-per-Semesters').get();

      Map<String, List<Map<String, dynamic>>> coursesBySemester = {};

      // 3. Use Future.wait to fetch all courses in parallel for efficiency
      await Future.wait(semestersSnapshot.docs.map((semesterDoc) async {
        final semesterId = semesterDoc.id;

        // 4. Fetch the courses subcollection for the current semester
        final coursesSnapshot =
            await semesterDoc.reference.collection('Courses').get();

        if (coursesSnapshot.docs.isNotEmpty) {
          final coursesList = coursesSnapshot.docs
              .map((courseDoc) => courseDoc.data())
              .toList();
          coursesBySemester[semesterId] = coursesList;
        }
      }));

      // 5. Combine the student profile data with the nested course data
      studentData['coursesBySemester'] = coursesBySemester;

      return studentData;
    } catch (e) {
      // ignore: avoid_print
      debugPrint("Error fetching full student data: $e");
      return {};
    }
  }

  /// Fetches global application settings and the current user's courses for all available semesters.
  ///
  /// This function retrieves:
  /// 1. Global settings from the 'Global/Settings' document, which includes the
  ///    current semester and a list of all available semesters.
  /// 2. The current user's courses for each of the available semesters.
  ///
  /// Returns a map containing the global settings and a 'coursesBySemester' map,
  /// where keys are semester IDs and values are lists of course data.
  /// Returns an empty map if the user is not logged in or if global settings are not found.
  Future<Map<String, dynamic>> getGlobalData() async {
    User? user = _auth.currentUser;
    if (user == null) {
      // Return an empty map if no user is logged in
      return {};
    }

    try {
      // 1. Fetch global settings
      final settingsDoc =
          await _firestore.collection('Global').doc('Settings').get();

      if (!settingsDoc.exists) {
        // Return an empty map if global settings document doesn't exist
        return {};
      }

      Map<String, dynamic> globalData = settingsDoc.data()!;
      List<String> availableSemesters =
          List<String>.from(globalData['availableSemesters'] ?? []);

      // 2. Fetch user's courses for each available semester
      Map<String, List<Map<String, dynamic>>> coursesBySemester = {};
      final studentDocRef = _firestore.collection('Students').doc(user.uid);

      await Future.wait(availableSemesters.map((semesterId) async {
        final coursesSnapshot = await studentDocRef
            .collection('Courses-per-Semesters')
            .doc(semesterId)
            .collection('Courses')
            .get();

        if (coursesSnapshot.docs.isNotEmpty) {
          final coursesList = coursesSnapshot.docs
              .map((courseDoc) => courseDoc.data())
              .toList();
          coursesBySemester[semesterId] = coursesList;
        }
      }));

      // 3. Combine global data with the user's course data
      globalData['coursesBySemester'] = coursesBySemester;

      return globalData;
    } catch (e) {
      // ignore: avoid_print
      debugPrint("Error fetching global data: $e");
      return {};
    }
  }
}
