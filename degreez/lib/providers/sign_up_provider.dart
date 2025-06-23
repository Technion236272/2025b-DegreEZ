import 'package:flutter/material.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class SignUpProvider extends ChangeNotifier {
  String? _selectedCatalog;
  String? _selectedFaculty;
  String? _selectedMajor;
  String? _selectedSemesterSeason;
  String? _selectedSemesterYear;
  
  String? get selectedFaculty => _selectedFaculty;
  String? get selectedMajor => _selectedMajor;
  String? get selectedCatalog => _selectedCatalog;
  String? get selectedSemesterSeason => _selectedSemesterSeason;
  String? get selectedSemesterYear => _selectedSemesterYear;
  String? get selectedSemester => '$_selectedSemesterSeason $_selectedSemesterYear';

  void resetFaculty(){_selectedFaculty=null;}  
  void resetMajor(){_selectedMajor=null;}  
  void resetCatalog(){_selectedCatalog=null;}  
  void resetSemesterSeason(){_selectedSemesterSeason=null;}  
  void resetSemesterYear(){_selectedSemesterYear=null;}  
  
  void setSelectedFaculty(String val) {
    _selectedFaculty = val;
    notifyListeners();
  }

  void setSelectedMajor(String val) {
    _selectedMajor = val;
    notifyListeners();
  }

  void setSelectedCatalog(String val) {
    _selectedCatalog = val;
    notifyListeners();
  }

  void setSelectedSemesterSeason(String val) {
    _selectedSemesterSeason = val;
    notifyListeners();
  }

  void setSelectedSemesterYear(String val) {
    _selectedSemesterYear = val;
    notifyListeners();
  }

  void resetSelected(){
    resetFaculty();
    resetMajor();
    resetCatalog();
    resetSemesterSeason();
    resetSemesterYear();
  }
}