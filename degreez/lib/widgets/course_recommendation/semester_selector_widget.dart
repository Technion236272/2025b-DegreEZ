// lib/widgets/course_recommendation/semester_selector_widget.dart

import 'package:flutter/material.dart';

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
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
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
            
            if (availableSemesters.isEmpty)
              const Center(
                child: Text('No semesters available'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSemesters.map((semester) {
                  final year = semester['year'] as int;
                  final semesterCode = semester['semester'] as int;
                  final display = semester['display'] as String;
                  
                  final isSelected = selectedYear == year && 
                                   selectedSemester == semesterCode;
                  
                  return ChoiceChip(
                    label: Text(display),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onSemesterSelected(year, semesterCode);
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : null,
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