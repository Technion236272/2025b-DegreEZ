import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      print("Error fetching full student data: $e");
      return {};
    }
  }
}
