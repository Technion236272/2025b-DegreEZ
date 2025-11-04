// lib/widgets/course_recommendation/semester_selector_widget.dart

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:degreez/providers/course_provider.dart';
class SemesterSelectorWidget extends StatelessWidget {
  final List<Map<String, dynamic>> availableSemesters;
  final int? selectedYear;
  final int? selectedSemester;
  final Function(int year, int semester) onSemesterSelected;

  const SemesterSelectorWidget({
    super.key,
    required this.availableSemesters,
    required this.selectedYear,
    required this.selectedSemester,
    required this.onSemesterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Target Semester',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AutoSizeText(
              "To display and select a semester here please add it on customized diagram first",
              maxLines: 2,
              minFontSize: 10,
              maxFontSize: 40,
            ),
            const SizedBox(height: 16),

            if (availableSemesters.isEmpty)
              const Center(child: Text('No semesters available'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    availableSemesters.map((semester) {
                      final year = semester['year'] as int;
                      final semesterCode = semester['semester'] as int;
                      final display = semester['display'] as String;

                      final isSelected =
                          selectedYear == year &&
                          selectedSemester == semesterCode;

                      return ChoiceChip(
                        label: Text(display),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            final parsed = CourseProvider().parseSemesterCode(
                              display,
                            );
                            if (parsed != null) {
                              // The color change is handled by selectedColor and labelStyle below.
                              final (year, semesterCode) = parsed;
                              onSemesterSelected(year, semesterCode);
                              
                            }
                          }
                        },

                        selectedColor: Theme.of(
                          context,
                        ).primaryColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
