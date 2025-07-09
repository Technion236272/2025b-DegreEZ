import 'package:degreez/providers/sign_up_provider.dart';
import 'package:degreez/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UniversitySelector extends StatefulWidget {
  const UniversitySelector({super.key});

  @override
  State<UniversitySelector> createState() => _UniversitySelectorState();
}

class _UniversitySelectorState extends State<UniversitySelector> {
  final List<String> _universities = ['Technion']; // Only Technion for now
  String? selectedUniversity;

  @override
  void initState() {
    super.initState();
    // Set default selection to Technion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signUpProvider = context.read<SignUpProvider>();
      if (signUpProvider.selectedUniversity == null) {
        signUpProvider.setSelectedUniversity('Technion');
        setState(() {
          selectedUniversity = 'Technion';
        });
      } else {
        setState(() {
          selectedUniversity = signUpProvider.selectedUniversity;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SignUpProvider, ThemeProvider>(
      builder: (context, signUpProvider, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeProvider.borderPrimary,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedUniversity,
              hint: Text(
                'Select University',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontSize: 16,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: themeProvider.textSecondary,
              ),
              dropdownColor: themeProvider.surfaceColor,
              style: TextStyle(
                color: themeProvider.textPrimary,
                fontSize: 16,
              ),
              items: _universities.map((String university) {
                return DropdownMenuItem<String>(
                  value: university,
                  child: Text(
                    university,
                    style: TextStyle(
                      color: themeProvider.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedUniversity = newValue;
                  });
                  signUpProvider.setSelectedUniversity(newValue);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
