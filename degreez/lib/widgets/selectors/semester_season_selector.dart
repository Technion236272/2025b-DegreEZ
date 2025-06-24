import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
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
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, _) {
        selectedSemesterSeason = signUpProvider.selectedSemesterSeason;
        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: ['Winter', 'Spring', 'Summer'].contains(selectedSemesterSeason) ? selectedSemesterSeason : null,
          style: const TextStyle(
            color: AppColorsDarkMode.secondaryColor,
          ),
          decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.secondaryColor,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.secondaryColorDimDD),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColorsDarkMode.errorColor,
            width: 2.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColorsDarkMode.errorColorDim),
        ),
        alignLabelWithHint: true,
        labelText: "Enrollment Semester",
        labelStyle: TextStyle(color: AppColorsDarkMode.secondaryColor,fontSize: 15),
        hoverColor: AppColorsDarkMode.secondaryColor,
        hintText: "Season",
        hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
      ),
          dropdownColor: AppColorsDarkMode.surfaceColor,
          items: ['Winter', 'Spring', 'Summer'].map((season) {
            return DropdownMenuItem<String>(
              value: season,
              child: Text(
                season,
                style: const TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
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