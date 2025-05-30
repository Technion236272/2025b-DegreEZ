import 'package:degreez/color/color_palette.dart';
import 'package:flutter/material.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class CustomizedDiagramNotifier extends ChangeNotifier {
  
  // Private field to store the current user
  CourseCardColorPalette? _cardColorPalette;

  CourseCardColorPalette? get cardColorPalette => _cardColorPalette;
  
  // Constructor: listen to auth state changes
  CustomizedDiagramNotifier() {
    _initCustomizedDiagram();
    notifyListeners();
    }
  
  // Initialize user on startup
  void _initCustomizedDiagram() {
    _cardColorPalette = CourseCardColorPalette1();
  }
  
  /// Sign in with Google account
  void switchPalette()  {
    if (cardColorPalette!.id==1)
    {_cardColorPalette = CourseCardColorPalette2();}
    else{
      _cardColorPalette = CourseCardColorPalette1();
    }
    notifyListeners();
  }

}