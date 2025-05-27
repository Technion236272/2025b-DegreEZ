import 'package:cloud_firestore/cloud_firestore.dart';

// models/student_model.dart
class StudentModel {
  final String id;
  final String name;
  final String major;
  final String faculty;
  final String preferences;
  final int semester;
  final String catalog; // selecting the catalog for the student
  // final List<String> courses; // Assuming you want to add this later
  // final List<String> enrolledCourses; // Assuming you want to add this later

  StudentModel({
    required this.id,
    required this.name,
    required this.major,
    required this.faculty,
    required this.preferences,
    required this.semester,
    required this.catalog,
  });

  // Factory constructor to create a StudentModel from Firestore data
  // This assumes that the Firestore document has fields with the same names as the class properties
  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return StudentModel(
      id: doc.id, //  this is the real Firestore document ID
      name: data['Name'] ?? '',
      major: data['Major'] ?? '',
      faculty: data['Faculty'] ?? '',
      preferences: data['Preferences'] ?? '',
      semester: data['Semester'] ?? 1,
      catalog: data['Catalog'] ?? '',
    );
  }

  // Method to convert the StudentModel to a Map for Firestore
  // This assumes that you want to save the same fields in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'Id': id,
      'Name': name,
      'Major': major,
      'Faculty': faculty,
      'Preferences': preferences,
      'Semester': semester,
      'Catalog': catalog,
    };
  }

  StudentModel copyWith({
    String? name,
    String? major,
    String? preferences,
    String? catalog,
    String? faculty,
    int? semester,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      major: major ?? this.major,
      faculty: faculty ?? this.faculty,
      preferences: preferences ?? this.preferences,
      semester: semester ?? this.semester,
      catalog: catalog ?? this.catalog,
    );
  }
}
