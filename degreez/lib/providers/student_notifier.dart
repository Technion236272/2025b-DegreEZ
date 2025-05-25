// This file defines a StudentNotifier class that extends ChangeNotifier.
// It is responsible for managing the state of student data in a Flutter application.
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';


class StudentNotifier with ChangeNotifier {
  // Private variables to hold student data and loading state
  // and error message
  StudentModel? _student;
  bool _isLoading = false;
  String _error = '';

  // Getters for the private variables
  StudentModel? get student => _student;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Fetch student data from Firestore
  // using the provided userId == user UID  , which will be saved in the student model
  Future<void> fetchStudentData(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Students')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        _student = StudentModel.fromFirestore(
            docSnapshot.data() as Map<String, dynamic>);
      } else {
        _error = 'Student not found';
      }
    } catch (e) {
      _error = 'Error fetching student data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Create and save a new student model
  Future<bool> createStudent(StudentModel student) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('Students')
          .doc(student.id)
          .set(student.toFirestore());
      
      _student = student;
      return true;
    } catch (e) {
      _error = 'Error creating student: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
