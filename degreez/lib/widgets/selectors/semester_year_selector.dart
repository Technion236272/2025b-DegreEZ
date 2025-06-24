import 'package:degreez/color/color_palette.dart';
import 'package:degreez/providers/sign_up_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SemesterYearSelector extends StatefulWidget {
  final int? year;
  const SemesterYearSelector({super.key, this.year});

  @override
  State<SemesterYearSelector> createState() => _SemesterYearSelectorState();
}

class _SemesterYearSelectorState extends State<SemesterYearSelector> {
  String? selectedYear;
  int currentYear = DateTime.now().year;

  @override
  void initState() {
    if ((widget.year != null)) {
      setState(() {
        currentYear = widget.year!;
      });
    } else {
      currentYear = DateTime.now().year;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpProvider>(
      builder: (context, signUpProvider, _) {
        selectedYear = signUpProvider.selectedSemesterYear;
        final selectedSeason = signUpProvider.selectedSemesterSeason;

        // Update local selectedYear if provider value changes
        if (signUpProvider.selectedSemesterYear != selectedYear) {
          selectedYear = signUpProvider.selectedSemesterYear;
        }

        List<String> yearValues = List.generate(11, (index) {
          int baseYear = currentYear - 5 + index;
          return selectedSeason == 'Winter'
              ? '${baseYear}-${baseYear + 1}'
              : '$baseYear';
        });

        return DropdownButtonFormField<String>(
          iconEnabledColor: AppColorsDarkMode.secondaryColor,
          value: yearValues.contains(selectedYear) ? selectedYear : null,
          style: const TextStyle(color: AppColorsDarkMode.secondaryColor),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColorsDarkMode.secondaryColor,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColorsDarkMode.secondaryColorDimDD,
              ),
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
            labelText: "Enrollment Year",
            labelStyle: TextStyle(
              color: AppColorsDarkMode.secondaryColor,
              fontSize: 15,
            ),
            hoverColor: AppColorsDarkMode.secondaryColor,
            hintText: "Year",
            hintStyle: TextStyle(color: AppColorsDarkMode.secondaryColorDim),
          ),
          dropdownColor: AppColorsDarkMode.surfaceColor,
          items:
              yearValues.map((yearLabel) {
                return DropdownMenuItem<String>(
                  value: yearLabel,
                  child: Text(
                    yearLabel,
                    style: const TextStyle(
                      color: AppColorsDarkMode.secondaryColor,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedYear = value;
              });

              // Update the provider with selected year
              signUpProvider.setSelectedSemesterYear(value);
            }
          },
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? "This field is required."
                      : null,
        );
      },
    );
  }
}
