import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SemesterYearSelector extends StatefulWidget {
  final int? year = null;
  const SemesterYearSelector({super.key,year});

  @override
  State<SemesterYearSelector> createState() => _SemesterYearSelectorState();
}

class _SemesterYearSelectorState extends State<SemesterYearSelector> {
  String? selectedYear;
  int currentYear = DateTime.now().year;

  @override
  void initState() {
    if ((widget.year!=null)) {
      setState(() {
        currentYear = widget.year!;
      });
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, _) {
        final selectedSeason = signUpProvider.selectedSemesterSeason;
        
        // Update local selectedYear if provider value changes
        if (signUpProvider.selectedSemesterYear != selectedYear) {
          selectedYear = signUpProvider.selectedSemesterYear;
        }

        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: selectedYear,
          style: const TextStyle(
            color: AppColorsDarkMode.secondaryColor,
          ),
          decoration: InputDecoration(
            labelText: 'Year',
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
          items: List.generate(11, (index) {
            int baseYear = currentYear - 5 + index;
            final yearLabel = selectedSeason == 'Winter'
                ? '${baseYear}-${baseYear + 1}'
                : '$baseYear';
            return DropdownMenuItem<String>(
              value: yearLabel,
              child: Text(
                yearLabel,
                style: const TextStyle(
                  color: AppColorsDarkMode.secondaryColor,
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedYear = value;
              });
              
              // Update the provider with selected year
              signUpProvider.setSelectedSemesterYear(value);
            }
          },
        );
      },
    );
  }
}