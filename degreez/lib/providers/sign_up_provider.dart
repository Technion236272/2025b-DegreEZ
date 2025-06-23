import 'package:flutter/material.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class SignUpProvider extends ChangeNotifier {
  String? _selectedFaculty = null;
  String? _selectedMajor = null;
  
  
  String? get selectedFaculty => _selectedFaculty;
  String? get selectedMajor => _selectedMajor;
  
  void setSelectedFaculty(String val) {
    _selectedFaculty = val;
    notifyListeners();
  }

  void setSelectedMajor(String val) {
    _selectedMajor = val;
    notifyListeners();
  }

}