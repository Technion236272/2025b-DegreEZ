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
        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: selectedSemesterSeason,
          style: const TextStyle(
            color: AppColorsDarkMode.secondaryColor,
          ),
          decoration: InputDecoration(
            labelText: 'Semester',
            labelStyle: const TextStyle(
              color: AppColorsDarkMode.secondaryColorDim,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColorsDarkMode.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColorsDarkMode.secondaryColor,
              ),
            ),
            filled: true,
            fillColor: AppColorsDarkMode.surfaceColor,
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
        );
      },
    );
  }
}