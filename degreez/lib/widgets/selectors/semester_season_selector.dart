import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SemesterSeasonSelector extends StatefulWidget {
  const SemesterSeasonSelector({super.key});

  @override
  State<SemesterSeasonSelector> createState() => _SemesterSeasonSelectorState();
}

class _SemesterSeasonSelectorState extends State<SemesterSeasonSelector> {
  String? selectedSemesterSeason;
  final int currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SignUpProvider,ThemeProvider>(
      builder: (context, signUpProvider,themeProvider, _) {
        selectedSemesterSeason = signUpProvider.selectedSemesterSeason;
        return DropdownButtonFormField<String>(
          iconEnabledColor: themeProvider.secondaryColor,
          value: ['Winter', 'Spring', 'Summer'].contains(selectedSemesterSeason) ? selectedSemesterSeason : null,
          style: TextStyle(
            color: themeProvider.secondaryColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: themeProvider.surfaceColor,
            labelText: "Enrollment Semester",
            labelStyle: TextStyle(color: themeProvider.textSecondary,fontSize: 15),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeProvider.borderPrimary,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeProvider.secondaryColor.withAlpha(200),),
          
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: themeProvider.errorColor,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeProvider.errorColor.withAlpha(170)),
        ),
        alignLabelWithHint: true,
        hoverColor: themeProvider.secondaryColor,
        hintText: "Season",
        hintStyle: TextStyle(color: themeProvider.secondaryColor.withAlpha(200),
      ),),
          dropdownColor: themeProvider.surfaceColor,
          items: ['Winter', 'Spring', 'Summer'].map((season) {
            return DropdownMenuItem<String>(
              value: season,
              child: Text(
                season,
                style: TextStyle(
                  color: themeProvider.secondaryColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedSemesterSeason = value;
              });
              
              // Update the provider with selected season
              signUpProvider.setSelectedSemesterSeason(value);
              
              // Auto-set the year based on season selection
              final autoYear = value == 'Winter'
                  ? '${currentYear - 1}-$currentYear'
                  : '$currentYear';
              signUpProvider.setSelectedSemesterYear(autoYear);
            }
          },
          validator: (value) =>
        (value == null || value.isEmpty) ? "This field is required." : null,
        );
      },
    );
  }
}