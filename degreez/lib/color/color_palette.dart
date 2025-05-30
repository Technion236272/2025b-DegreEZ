import 'package:flutter/material.dart';

class AppColorsDarkMode {
  static const Color mainColor = Colors.black;
  static const Color secondaryColor = Color(0xFFFCBAAD);
  static const Color secondaryColorDim = Color(0xAAFCBAAD);
  static const Color secondaryColorDimDD = Color(0xDDFCBAAD);
  static const Color accentColor = Color(0xFF41221C);
  static const Color accentColorDim = Color(0xCC41221C);
}

class CourseCardColorPalette{
  int? _id;
  final Color _topBarBG = Colors.black;
  final Color _topBarText = Colors.black;
  final Color _topBarMarkBG = Colors.black;
  final Color _topBarMarkText = Colors.black;
  final Color _cardFG = Colors.black;
  final Color _cardBG = Colors.black;
  
  get id => _id;
  get topBarBG => _topBarBG;
  get topBarText => _topBarText;
  get topBarMarkBG => _topBarMarkBG;
  get topBarMarkText => _topBarMarkText;
  get cardFG => _cardFG;

  Color cardBG([String? courseId]){
    return _cardBG;
    }

  CourseCardColorPalette(){
    _id = 0;
  }
}


class CourseCardColorPalette1 extends CourseCardColorPalette
{
  CourseCardColorPalette1(){
    _id = 1;
  }
  @override
  get topBarBG => AppColorsDarkMode.accentColor;

  @override
  get topBarText => AppColorsDarkMode.secondaryColor;

  @override
  get topBarMarkBG => AppColorsDarkMode.secondaryColorDimDD;

  @override
  get topBarMarkText => AppColorsDarkMode.accentColor;

  @override
  Color cardBG([String? courseId]){
    return AppColorsDarkMode.secondaryColor;
    }

  @override
  get cardFG => AppColorsDarkMode.accentColor;
  
}

class CourseCardColorPalette2 extends CourseCardColorPalette
{
  CourseCardColorPalette2(){
    _id = 2;
  }
  @override
  get topBarBG => AppColorsDarkMode.accentColorDim;

  @override
  get topBarText => AppColorsDarkMode.secondaryColor;

  @override
  get topBarMarkBG => AppColorsDarkMode.secondaryColorDimDD;

  @override
  get topBarMarkText => AppColorsDarkMode.accentColor;

  @override
  Color cardBG([String? courseId]){
    return _getCourseColor(courseId!);
    }

  @override
  get cardFG => AppColorsDarkMode.secondaryColor;

  Color _getCourseColor(String courseId) {
    final hash = courseId.hashCode;
    final colors = [
      Colors.teal.shade900, // Dark greenish blue
      Colors.indigo.shade900, // Deep bluish purple
      Colors.cyan.shade900, // Rich green-blue — bright pop
      Colors.deepPurple.shade900, // Bold, regal purple
      Colors.blue.shade900, // Classic dark blue
      Colors.orange.shade900, // Dark, warm orange — still different from brown
      Colors.red.shade900, // Blood red — intense but clearly distinct
      Colors.lime.shade900, // Sharp and vivid green-yellow
    ];
    return colors[hash.abs() % colors.length];
  }
}