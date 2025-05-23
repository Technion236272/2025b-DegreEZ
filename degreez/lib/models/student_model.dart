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
  factory StudentModel.fromFirestore(Map<String, dynamic> data) {
    return StudentModel(
      id: data['Id'] ?? '',
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

  
}